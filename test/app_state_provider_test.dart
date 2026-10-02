import 'package:bucks/models/transaction.dart';
import 'package:bucks/providers/app_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fake_backend.dart';

void main() {
  late DateTime now;
  late FakeBackend backend;

  setUp(() {
    backend = FakeBackend();
    now = DateTime(2026, 10, 2, 10);
  });

  AppStateProvider newProvider() =>
      AppStateProvider(backend: backend, clock: () => now);

  /// Registers a brand-new account and returns its loaded provider.
  Future<AppStateProvider> create({String email = 'a@test.com'}) async {
    final p = newProvider();
    final r = await p.register(
        username: 'Tester', email: email, password: 'secret12');
    expect(r.success, isTrue, reason: r.message);
    return p;
  }

  test('level thresholds', () {
    expect(AppStateProvider.xpForLevel(1), 0);
    expect(AppStateProvider.xpForLevel(2), 100);
    expect(AppStateProvider.xpForLevel(3), 250);
    expect(AppStateProvider.levelForXp(99), 1);
    expect(AppStateProvider.levelForXp(100), 2);
    expect(AppStateProvider.levelForXp(250), 3);
  });

  test('fresh account has no fake data', () async {
    final p = await create();
    expect(p.isSignedIn, isTrue);
    expect(p.username, 'Tester');
    expect(p.transactions, isEmpty);
    expect(p.goals, isEmpty);
    expect(p.availableBalance, 0);
    expect(p.buckCoins, 0);
    expect(p.missions.length, 3);
  });

  test('income and expense feed the shared totals', () async {
    final p = await create();
    p.addTransaction(
        type: TransactionType.income, amount: 5000, category: 'Allowance');
    p.addTransaction(
        type: TransactionType.expense, amount: 150, category: 'Food');

    expect(p.spentToday, 150);
    expect(p.totalExpenses, 150);
    expect(p.availableBalance, 4850);
    expect(p.transactions.first.category, 'Food'); // newest first
  });

  test('savings contribution updates the same goal, not expenses', () async {
    final p = await create();
    p.addGoal(name: 'Laptop', target: 25000);
    final goalId = p.goals.first.id;

    final r = p.addTransaction(
        type: TransactionType.savings, amount: 1000, goalId: goalId);

    expect(r.success, isTrue);
    expect(p.goals.length, 1);
    expect(p.goals.first.savedAmount, 1000);
    expect(p.totalSaved, 1000);
    expect(p.totalExpenses, 0);
    expect(p.isAchievementUnlocked('savings_starter'), isTrue);
  });

  test('budget spent is derived from transactions', () async {
    final p = await create();
    p.setBudget(category: 'Food', limit: 3000);
    p.addTransaction(
        type: TransactionType.expense, amount: 500, category: 'Food');

    final b = p.budgets.first;
    expect(b.spent, 500);
    expect(b.remaining, 2500);
  });

  test('rewards are only granted once', () async {
    final p = await create();
    p.addTransaction(
        type: TransactionType.expense, amount: 10, category: 'Food');
    final afterFirst = p.buckCoins;
    final xpAfterFirst = p.xp;

    p.addTransaction(
        type: TransactionType.expense, amount: 10, category: 'Food');
    p.recordAppOpened();
    p.recordAppOpened();

    // The second expense can't re-complete a mission or re-unlock an
    // achievement. Only the (once-only) open-app mission may add rewards.
    final openApp = p.missions.where((m) => m.templateId == 'open_bucks' ||
        m.templateId == 'maintain_streak');
    final extra = openApp.fold<int>(0, (s, m) => s + m.bucksReward);
    expect(p.buckCoins, afterFirst + extra);
    expect(p.xp >= xpAfterFirst, isTrue);

    final coinsNow = p.buckCoins;
    p.recordAppOpened();
    expect(p.buckCoins, coinsNow);
  });

  test('purchase, duplicate purchase and insufficient funds', () async {
    final p = await create();
    p.debugSetBuckCoins(150);

    expect(p.purchaseCustomizationItem('hat_simple').success, isTrue);
    expect(p.buckCoins, 100);
    expect(p.isCustomizationUnlocked('hat_simple'), isTrue);

    // Duplicate: no second charge.
    expect(p.purchaseCustomizationItem('hat_simple').success, isFalse);
    expect(p.buckCoins, 100);

    // Insufficient funds: nothing changes.
    p.debugSetBuckCoins(30);
    final r = p.purchaseCustomizationItem('hat_cap'); // 75
    expect(r.success, isFalse);
    expect(r.message, 'Not enough Bucks!');
    expect(p.buckCoins, 30);
    expect(p.isCustomizationUnlocked('hat_cap'), isFalse);
  });

  test('equip needs ownership and replaces within a category', () async {
    final p = await create();
    p.debugSetBuckCoins(500);

    expect(p.equipCustomizationItem('hat_simple').success, isFalse);

    p.purchaseCustomizationItem('hat_simple');
    p.purchaseCustomizationItem('hat_cap');
    p.equipCustomizationItem('hat_simple');
    expect(p.isCustomizationEquipped('hat_simple'), isTrue);

    p.equipCustomizationItem('hat_cap');
    expect(p.isCustomizationEquipped('hat_simple'), isFalse);
    expect(p.isCustomizationEquipped('hat_cap'), isTrue);
  });

  test('everything persists across a restart (session restored)', () async {
    final p1 = await create();
    p1.debugSetBuckCoins(150);
    p1.purchaseCustomizationItem('hat_simple');
    p1.equipCustomizationItem('hat_simple');
    p1.addGoal(name: 'Laptop', target: 25000);
    p1.addTransaction(
        type: TransactionType.expense, amount: 150, category: 'Food');
    await p1.flush();

    // New provider = app restart; the backend still has the session.
    final p2 = newProvider();
    expect(p2.authStatus, AuthStatus.initializing);
    await p2.restoreSession();

    expect(p2.isSignedIn, isTrue);
    expect(p2.buckCoins, p1.buckCoins);
    expect(p2.xp, p1.xp);
    expect(p2.isCustomizationUnlocked('hat_simple'), isTrue);
    expect(p2.isCustomizationEquipped('hat_simple'), isTrue);
    expect(p2.transactions.length, 1);
    expect(p2.goals.length, 1);
    expect(p2.currentStreak, p1.currentStreak);
    expect(p2.missions.map((m) => m.id), p1.missions.map((m) => m.id));
    expect(p2.missions.map((m) => m.isCompleted),
        p1.missions.map((m) => m.isCompleted));
  });

  test('no session on start -> signed out', () async {
    final p = newProvider();
    await p.restoreSession();
    expect(p.authStatus, AuthStatus.signedOut);
  });

  test('wrong password fails and stays signed out', () async {
    await create();
    await backend.signOut();
    final p = newProvider();
    final r = await p.signIn(email: 'a@test.com', password: 'nope');
    expect(r.success, isFalse);
    expect(p.isSignedIn, isFalse);
  });

  test('logout clears in-memory state; login restores it', () async {
    final p = await create();
    p.addTransaction(
        type: TransactionType.income, amount: 500, category: 'Allowance');
    await p.flush();

    expect((await p.signOut()).success, isTrue);
    expect(p.authStatus, AuthStatus.signedOut);
    expect(p.transactions, isEmpty);
    expect(p.buckCoins, 0);
    expect(p.username, '');

    final r = await p.signIn(email: 'a@test.com', password: 'secret12');
    expect(r.success, isTrue);
    expect(p.transactions.length, 1);
  });

  test('user B never sees user A data', () async {
    final a = await create(email: 'a@test.com');
    a.addTransaction(
        type: TransactionType.income, amount: 500, category: 'Allowance');
    a.addGoal(name: 'Laptop', target: 1000);
    a.setBudget(category: 'Food', limit: 100);
    await a.flush();
    await a.signOut();

    final b = await create(email: 'b@test.com');
    expect(b.transactions, isEmpty);
    expect(b.goals, isEmpty);
    expect(b.budgets, isEmpty);
    expect(b.availableBalance, 0);
  });

  test('failed save keeps data in memory, reports and retries', () async {
    final p = await create();
    backend.failSaves = true;
    p.addTransaction(
        type: TransactionType.expense, amount: 20, category: 'Food');
    await p.flush();
    expect(p.syncError, isNotNull);
    expect(p.transactions.length, 1);

    backend.failSaves = false;
    p.retrySync();
    await p.flush();
    expect(p.syncError, isNull);
    expect(backend.rowsFor(backend.currentUserId!)!.transactions.length, 1);
  });

  test('same day keeps missions; new day regenerates and grows streak',
      () async {
    final p = await create();
    final today = p.missions.map((m) => m.id).toList();

    p.refreshDay();
    expect(p.missions.map((m) => m.id).toList(), today);

    now = DateTime(2026, 10, 3, 9);
    p.refreshDay();
    expect(p.missions.first.date, '2026-10-03');
    expect(p.currentStreak, 2);

    // Skipping a day resets the streak.
    now = DateTime(2026, 10, 6, 9);
    p.refreshDay();
    expect(p.currentStreak, 1);
  });
}
