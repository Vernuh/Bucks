import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/achievement.dart';
import '../models/budget.dart';
import '../models/customization_item.dart';
import '../models/mission.dart';
import '../models/mission_pool.dart';
import '../models/monthly_summary.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../models/upcoming_item.dart';
import '../models/user.dart';
import '../services/bucks_backend.dart';
import '../services/supabase_service.dart';
import '../utils/formatters.dart';

/// Outcome of a user action, so screens can show a message without
/// containing any business logic themselves.
class ActionResult {
  final bool success;
  final String message;
  const ActionResult(this.success, this.message);
}

/// Where the app is in the sign-in lifecycle. The UI shows a loading screen
/// until the signed-in user's data has been loaded from Supabase.
enum AuthStatus { initializing, signedOut, signedIn, loadFailed }

/// The ONE in-memory source of truth for the current user's data.
///
///   Screen -> AppStateProvider (logic) -> SupabaseService -> Supabase
///   AppStateProvider -> notifyListeners() -> every watching screen
///
/// Supabase (Auth + PostgreSQL) is the only PERSISTENT store. Changes are
/// applied in memory immediately and written to Supabase right after; a
/// failed write is kept and retried (see [syncError] / [retrySync]).
///
/// Screens read getters and call methods here. They never compute balances,
/// grant rewards, or touch Bucks Coins / customization state themselves.
class AppStateProvider extends ChangeNotifier {
  AppStateProvider({BucksBackend? backend, DateTime Function()? clock})
      : _backend = backend ?? SupabaseService.instance,
        _clock = clock ?? DateTime.now;

  final BucksBackend _backend;
  final DateTime Function() _clock;

  // --- state ---------------------------------------------------------------
  User _user = User(id: '', username: '');
  final List<Transaction> _transactions = []; // oldest -> newest
  final List<SavingsGoal> _goals = [];
  final List<Budget> _budgetDefs = []; // limits only; spent is derived
  final List<UpcomingItem> _upcoming = [];
  List<Mission> _missions = [];
  final Set<String> _achievements = {};
  final Set<String> _unlockedCustomization = {};
  final Map<String, String> _equippedCustomization = {}; // category -> id

  bool _loaded = false;
  AuthStatus _status = AuthStatus.initializing;
  String? _loadError;
  String? _syncError;
  int _idCounter = 0;

  // Per-action bookkeeping so the result message can mention rewards.
  int _rewardBucks = 0;
  int _rewardXp = 0;
  int _levelAtActionStart = 1;

  // Short-lived Bucks reaction (not persisted).
  String? _eventMessage;
  DateTime? _eventAt;

  Future<void> _pendingSave = Future<void>.value();

  // --- auth + startup ------------------------------------------------------

  bool get isLoaded => _loaded;
  AuthStatus get authStatus => _status;
  bool get isSignedIn => _status == AuthStatus.signedIn;

  /// Why the first load failed (shown with a Retry button), if it did.
  String? get loadError => _loadError;

  /// Set when the last write to Supabase failed. The change is still in
  /// memory and is retried on the next save or [retrySync].
  String? get syncError => _syncError;

  /// Called once at app start: restores the existing Supabase session (if
  /// any) and loads that user's data BEFORE the main app is shown.
  Future<void> restoreSession() async {
    final uid = _backend.currentUserId;
    if (uid == null) {
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    _status = AuthStatus.initializing;
    _loadError = null;
    notifyListeners();
    try {
      await _loadFor(uid);
    } on BackendException catch (e) {
      _loadError = e.message;
      _status = AuthStatus.loadFailed;
      notifyListeners();
    }
  }

  /// Registers with Supabase Auth. On success (and a session), the new
  /// user's profile/stats exist and an empty account is loaded.
  Future<ActionResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final name = username.trim();
    final mail = email.trim();
    if (name.isEmpty) return const ActionResult(false, 'Enter a username.');
    if (mail.isEmpty) return const ActionResult(false, 'Enter your email.');
    if (password.length < 6) {
      return const ActionResult(
          false, 'Password must be at least 6 characters.');
    }
    try {
      final out = await _backend.signUp(
          email: mail, password: password, username: name);
      if (out.needsEmailConfirmation || out.userId == null) {
        return const ActionResult(true,
            'Account created! Check your email to confirm it, then log in.');
      }
      await _loadFor(out.userId!);
      return const ActionResult(true, 'Welcome to BUCKS!');
    } on BackendException catch (e) {
      return ActionResult(false, e.message);
    }
  }

