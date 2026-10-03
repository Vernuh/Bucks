import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../config/app_config.dart';
import '../utils/formatters.dart';
import '../models/budget.dart';
import '../models/customization_item.dart';
import '../models/debt.dart';
import '../models/mission.dart';
import '../models/mission_pool.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../models/upcoming_item.dart';
import '../models/user.dart';
import 'bucks_backend.dart';

/// The only class that talks to Supabase (Auth + PostgreSQL).
///
///   Screen -> AppStateProvider -> SupabaseService -> Supabase
///
/// Uses only the PUBLIC key; Row Level Security (see supabase/schema.sql)
/// guarantees a user can only touch rows whose owner is their own
/// auth.users.id.
///
/// Saving is diff-based: the service remembers what it last read/wrote per
/// table and only sends rows that changed. If a write fails, the memory is
/// NOT updated, so the next save retries the same changes.
class SupabaseService implements BucksBackend {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  /// Call once at startup, before runApp().
  static Future<void> initialize() async {
    AppConfig.ensureConfigured();
    await sb.Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublicKey,
    );
  }

  sb.SupabaseClient get _db => sb.Supabase.instance.client;

  // table -> (row key -> json of the row as last known to be in the DB)
  final Map<String, Map<String, String>> _synced = {};

  // --- auth --------------------------------------------------------------

  @override
  String? get currentUserId => _db.auth.currentUser?.id;

  @override
  String? get currentEmail => _db.auth.currentUser?.email;

  @override
  Future<AuthOutcome> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final res = await _db.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      final user = res.user;
      if (user == null) {
        throw const BackendException('Could not create the account.');
      }
      _synced.clear();
      return AuthOutcome(
        userId: res.session == null ? null : user.id,
        email: user.email,
        needsEmailConfirmation: res.session == null,
      );
    } on sb.AuthException catch (e) {
      throw BackendException(e.message);
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException(_friendly(e));
    }
  }

  @override
  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res =
          await _db.auth.signInWithPassword(email: email, password: password);
      final user = res.user;
      if (user == null) {
        throw const BackendException('Could not log in.');
      }
      _synced.clear();
      return AuthOutcome(userId: user.id, email: user.email);
    } on sb.AuthException catch (e) {
      throw BackendException(e.message);
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException(_friendly(e));
    }
  }

  @override
  Future<void> signOut() async {
    _synced.clear();
    try {
      await _db.auth.signOut();
    } on sb.AuthException catch (e) {
      throw BackendException(e.message);
    }
  }

  // --- load --------------------------------------------------------------

  @override
  Future<StoredData> loadUserData(String uid) async {
    try {
      _synced.clear();

      // Profile + stats: created here if the sign-up trigger didn't (yet).
      final authUser = _db.auth.currentUser;
      var profile = await _db
          .from('profiles')
          .select('username')
          .eq('id', uid)
          .maybeSingle();
      if (profile == null) {
        final meta = authUser?.userMetadata?['username'];
        final name = (meta is String && meta.trim().isNotEmpty)
            ? meta.trim()
            : 'Student';
        await _db.from('profiles').upsert({'id': uid, 'username': name});
        profile = {'username': name};
      }

      var stats = await _db
          .from('user_stats')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      if (stats == null) {
        await _db.from('user_stats').upsert({'user_id': uid});
        stats = {
          'bucks_coins': 0,
          'xp': 0,
          'current_streak': 0,
          'last_activity_date': null,
        };
      }

      final user = User(
        id: uid,
        username: profile['username'] as String,
        email: authUser?.email ?? '',
        buckCoins: (stats['bucks_coins'] as num).toInt(),
        xp: (stats['xp'] as num).toInt(),
        currentStreak: (stats['current_streak'] as num).toInt(),
        lastActivityDate: stats['last_activity_date'] as String?,
      );

      final goalRows =
          await _db.from('savings_goals').select().eq('user_id', uid);
      final txRows = await _db
          .from('transactions')
          .select()
          .eq('user_id', uid)
          .order('date', ascending: true);
      final budgetRows = await _db.from('budgets').select().eq('user_id', uid);
      final upcomingRows =
          await _db.from('upcoming_items').select().eq('user_id', uid);
      final debtRows = await _loadDebtRows(uid);
      // Only the most recent day's missions are needed in memory
      // (older rows stay in the DB as the reward history).
      final missionRows = await _db
          .from('user_missions')
          .select()
          .eq('user_id', uid)
          .order('mission_date', ascending: false)
          .limit(MissionPool.all.length);
      final achievementRows = await _db
          .from('user_achievements')
          .select()
          .eq('user_id', uid)
          .eq('unlocked', true);
      final customRows =
          await _db.from('user_customizations').select().eq('user_id', uid);

      final goals = goalRows.map(_goalFromRow).toList();
      final transactions = txRows.map(_transactionFromRow).toList();
      final budgets = budgetRows.map(_budgetFromRow).toList();
      final upcoming = upcomingRows.map(_upcomingFromRow).toList();
      final debts = debtRows.map(Debt.fromJson).toList();

      var missions = <Mission>[];
      if (missionRows.isNotEmpty) {
        final latest = missionRows.first['mission_date'] as String;
        missions = missionRows
            .where((r) => r['mission_date'] == latest)
            .map(_missionFromRow)
            .whereType<Mission>()
            .toList();
      }

      final achievements =
          achievementRows.map((r) => r['achievement_id'] as String).toSet();
      final unlocked = <String>{};
      final equipped = <String, String>{};
      for (final r in customRows) {
        final id = r['item_id'] as String;
        final item = CustomizationCatalog.byId(id);
        if (item == null) continue;
        unlocked.add(id);
        if (r['equipped'] == true) equipped[item.category] = id;
      }

      final data = StoredData(
        user: user,
        transactions: transactions,
        goals: goals,
        budgets: budgets,
        upcoming: upcoming,
        debts: debts,
        missions: missions,
        achievements: achievements,
        unlockedCustomization: unlocked,
        equippedCustomization: equipped,
      );

      // Remember exactly what the DB holds right now.
      _remember(uid, data);
      return data;
    } on sb.PostgrestException catch (e) {
      throw BackendException('Could not load your data: ${e.message}');
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException(_friendly(e));
    }
  }

  // --- debts -------------------------------------------------------------

  /// Re-reads the signed-in user's debts and records them as "in sync", so
  /// the next save only sends real changes. RLS also limits this to the
  /// caller's own rows; the explicit filter is a second layer.
  @override
  Future<List<Debt>> loadDebts(String uid) async {
    if (uid.isEmpty || uid != currentUserId) {
      throw const BackendException('Please log in to see your debts.');
    }
    try {
      final rows = await _loadDebtRows(uid);
      final debts = rows.map(Debt.fromJson).toList();
      _synced['debts'] = {
        for (final x in debts) x.id: jsonEncode(_debtRow(uid, x)),
      };
      return debts;
    } catch (e) {
      debugPrint('SupabaseService.loadDebts error: $e');
      if (e is BackendException) rethrow;
      if (e is sb.PostgrestException) {
        throw BackendException(_isMissingTable(e)
            ? 'The debts table is missing in Supabase. Run the debts '
                'migration in the SQL Editor.'
            : 'Could not load your debts. Please try again.');
      }
      throw BackendException(_friendly(e));
    }
  }

  // --- save (diff-based) -------------------------------------------------

  @override
  Future<void> saveUserData(String uid, StoredData data) async {
    final desired = _rowsFor(uid, data);
    try {
      // Deletes first (children before parents), then upserts (parents
      // before children), so unique/foreign keys never trip.
      for (final t in const [
        'transactions',
        'budgets',
        'upcoming_items',
        'savings_goals',
        'debts',
      ]) {
        await _deleteRemoved(uid, t, desired[t]!);
      }

      await _upsertChanged(uid, 'savings_goals', desired['savings_goals']!,
          'user_id,id');
      await _upsertChanged(
          uid, 'transactions', desired['transactions']!, 'user_id,id');
      await _upsertChanged(uid, 'budgets', desired['budgets']!, 'user_id,id');
      await _upsertChanged(
          uid, 'upcoming_items', desired['upcoming_items']!, 'user_id,id');
      await _upsertChanged(uid, 'debts', desired['debts']!, 'user_id,id');

      // Missions / achievements are history: never deleted by a save.
      await _upsertChanged(
          uid, 'user_missions', desired['user_missions']!, 'user_id,mission_id');
      await _upsertChanged(uid, 'user_achievements',
          desired['user_achievements']!, 'user_id,achievement_id',
          ignoreDuplicates: true);

      await _syncCustomizations(uid, desired['user_customizations']!);

      // Profile + stats last. If an earlier step failed we never get here,
      // so a reward can be lost on failure but never granted twice.
      await _upsertChanged(
          uid, 'profiles', desired['profiles']!, 'id');
      await _upsertChanged(
          uid, 'user_stats', desired['user_stats']!, 'user_id');
    } on sb.PostgrestException catch (e) {
      throw BackendException('Could not save: ${e.message}');
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException(_friendly(e));
    }
  }

  Future<void> _deleteRemoved(
    String uid,
    String table,
    Map<String, Map<String, dynamic>> desired,
  ) async {
    final known = _synced[table] ?? const <String, String>{};
    final gone = known.keys.where((k) => !desired.containsKey(k)).toList();
    if (gone.isEmpty) return;
    await _db.from(table).delete().eq('user_id', uid).inFilter('id', gone);
    for (final k in gone) {
      _synced[table]?.remove(k);
    }
  }

  Future<void> _upsertChanged(
    String uid,
    String table,
    Map<String, Map<String, dynamic>> desired,
    String onConflict, {
    bool ignoreDuplicates = false,
  }) async {
    final known = _synced.putIfAbsent(table, () => {});
    final changed = <String, Map<String, dynamic>>{};
    desired.forEach((key, row) {
      if (known[key] != jsonEncode(row)) changed[key] = row;
    });
    if (changed.isEmpty) return;
    await _db.from(table).upsert(
          changed.values.toList(),
          onConflict: onConflict,
          ignoreDuplicates: ignoreDuplicates,
        );
    changed.forEach((key, row) => known[key] = jsonEncode(row));
  }

  /// Un-equips first, then equips, so the "one equipped item per category"
  /// unique index is never violated mid-update.
  Future<void> _syncCustomizations(
    String uid,
    Map<String, Map<String, dynamic>> desired,
  ) async {
    final known = _synced.putIfAbsent('user_customizations', () => {});
    final changed = <String, Map<String, dynamic>>{};
    desired.forEach((key, row) {
      if (known[key] != jsonEncode(row)) changed[key] = row;
    });
    if (changed.isEmpty) return;

    for (final equipped in const [false, true]) {
      final batch = changed.entries
          .where((e) => e.value['equipped'] == equipped)
          .toList();
      if (batch.isEmpty) continue;
      await _db.from('user_customizations').upsert(
            batch.map((e) => e.value).toList(),
            onConflict: 'user_id,item_id',
          );
      for (final e in batch) {
        known[e.key] = jsonEncode(e.value);
      }
    }
  }

  // --- reset -------------------------------------------------------------

  @override
  Future<void> deleteUserData(String uid) async {
    try {
      for (final t in const [
        'transactions',
        'budgets',
        'upcoming_items',
        'savings_goals',
        'debts',
        'user_missions',
        'user_achievements',
        'user_customizations',
      ]) {
        await _db.from(t).delete().eq('user_id', uid);
      }
      await _db.from('user_stats').upsert({
        'user_id': uid,
        'bucks_coins': 0,
        'xp': 0,
        'current_streak': 0,
        'last_activity_date': null,
      });
      _synced.clear();
    } on sb.PostgrestException catch (e) {
      throw BackendException('Could not reset: ${e.message}');
    } catch (e) {
      if (e is BackendException) rethrow;
      throw BackendException(_friendly(e));
    }
  }

  // --- row mapping -------------------------------------------------------

  Map<String, Map<String, Map<String, dynamic>>> _rowsFor(
    String uid,
    StoredData d,
  ) {
    String ts(DateTime t) => t.toUtc().toIso8601String();
    final user = d.user;

    return {
      'profiles': {
        uid: {'id': uid, 'username': user?.username ?? 'Student'},
      },
      'user_stats': {
        uid: {
          'user_id': uid,
          'bucks_coins': user?.buckCoins ?? 0,
          'xp': user?.xp ?? 0,
          'current_streak': user?.currentStreak ?? 0,
          'last_activity_date': user?.lastActivityDate,
        },
      },
      'savings_goals': {
        for (final g in d.goals)
          g.id: {
            'user_id': uid,
            'id': g.id,
            'name': g.name,
            'target_amount': g.targetAmount,
            'saved_amount': g.savedAmount,
            'deadline': g.deadline == null ? null : ts(g.deadline!),
          },
      },
      'transactions': {
        for (final t in d.transactions)
          t.id: {
            'user_id': uid,
            'id': t.id,
            'type': t.type.name,
            'category': t.category,
            'amount': t.amount,
            'date': ts(t.date),
            'note': t.note,
            'goal_id': t.goalId,
          },
      },
      'budgets': {
        for (final b in d.budgets)
          b.id: {
            'user_id': uid,
            'id': b.id,
            'category': b.category,
            'limit_amount': b.limit,
          },
      },
      'upcoming_items': {
        for (final u in d.upcoming)
          u.id: {
            'user_id': uid,
            'id': u.id,
            'name': u.name,
            'amount': u.amount,
            'is_expense': u.isExpense,
            'date': ts(u.date),
          },
      },
      // user_id always comes from the signed-in session ([uid]), never from
      // the Debt object. created_at / updated_at are managed by the database.
      'debts': {
        for (final x in d.debts) x.id: _debtRow(uid, x),
      },
      'user_missions': {
        for (final m in d.missions)
          m.id: {
            'user_id': uid,
            'mission_id': m.id,
            'template_id': m.templateId,
            'mission_date': m.date,
            'completed': m.isCompleted,
            'reward_granted': m.rewardGranted,
          },
      },
      'user_achievements': {
        for (final a in d.achievements)
          a: {
            'user_id': uid,
            'achievement_id': a,
            'unlocked': true,
          },
      },
      'user_customizations': {
        for (final id in d.unlockedCustomization)
          if (CustomizationCatalog.byId(id) != null)
            id: {
              'user_id': uid,
              'item_id': id,
              'category': CustomizationCatalog.byId(id)!.category,
              'equipped': d.equippedCustomization[
                      CustomizationCatalog.byId(id)!.category] ==
                  id,
            },
      },
    };
  }

  Map<String, dynamic> _debtRow(String uid, Debt x) => {
        'user_id': uid,
        'id': x.id,
        'type': x.type.value,
        'title': x.title,
        'person_name': x.personName,
        'original_amount': x.originalAmount,
        'amount_paid': x.amountPaid,
        'due_date': x.dueDate == null ? null : dateKey(x.dueDate!),
        'notes': x.notes,
        'status': x.status.value,
      };

  /// True when Postgres/PostgREST says the table does not exist (the debts
  /// migration has not been run yet).
  bool _isMissingTable(sb.PostgrestException e) =>
      e.code == '42P01' || e.code == 'PGRST205';

  /// Debts for the initial load. If the migration has not been applied yet,
  /// the rest of the app must still load, so a missing table counts as "no
  /// debts" here (saving a debt would then fail visibly via syncError).
  Future<List<Map<String, dynamic>>> _loadDebtRows(String uid) async {
    try {
      final rows = await _db
          .from('debts')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(rows);
    } on sb.PostgrestException catch (e) {
      if (_isMissingTable(e)) {
        debugPrint('debts table not found; run the debts migration.');
        return const [];
      }
      rethrow;
    }
  }

  /// Records what the DB currently holds, in the same shape [_rowsFor]
  /// produces, so the first save after a load only sends real changes.
  void _remember(String uid, StoredData data) {
    _synced.clear();
    _rowsFor(uid, data).forEach((table, rows) {
      _synced[table] = {
        for (final e in rows.entries) e.key: jsonEncode(e.value),
      };
    });
  }

  double _num(Object? v) => v is num ? v.toDouble() : double.parse('$v');

  SavingsGoal _goalFromRow(Map<String, dynamic> r) => SavingsGoal(
        id: r['id'] as String,
        name: r['name'] as String,
        targetAmount: _num(r['target_amount']),
        savedAmount: _num(r['saved_amount']),
        deadline: r['deadline'] == null
            ? null
            : DateTime.parse(r['deadline'] as String).toLocal(),
      );

  Transaction _transactionFromRow(Map<String, dynamic> r) => Transaction(
        id: r['id'] as String,
        type: TransactionType.values.byName(r['type'] as String),
        category: r['category'] as String,
        amount: _num(r['amount']),
        date: DateTime.parse(r['date'] as String).toLocal(),
        note: r['note'] as String?,
        goalId: r['goal_id'] as String?,
      );

  Budget _budgetFromRow(Map<String, dynamic> r) => Budget(
        id: r['id'] as String,
        category: r['category'] as String,
        limit: _num(r['limit_amount']),
      );

  UpcomingItem _upcomingFromRow(Map<String, dynamic> r) => UpcomingItem(
        id: r['id'] as String,
        name: r['name'] as String,
        amount: _num(r['amount']),
        isExpense: r['is_expense'] as bool,
        date: DateTime.parse(r['date'] as String).toLocal(),
      );

  /// Missions are predefined: title/rewards come from [MissionPool]; the DB
  /// only stores progress. Unknown template ids are skipped.
  Mission? _missionFromRow(Map<String, dynamic> r) {
    final templateId = r['template_id'] as String;
    final matches = MissionPool.all.where((t) => t.id == templateId);
    if (matches.isEmpty) return null;
    final t = matches.first;
    return Mission(
      id: r['mission_id'] as String,
      templateId: t.id,
      title: t.title,
      description: t.description,
      category: t.category,
      action: t.action,
      bucksReward: t.bucksReward,
      xpReward: t.xpReward,
      date: r['mission_date'] as String,
      isCompleted: r['completed'] as bool? ?? false,
      rewardGranted: r['reward_granted'] as bool? ?? false,
    );
  }

  String _friendly(Object e) {
    debugPrint('SupabaseService error: $e');
    final text = e.toString();
    if (text.contains('SocketException') ||
        text.contains('ClientException') ||
        text.contains('Failed host lookup')) {
      return 'Could not reach the server. Check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