  Future<ActionResult> signIn({
    required String email,
    required String password,
  }) async {
    final mail = email.trim();
    if (mail.isEmpty || password.isEmpty) {
      return const ActionResult(false, 'Enter your email and password.');
    }
    try {
      final out = await _backend.signIn(email: mail, password: password);
      await _loadFor(out.userId!);
      return const ActionResult(true, 'Logged in.');
    } on BackendException catch (e) {
      // Don't leave a half-signed-in session behind if loading failed.
      if (_backend.currentUserId != null && !_loaded) {
        try {
          await _backend.signOut();
        } catch (_) {}
      }
      return ActionResult(false, e.message);
    }
  }

  /// Signs out of Supabase and clears ALL user-specific in-memory state.
  Future<ActionResult> signOut() async {
    await _pendingSave;
    try {
      await _backend.signOut();
    } on BackendException catch (e) {
      return ActionResult(false, e.message);
    }
    _clearUserState();
    _status = AuthStatus.signedOut;
    notifyListeners();
    return const ActionResult(true, 'Signed out.');
  }

  Future<void> _loadFor(String uid) async {
    final data = await _backend.loadUserData(uid);
    _applyLoaded(data, uid);
    _loaded = true;
    _status = AuthStatus.signedIn;
    _loadError = null;
    _persist();
    notifyListeners();
  }

  void _applyLoaded(StoredData data, String uid) {
    _user = (data.user ?? User(id: uid, username: 'Student')).copyWith();
    _transactions
      ..clear()
      ..addAll(data.transactions);
    _goals
      ..clear()
      ..addAll(data.goals);
    _budgetDefs
      ..clear()
      ..addAll(data.budgets);
    _upcoming
      ..clear()
      ..addAll(data.upcoming);
    _missions = List.of(data.missions);
    _achievements
      ..clear()
      ..addAll(data.achievements);
    _unlockedCustomization
      ..clear()
      ..addAll(data.unlockedCustomization);
    _equippedCustomization
      ..clear()
      ..addAll(data.equippedCustomization);

    // Drop ids that no longer exist in the catalog / aren't owned.
    _unlockedCustomization
        .removeWhere((id) => CustomizationCatalog.byId(id) == null);
    _equippedCustomization.removeWhere((cat, id) =>
        !_unlockedCustomization.contains(id) ||
        CustomizationCatalog.byId(id)?.category != cat);

    _beginAction();
    _syncDay();
    _checkAchievements();
  }

  void _clearUserState() {
    _user = User(id: '', username: '');
    _transactions.clear();
    _goals.clear();
    _budgetDefs.clear();
    _upcoming.clear();
    _missions = [];
    _achievements.clear();
    _unlockedCustomization.clear();
    _equippedCustomization.clear();
    _eventMessage = null;
    _eventAt = null;
    _loaded = false;
    _loadError = null;
    _syncError = null;
    _pendingSave = Future<void>.value();
  }

  /// Completes when everything queued for saving has been written.
  Future<void> flush() => _pendingSave;

  /// Retries writing anything that failed to reach Supabase.
  void retrySync() => _persist();

  // --- level / XP ----------------------------------------------------------

  /// Total XP needed to reach [level]. L1=0, L2=100, L3=250, L4=450, ...
  static int xpForLevel(int level) =>
      level <= 1 ? 0 : 25 * (level - 1) * (level + 2);

  static int levelForXp(int xp) {
    var level = 1;
    while (xp >= xpForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  // --- profile getters -----------------------------------------------------

  String get username => _user.username;
  String get email => _user.email;

  /// THE Bucks Coins balance. Home/Bucks/Profile/Customize all read this.
  int get buckCoins => _user.buckCoins;
  int get xp => _user.xp;
  int get level => levelForXp(_user.xp);
  int get xpForCurrentLevel => xpForLevel(level);
  int get xpForNextLevel => xpForLevel(level + 1);

  /// 0.0 – 1.0 progress through the current level.
  double get levelProgress {
    final span = xpForNextLevel - xpForCurrentLevel;
    if (span <= 0) return 0;
    return ((_user.xp - xpForCurrentLevel) / span).clamp(0.0, 1.0);
  }

  int get currentStreak => _user.currentStreak;

  void setUsername(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _user = _user.copyWith(username: trimmed);
    _persist();
    notifyListeners();
  }

  // --- financial getters (all derived from the shared transactions) --------

  /// Newest first.
  List<Transaction> get transactions => _transactions.reversed.toList();
  List<SavingsGoal> get goals => List.unmodifiable(_goals);
  List<UpcomingItem> get upcomingItems {
    final list = List.of(_upcoming)..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  bool _isToday(DateTime d) {
    final now = _clock();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isThisMonth(DateTime d) {
    final now = _clock();
    return d.year == now.year && d.month == now.month;
  }

  double _sum(Iterable<Transaction> txs) =>
      txs.fold(0.0, (sum, t) => sum + t.amount);

  double get totalIncome =>
      _sum(_transactions.where((t) => t.type == TransactionType.income));
  double get totalExpenses =>
      _sum(_transactions.where((t) => t.type == TransactionType.expense));
  double get totalSavingsContributions =>
      _sum(_transactions.where((t) => t.type == TransactionType.savings));

  /// Income - expenses - money moved into savings goals.
  double get availableBalance =>
      totalIncome - totalExpenses - totalSavingsContributions;

  double get spentToday => _sum(_transactions
      .where((t) => t.type == TransactionType.expense && _isToday(t.date)));

  /// What is currently saved across all goals.
  double get totalSaved => _goals.fold(0.0, (sum, g) => sum + g.savedAmount);

  bool get hasTransactions => _transactions.isNotEmpty;

  /// Expense totals for the current month, biggest first.
  List<MapEntry<String, double>> get spendingByCategoryThisMonth {
    final map = <String, double>{};
    for (final t in _transactions) {
      if (t.type == TransactionType.expense && _isThisMonth(t.date)) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  double get incomeThisMonth => _sum(_transactions
      .where((t) => t.type == TransactionType.income && _isThisMonth(t.date)));
  double get expensesThisMonth => _sum(_transactions
      .where((t) => t.type == TransactionType.expense && _isThisMonth(t.date)));
  double get savedThisMonth => _sum(_transactions
      .where((t) => t.type == TransactionType.savings && _isThisMonth(t.date)));

  /// The last [count] months (oldest first), derived from transactions.
  List<MonthlySummary> monthlySummaries({int count = 5}) {
    final now = _clock();
    final result = <MonthlySummary>[];
    for (var i = count - 1; i >= 0; i--) {
      final start = DateTime(now.year, now.month - i, 1);
      final end = DateTime(start.year, start.month + 1, 1);
      bool inMonth(Transaction t) =>
          !t.date.isBefore(start) && t.date.isBefore(end);

      result.add(MonthlySummary(
        month: monthShort(start.month),
        income: _sum(_transactions
            .where((t) => t.type == TransactionType.income && inMonth(t))),
        expenses: _sum(_transactions
            .where((t) => t.type == TransactionType.expense && inMonth(t))),
        saved: _sum(_transactions
            .where((t) => t.type == TransactionType.savings && inMonth(t))),
        cumulativeSavings: _sum(_transactions.where(
            (t) => t.type == TransactionType.savings && t.date.isBefore(end))),
      ));
    }
    return result;
  }

  // --- budgets (spent is derived) ------------------------------------------

  List<Budget> get budgets => _budgetDefs
      .map((b) => b.copyWith(
            spent: _sum(_transactions.where((t) =>
                t.type == TransactionType.expense &&
                t.category == b.category &&
                _isThisMonth(t.date))),
          ))
      .toList();

  double get totalBudgetLimit => _budgetDefs.fold(0.0, (s, b) => s + b.limit);
  double get totalBudgetSpent => budgets.fold(0.0, (s, b) => s + b.spent);
  double get budgetRemaining => totalBudgetLimit - totalBudgetSpent;
  bool get hasBudgets => _budgetDefs.isNotEmpty;

  // --- missions ------------------------------------------------------------

  List<Mission> get missions => List.unmodifiable(_missions);

  // --- achievements --------------------------------------------------------

  bool isAchievementUnlocked(String id) => _achievements.contains(id);
  int get unlockedAchievementCount => _achievements.length;

  // --- customization -------------------------------------------------------

  bool isCustomizationUnlocked(String itemId) =>
      _unlockedCustomization.contains(itemId);

  bool isCustomizationEquipped(String itemId) {
    final item = CustomizationCatalog.byId(itemId);
    return item != null && _equippedCustomization[item.category] == itemId;
  }

  /// Equipped items, in catalog category order.
  List<CustomizationItem> get equippedItems {
    final result = <CustomizationItem>[];
    for (final cat in CustomizationCatalog.categories) {
      final id = _equippedCustomization[cat];
      final item = id == null ? null : CustomizationCatalog.byId(id);
      if (item != null) result.add(item);
    }
    return result;
  }

  // --- Bucks reactions (deterministic, no AI) ------------------------------

  String get bucksMessage {
    final at = _eventAt;
    if (_eventMessage != null &&
        at != null &&
        _clock().difference(at) < const Duration(seconds: 45)) {
      return _eventMessage!;
    }

    if (_transactions.isEmpty && _goals.isEmpty && _budgetDefs.isEmpty) {
      return "Bawk! Hi $username! Add your first transaction and let's get "
          'started.';
    }
    final bs = budgets;
    if (bs.any((b) => b.isOver)) {
      return "Bawk! We went over a budget. Let's slow down on spending.";
    }
    if (bs.any((b) => b.isNearLimit)) {
      return "Bawk! We're getting close to the budget limit.";
    }
    if (_goals.any((g) => g.isComplete)) {
      return 'Bawk! We reached your savings goal!';
    }
    if (bs.isNotEmpty) {
      return "Bawk! You're doing great, $username! Only "
          "${formatPeso(budgetRemaining)} left in this month's budget.";
    }
    return "Bawk! Let's keep those finances cluckin'!";
  }

  void _setEvent(String message) {
    _eventMessage = message;
    _eventAt = _clock();
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  // --- transactions --------------------------------------------------------

  /// Adds an income, expense or savings contribution. For
  /// [TransactionType.savings], [goalId] must be an existing goal and that
  /// SAME goal's saved amount is increased.
  ActionResult addTransaction({
    required TransactionType type,
    required double amount,
    String? category,
    String? note,
    String? goalId,
    DateTime? date,
  }) {
    if (!amount.isFinite || amount <= 0) {
      return const ActionResult(false, 'Enter a valid amount.');
    }
    if (type == TransactionType.savings) {
      if (!_goals.any((g) => g.id == goalId)) {
        return const ActionResult(false, 'Pick a savings goal.');
      }
    } else if (category == null || category.isEmpty) {
      return const ActionResult(false, 'Pick a category.');
    }

    final cleanNote =
        (note == null || note.trim().isEmpty) ? null : note.trim();
    final when = date ?? _clock();

    _beginAction();
    _syncDay();

    String savedMessage;
    String? event;

    if (type == TransactionType.savings) {
      final idx = _goals.indexWhere((g) => g.id == goalId);
      final goal = _goals[idx];
      final wasComplete = goal.isComplete;
      _goals[idx] = goal.copyWith(savedAmount: goal.savedAmount + amount);
      _transactions.add(Transaction(
        id: _newId('tx'),
        type: type,
        category: goal.name,
        amount: amount,
        date: when,
        note: cleanNote,
        goalId: goal.id,
      ));
      _completeMissions(MissionAction.saveMoney);
      savedMessage = 'Savings saved: ${formatPeso(amount)} to ${goal.name}.';
      if (!wasComplete && _goals[idx].isComplete) {
        event = 'Bawk! We reached your savings goal!';
      }
    } else {
      _transactions.add(Transaction(
        id: _newId('tx'),
        type: type,
        category: category!,
        amount: amount,
        date: when,
        note: cleanNote,
      ));
      final isExpense = type == TransactionType.expense;
      _completeMissions(
        isExpense ? MissionAction.logExpense : MissionAction.logIncome,
      );
      savedMessage = isExpense
          ? 'Expense saved: ${formatPeso(amount)} ($category).'
          : 'Income saved: ${formatPeso(amount)} ($category).';
    }

    if (cleanNote != null) _completeMissions(MissionAction.addNote);
    _completeMissions(MissionAction.anyActivity);
    _evaluateStayOnBudget();
    return _finish(savedMessage, event: event);
  }

  // --- savings goals -------------------------------------------------------

  ActionResult addGoal({required String name, required double target}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return const ActionResult(false, 'Enter a goal name.');
    if (!target.isFinite || target <= 0) {
      return const ActionResult(false, 'Enter a valid target amount.');
    }
    if (_goals.any((g) => g.name.toLowerCase() == trimmed.toLowerCase())) {
      return const ActionResult(
          false, 'You already have a goal with that name.');
    }

    _beginAction();
    _syncDay();
    _goals.add(SavingsGoal(
      id: _newId('goal'),
      name: trimmed,
      targetAmount: target,
      savedAmount: 0,
    ));
    _completeMissions(MissionAction.anyActivity);
    return _finish('Goal created: $trimmed.');
  }

  // --- budgets -------------------------------------------------------------

  /// Creates the monthly budget for [category], or updates its limit.
  ActionResult setBudget({required String category, required double limit}) {
    if (!limit.isFinite || limit <= 0) {
      return const ActionResult(false, 'Enter a valid budget limit.');
    }
    _beginAction();
    _syncDay();
    final idx = _budgetDefs.indexWhere((b) => b.category == category);
    if (idx >= 0) {
      _budgetDefs[idx] = _budgetDefs[idx].copyWith(limit: limit);
    } else {
      _budgetDefs
          .add(Budget(id: _newId('budget'), category: category, limit: limit));
    }
    _completeMissions(MissionAction.anyActivity);
    _evaluateStayOnBudget();
    return _finish('$category budget set to ${formatPeso(limit)}.');
  }

  ActionResult removeBudget(String budgetId) {
    final before = _budgetDefs.length;
    _budgetDefs.removeWhere((b) => b.id == budgetId);
    if (_budgetDefs.length == before) {
      return const ActionResult(false, 'Budget not found.');
    }
    _persist();
    notifyListeners();
    return const ActionResult(true, 'Budget removed.');
  }

  // --- upcoming items ------------------------------------------------------

  ActionResult addUpcoming({
    required String name,
    required double amount,
    required bool isExpense,
    required DateTime date,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return const ActionResult(false, 'Enter a name.');
    if (!amount.isFinite || amount <= 0) {
      return const ActionResult(false, 'Enter a valid amount.');
    }
    _upcoming.add(UpcomingItem(
      id: _newId('up'),
      name: trimmed,
      amount: amount,
      isExpense: isExpense,
      date: date,
    ));
    _persist();
    notifyListeners();
    return ActionResult(true, 'Added $trimmed to upcoming.');
  }

  ActionResult removeUpcoming(String id) {
    _upcoming.removeWhere((u) => u.id == id);
    _persist();
    notifyListeners();
    return const ActionResult(true, 'Removed.');
  }

  /// Turns an upcoming item into a real transaction (category "Other",
  /// note = its name) and removes it from the upcoming list.
  ActionResult completeUpcoming(String id) {
    final idx = _upcoming.indexWhere((u) => u.id == id);
    if (idx < 0) return const ActionResult(false, 'Item not found.');
    final item = _upcoming[idx];
    _upcoming.removeAt(idx);
    return addTransaction(
      type: item.isExpense ? TransactionType.expense : TransactionType.income,
      amount: item.amount,
      category: 'Other',
      note: item.name,
    );
  }

  // --- screen-visit missions -----------------------------------------------

  /// Called when the user actually opens Budget / Reports / Goals, or the
  /// app itself. Only visit-type actions are accepted.
  void recordVisit(MissionAction action) {
    const allowed = {
      MissionAction.openBudget,
      MissionAction.openGoals,
      MissionAction.openReports,
      MissionAction.openApp,
    };
    if (!allowed.contains(action)) return;

    _beginAction();
    final dayChanged = _syncDay();
    _completeMissions(action);
    _checkAchievements();

    final earned = _rewardBucks > 0 || _rewardXp > 0;
    if (earned) _setEvent('Bawk! You earned some Bucks!');
    if (dayChanged || earned) {
      _persist();
      notifyListeners();
    }
  }

  /// Convenience for entering the main app.
  void recordAppOpened() => recordVisit(MissionAction.openApp);

  /// Call when the app returns to the foreground (the day may have changed).
  void refreshDay() {
    _beginAction();
    if (_syncDay()) {
      _checkAchievements();
      _persist();
      notifyListeners();
    }
  }

  // --- customization economy -----------------------------------------------

  ActionResult purchaseCustomizationItem(String itemId) {
    final item = CustomizationCatalog.byId(itemId);
    if (item == null) return const ActionResult(false, 'Item not found.');
    if (_unlockedCustomization.contains(itemId)) {
      return ActionResult(false, '${item.name} is already owned.');
    }
    if (_user.buckCoins < item.cost) {
      return const ActionResult(false, 'Not enough Bucks!');
    }

    _user = _user.copyWith(buckCoins: _user.buckCoins - item.cost);
    _unlockedCustomization.add(itemId);
    _setEvent('Bawk! Nice! Bucks got a new item!');
    _persist();
    notifyListeners();
    return ActionResult(true, '${item.name} unlocked!');
  }

  /// Equips an unlocked item, replacing whatever was equipped in the same
  /// category.
  ActionResult equipCustomizationItem(String itemId) {
    final item = CustomizationCatalog.byId(itemId);
    if (item == null) return const ActionResult(false, 'Item not found.');
    if (!_unlockedCustomization.contains(itemId)) {
      return const ActionResult(false, 'Unlock this item first.');
    }
    if (_equippedCustomization[item.category] == itemId) {
      return ActionResult(false, '${item.name} is already equipped.');
    }

    _equippedCustomization[item.category] = itemId;
    _setEvent('Bawk! Looking good!');
    _persist();
    notifyListeners();
    return ActionResult(true, '${item.name} equipped!');
  }

  // --- reset / debug -------------------------------------------------------

  /// Deletes this account's BUCKS data in Supabase (the login account itself
  /// stays) and starts fresh.
  Future<ActionResult> resetAllData() async {
    await _pendingSave;
    try {
      await _backend.deleteUserData(_user.id);
    } on BackendException catch (e) {
      return ActionResult(false, e.message);
    }
    _user = User(id: _user.id, username: _user.username, email: _user.email);
    _transactions.clear();
    _goals.clear();
    _budgetDefs.clear();
    _upcoming.clear();
    _missions = [];
    _achievements.clear();
    _unlockedCustomization.clear();
    _equippedCustomization.clear();
    _eventMessage = null;
    _eventAt = null;
    _syncError = null;

    _beginAction();
    _syncDay();
    _persist();
    notifyListeners();
    return const ActionResult(true, 'All data reset.');
  }

  /// DEBUG BUILDS ONLY: sets the Bucks Coins balance so purchases and
  /// insufficient-funds behavior can be tested without waiting for
  /// missions. Does nothing in release builds.
  void debugSetBuckCoins(int amount) {
    if (!kDebugMode) return;
    _user = _user.copyWith(buckCoins: max(0, amount));
    _persist();
    notifyListeners();
  }

  // ===========================================================================
  // INTERNALS
  // ===========================================================================

  String _newId(String prefix) =>
      '${prefix}_${_clock().microsecondsSinceEpoch}_${_idCounter++}';

  void _beginAction() {
    _rewardBucks = 0;
    _rewardXp = 0;
    _levelAtActionStart = level;
  }

  /// Shared tail of every data-changing action.
  ActionResult _finish(String message, {String? event}) {
    _checkAchievements();

    final earned = _rewardBucks > 0 || _rewardXp > 0;
    if (event != null) {
      _setEvent(event);
    } else if (earned) {
      _setEvent('Bawk! You earned some Bucks!');
    }

    var full = message;
    if (earned) full += ' +$_rewardBucks Bucks, +$_rewardXp XP earned!';
    if (level > _levelAtActionStart) {
      full += ' Level up! You are now level $level.';
    }

    _persist();
    notifyListeners();
    return ActionResult(true, full);
  }

  /// Adds coins/XP. Never lets either go negative.
  void _grant({int bucks = 0, int xp = 0}) {
    final b = max(0, bucks);
    final x = max(0, xp);
    if (b == 0 && x == 0) return;
    _user = _user.copyWith(
      buckCoins: _user.buckCoins + b,
      xp: _user.xp + x,
    );
    _rewardBucks += b;
    _rewardXp += x;
  }

  /// Completes (and rewards, exactly once) every not-yet-completed mission
  /// for [action].
  void _completeMissions(MissionAction action) {
    for (var i = 0; i < _missions.length; i++) {
      final m = _missions[i];
      if (m.action != action || m.isCompleted || m.rewardGranted) continue;
      _missions[i] = m.copyWith(isCompleted: true, rewardGranted: true);
      _grant(bucks: m.bucksReward, xp: m.xpReward);
    }
  }

  /// "Stay on Budget": at least one budget exists, something was spent
  /// today, and no budget is over its limit.
  void _evaluateStayOnBudget() {
    if (_budgetDefs.isEmpty) return;
    if (spentToday <= 0) return;
    if (budgets.any((b) => b.isOver)) return;
    _completeMissions(MissionAction.stayOnBudget);
  }

  void _checkAchievements() {
    for (final def in AchievementCatalog.all) {
      if (_achievements.contains(def.id)) continue;
      if (!_isAchieved(def.id)) continue;
      _achievements.add(def.id);
      _grant(bucks: def.bucksReward, xp: def.xpReward);
    }
  }

  bool _isAchieved(String id) {
    switch (id) {
      case 'first_transaction':
        return _transactions.isNotEmpty;
      case 'first_goal':
        return _goals.isNotEmpty;
      case 'budget_beginner':
        return _budgetDefs.isNotEmpty;
      case 'savings_starter':
        return _transactions.any((t) => t.type == TransactionType.savings);
      case 'streak_7':
        return _user.currentStreak >= 7;
      default:
        return false;
    }
  }

  /// Makes sure the streak and today's mission set match today's date.
  /// Returns true if anything changed. Missions are only regenerated when
  /// the stored date differs from today — never on a screen rebuild.
  bool _syncDay() {
    final now = _clock();
    final today = dateKey(now);
    var changed = false;

    // Streak: same day = no change, yesterday = +1, otherwise restart at 1.
    final last = _user.lastActivityDate;
    if (last != today) {
      final yesterday = dateKey(DateTime(now.year, now.month, now.day - 1));
      final streak = last == yesterday ? _user.currentStreak + 1 : 1;
      _user = _user.copyWith(currentStreak: streak, lastActivityDate: today);
      changed = true;
    }

    if (_missions.isEmpty || _missions.first.date != today) {
      _missions = _generateMissions(now);
      changed = true;
    }
    return changed;
  }

  /// Picks 3 missions from 3 different categories. Seeded by the date, so
  /// the same day always yields the same set.
  List<Mission> _generateMissions(DateTime day) {
    final key = dateKey(day);
    final rng = Random(day.year * 10000 + day.month * 100 + day.day);

    final categories = List.of(MissionCategory.values)..shuffle(rng);
    final picked = <Mission>[];
    for (final category in categories.take(3)) {
      final options =
          MissionPool.all.where((t) => t.category == category).toList();
      final t = options[rng.nextInt(options.length)];
      picked.add(Mission(
        id: '${key}_${t.id}',
        templateId: t.id,
        title: t.title,
        description: t.description,
        category: t.category,
        action: t.action,
        bucksReward: t.bucksReward,
        xpReward: t.xpReward,
        date: key,
      ));
    }
    return picked;
  }

  /// Snapshots current state and queues a write to Supabase (writes are
  /// chained, so they finish in order). Failures never lose in-memory data;
  /// they set [syncError] and the next save retries.
  void _persist() {
    if (!_loaded || _user.id.isEmpty) return;
    final uid = _user.id;
    final snapshot = StoredData(
      user: _user,
      transactions: List.of(_transactions),
      goals: List.of(_goals),
      budgets: List.of(_budgetDefs),
      upcoming: List.of(_upcoming),
      missions: List.of(_missions),
      achievements: Set.of(_achievements),
      unlockedCustomization: Set.of(_unlockedCustomization),
      equippedCustomization: Map.of(_equippedCustomization),
    );
    _pendingSave = _pendingSave
        .then((_) => _backend.saveUserData(uid, snapshot))
        .then((_) {
      if (_syncError != null && _user.id == uid) {
        _syncError = null;
        notifyListeners();
      }
    }).catchError((Object e) {
      debugPrint('AppStateProvider: save failed: $e');
      if (_user.id == uid) {
        _syncError = e is BackendException
            ? e.message
            : 'Could not save your changes.';
        notifyListeners();
      }
    });
  }
}
