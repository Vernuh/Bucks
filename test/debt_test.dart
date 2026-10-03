import 'dart:io';

import 'package:bucks/models/debt.dart';
import 'package:bucks/models/transaction.dart';
import 'package:bucks/providers/app_state_provider.dart';
import 'package:bucks/screens/debt/debt_tracker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fake_backend.dart';

Debt sample({
  double original = 5000,
  double paid = 2000,
  DebtType type = DebtType.iOwe,
  DateTime? due,
}) =>
    Debt(
      id: 'debt_1',
      userId: 'user-1',
      type: type,
      title: 'Laptop installment',
      personName: 'Juan',
      originalAmount: original,
      amountPaid: paid,
      dueDate: due,
      notes: 'monthly',
      createdAt: DateTime.utc(2026, 10, 2, 3),
      updatedAt: DateTime.utc(2026, 10, 2, 4),
    );

void main() {
  // ---------------------------------------------------------------- model
  group('Debt model', () {
    test('serialization round-trips with the table\'s column names', () {
      final d = sample(due: DateTime(2026, 11, 30));
      final json = d.toJson();

      expect(json['type'], 'i_owe');
      expect(json['status'], 'active');
      expect(json['due_date'], '2026-11-30');
      expect(json['original_amount'], 5000);
      expect(json['amount_paid'], 2000);

      final back = Debt.fromJson(json);
      expect(back.id, d.id);
      expect(back.userId, 'user-1');
      expect(back.type, DebtType.iOwe);
      expect(back.title, 'Laptop installment');
      expect(back.personName, 'Juan');
      expect(back.originalAmount, 5000);
      expect(back.amountPaid, 2000);
      expect(back.dueDate, DateTime(2026, 11, 30));
      expect(back.notes, 'monthly');
      expect(back.createdAt.isAtSameMomentAs(d.createdAt), isTrue);
      expect(back.updatedAt.isAtSameMomentAs(d.updatedAt), isTrue);
    });

    test('accepts numeric strings and nulls from the database', () {
      final back = Debt.fromJson({
        'id': 'x',
        'user_id': 'u',
        'type': 'owed_to_me',
        'title': 'Borrowed money',
        'person_name': null,
        'original_amount': '1000.00',
        'amount_paid': '200.00',
        'due_date': null,
        'notes': null,
        'status': 'active',
        'created_at': '2026-10-02T03:00:00+00:00',
        'updated_at': '2026-10-02T03:00:00+00:00',
      });
      expect(back.type, DebtType.owedToMe);
      expect(back.originalAmount, 1000);
      expect(back.amountPaid, 200);
      expect(back.personName, isNull);
      expect(back.dueDate, isNull);
    });

    test('unknown type or status is rejected', () {
      expect(() => DebtType.fromValue('lent'), throwsFormatException);
      expect(() => DebtStatus.fromValue('overdue'), throwsFormatException);
    });

    test('remaining = original - paid, and never drifts on decimals', () {
      expect(sample().remaining, 3000);
      expect(sample(original: 0.3, paid: 0.1).remaining, 0.2);
      expect(sample(original: 100.10, paid: 0.10).remaining, 100);
    });

    test('status is derived: paid exactly when nothing remains', () {
      expect(sample(paid: 0).status, DebtStatus.active);
      expect(sample(paid: 4999.99).status, DebtStatus.active);
      expect(sample(paid: 5000).status, DebtStatus.paid);
      expect(sample(paid: 5000).remaining, 0);
    });

    test('progress is clamped 0..1 and overdue ignores paid debts', () {
      expect(sample(paid: 2500).progress, 0.5);
      final past = DateTime(2026, 10, 1);
      final today = DateTime(2026, 10, 2, 15);
      expect(sample(due: past).isOverdue(today), isTrue);
      expect(sample(due: DateTime(2026, 10, 2)).isOverdue(today), isFalse);
      expect(sample(due: past, paid: 5000).isOverdue(today), isFalse);
      expect(sample().isOverdue(today), isFalse); // no due date
    });
  });

  // ------------------------------------------------------------- provider
  group('AppStateProvider debts', () {
    late DateTime now;
    late FakeBackend backend;

    setUp(() {
      backend = FakeBackend();
      now = DateTime(2026, 10, 2, 10);
    });

    AppStateProvider newProvider() =>
        AppStateProvider(backend: backend, clock: () => now);

    Future<AppStateProvider> create({String email = 'a@test.com'}) async {
      final p = newProvider();
      final r = await p.register(
          username: 'Tester', email: email, password: 'secret12');
      expect(r.success, isTrue, reason: r.message);
      return p;
    }

    String firstId(AppStateProvider p, DebtType t) => p.debtsOfType(t).first.id;

    test('fresh account has no debts (empty state)', () async {
      final p = await create();
      expect(p.debts, isEmpty);
      expect(p.debtsOfType(DebtType.iOwe), isEmpty);
      expect(p.debtsOfType(DebtType.owedToMe), isEmpty);
      expect(p.totalIOwe, 0);
      expect(p.totalOwedToMe, 0);
      expect(p.nextDebtDue, isNull);
    });

    test('creates "Money I Owe" and "Money Owed to Me" separately', () async {
      final p = await create();
      final a = p.addDebt(
          type: DebtType.iOwe,
          title: '  Laptop installment ',
          personName: ' Juan ',
          amount: 5000,
          dueDate: DateTime(2026, 11, 30, 18),
          notes: 'monthly');
      final b = p.addDebt(
          type: DebtType.owedToMe,
          title: 'Borrowed money',
          personName: '   ',
          amount: 1000);
      expect(a.success, isTrue, reason: a.message);
      expect(b.success, isTrue, reason: b.message);

      final owe = p.debtsOfType(DebtType.iOwe);
      final owed = p.debtsOfType(DebtType.owedToMe);
      expect(owe.length, 1);
      expect(owed.length, 1);
      expect(owe.first.title, 'Laptop installment');
      expect(owe.first.personName, 'Juan');
      expect(owe.first.dueDate, DateTime(2026, 11, 30)); // date only
      expect(owe.first.amountPaid, 0);
      expect(owe.first.status, DebtStatus.active);
      expect(owed.first.personName, isNull); // blank -> optional
      expect(p.totalIOwe, 5000);
      expect(p.totalOwedToMe, 1000);
    });

    test('the debt belongs to the signed-in user, not a UI-supplied id',
        () async {
      final p = await create();
      p.addDebt(type: DebtType.iOwe, title: 'Rent', amount: 100);
      await p.flush();
      final uid = backend.currentUserId!;
      expect(p.debts.single.userId, uid);
      expect(backend.rowsFor(uid)!.debts.single.userId, uid);
    });

    test('rejects missing title and bad / negative amounts', () async {
      final p = await create();
      expect(
          p.addDebt(type: DebtType.iOwe, title: '  ', amount: 10).success,
          isFalse);
      for (final bad in [0.0, -5.0, double.nan, double.infinity, 0.001, 1e12]) {
        final r = p.addDebt(type: DebtType.iOwe, title: 'X', amount: bad);
        expect(r.success, isFalse, reason: 'amount $bad');
      }
      expect(p.debts, isEmpty);
    });

    test('recording a valid payment lowers the remaining balance', () async {
      final p = await create();
      p.addDebt(type: DebtType.iOwe, title: 'Laptop', amount: 5000);
      final id = firstId(p, DebtType.iOwe);

      final r = p.recordDebtPayment(id, 2000);
      expect(r.success, isTrue, reason: r.message);
      final d = p.debts.single;
      expect(d.amountPaid, 2000);
      expect(d.remaining, 3000);
      expect(d.status, DebtStatus.active);
      expect(p.totalIOwe, 3000);
    });

    test('a payment larger than the remaining balance is rejected', () async {
      final p = await create();
      p.addDebt(type: DebtType.iOwe, title: 'Laptop', amount: 5000);
      final id = firstId(p, DebtType.iOwe);
      p.recordDebtPayment(id, 2000);

      final r = p.recordDebtPayment(id, 3500);
      expect(r.success, isFalse);
      expect(p.debts.single.amountPaid, 2000); // unchanged
      expect(p.recordDebtPayment(id, 0).success, isFalse);
      expect(p.recordDebtPayment(id, -1).success, isFalse);
      expect(p.debts.single.amountPaid, 2000);
    });

    test('paying the full amount marks the debt paid', () async {
      final p = await create();
      p.addDebt(type: DebtType.owedToMe, title: 'Loan', amount: 1000);
      final id = firstId(p, DebtType.owedToMe);
      p.recordDebtPayment(id, 200);
      final r = p.recordDebtPayment(id, 800);
      expect(r.success, isTrue);
      final d = p.debts.single;
      expect(d.status, DebtStatus.paid);
      expect(d.amountPaid, d.originalAmount);
      expect(p.totalOwedToMe, 0);
      expect(p.recordDebtPayment(id, 1).success, isFalse); // already paid
    });

    test('amountPaid can never exceed originalAmount (even via edit)',
        () async {
      final p = await create();
      p.addDebt(type: DebtType.iOwe, title: 'Laptop', amount: 5000);
      final id = firstId(p, DebtType.iOwe);
      p.recordDebtPayment(id, 2000);

      final tooLow = p.updateDebt(id, title: 'Laptop', originalAmount: 1500);
      expect(tooLow.success, isFalse);
      expect(p.debts.single.originalAmount, 5000);

      // Editing down to exactly what was paid settles the debt.
      final exact = p.updateDebt(id, title: 'Laptop', originalAmount: 2000);
      expect(exact.success, isTrue);
      expect(p.debts.single.status, DebtStatus.paid);
      for (final d in p.debts) {
        expect(d.amountPaid <= d.originalAmount, isTrue);
      }
    });

    test('edit changes metadata and keeps payments', () async {
      final p = await create();
      p.addDebt(
          type: DebtType.iOwe, title: 'Old', personName: 'A', amount: 500);
      final id = firstId(p, DebtType.iOwe);
      p.recordDebtPayment(id, 100);

      final r = p.updateDebt(id,
          title: 'New',
          personName: '',
          originalAmount: 800,
          dueDate: DateTime(2026, 12, 1),
          notes: 'note');
      expect(r.success, isTrue, reason: r.message);
      final d = p.debts.single;
      expect(d.title, 'New');
      expect(d.personName, isNull);
      expect(d.originalAmount, 800);
      expect(d.amountPaid, 100);
      expect(d.type, DebtType.iOwe); // direction is fixed
      expect(d.remaining, 700);
      expect(p.updateDebt(id, title: '', originalAmount: 800).success, isFalse);
    });

    test('delete removes the debt', () async {
      final p = await create();
      p.addDebt(type: DebtType.iOwe, title: 'One', amount: 10);
      p.addDebt(type: DebtType.iOwe, title: 'Two', amount: 20);
      final id = p.debts.first.id;
      expect(p.deleteDebt(id).success, isTrue);
      expect(p.debts.length, 1);
      expect(p.debts.any((d) => d.id == id), isFalse);
      expect(p.deleteDebt(id).success, isFalse); // already gone
    });

    test('debts persist and come back at the next login', () async {
      final p = await create();
      p.addDebt(type: DebtType.iOwe, title: 'Laptop', amount: 5000);
      p.recordDebtPayment(firstId(p, DebtType.iOwe), 1250.5);
      await p.flush();

      final p2 = newProvider();
      final r = await p2.signIn(email: 'a@test.com', password: 'secret12');
      expect(r.success, isTrue, reason: r.message);
      expect(p2.debts.length, 1);
      expect(p2.debts.single.amountPaid, 1250.5);
      expect(p2.debts.single.remaining, 3749.5);
    });

    test('user A\'s debts are invisible to and untouchable by user B',
        () async {
      final a = await create(email: 'a@test.com');
      a.addDebt(type: DebtType.iOwe, title: 'A secret', amount: 999);
      final aDebtId = a.debts.single.id;
      await a.flush();
      await a.signOut();

      final b = await create(email: 'b@test.com');
      expect(b.debts, isEmpty);
      expect((await b.refreshDebts()).success, isTrue);
      expect(b.debts, isEmpty);

      expect(b.recordDebtPayment(aDebtId, 1).success, isFalse);
      expect(b.updateDebt(aDebtId, title: 'x', originalAmount: 5).success,
          isFalse);
      expect(b.deleteDebt(aDebtId).success, isFalse);

      // A's data is intact.
      final a2 = newProvider();
      await a2.signIn(email: 'a@test.com', password: 'secret12');
      expect(a2.debts.single.title, 'A secret');
      expect(a2.debts.single.amountPaid, 0);
    });

    test('debts never create transactions, balance changes or rewards',
        () async {
      final p = await create();
      p.addTransaction(
          type: TransactionType.income, amount: 1000, category: 'Allowance');
      final txCount = p.transactions.length;
      final balance = p.availableBalance;
      final coins = p.buckCoins;
      final xp = p.xp;

      p.addDebt(type: DebtType.owedToMe, title: 'Friend owes me', amount: 1000);
      p.addDebt(type: DebtType.iOwe, title: 'I owe friend', amount: 700);
      p.recordDebtPayment(firstId(p, DebtType.owedToMe), 400);
      p.recordDebtPayment(firstId(p, DebtType.iOwe), 700);
      p.updateDebt(firstId(p, DebtType.owedToMe),
          title: 'Friend owes me', originalAmount: 1200);
      p.deleteDebt(firstId(p, DebtType.owedToMe));

      expect(p.transactions.length, txCount);
      expect(p.availableBalance, balance);
      expect(p.totalIncome, 1000);
      expect(p.totalExpenses, 0);
      expect(p.buckCoins, coins);
      expect(p.xp, xp);
    });

    test('refresh failure keeps the debts and shows a friendly error',
        () async {
      final p = await create();
      p.addDebt(type: DebtType.iOwe, title: 'Laptop', amount: 100);
      await p.flush();

      backend.failDebtLoads = true;
      final r = await p.refreshDebts();
      expect(r.success, isFalse);
      expect(p.debtsError, isNotNull);
      expect(p.debts.length, 1);
      expect(p.debtsLoading, isFalse);

      backend.failDebtLoads = false;
      expect((await p.refreshDebts()).success, isTrue);
      expect(p.debtsError, isNull);
    });

    test('refresh never overwrites a change that failed to save', () async {
      final p = await create();
      backend.failSaves = true;
      p.addDebt(type: DebtType.iOwe, title: 'Unsaved', amount: 50);
      await p.flush();

      final r = await p.refreshDebts();
      expect(r.success, isFalse);
      expect(p.debts.single.title, 'Unsaved'); // still in memory

      backend.failSaves = false;
      expect((await p.refreshDebts()).success, isTrue);
      expect(p.debts.single.title, 'Unsaved'); // saved, then reloaded
    });

    test('without a login nothing can be added, and sign-out clears debts',
        () async {
      final loggedOut = newProvider();
      expect(
          loggedOut.addDebt(type: DebtType.iOwe, title: 'x', amount: 1).success,
          isFalse);
      expect((await loggedOut.refreshDebts()).success, isFalse);

      final p = await create();
      p.addDebt(type: DebtType.iOwe, title: 'Laptop', amount: 100);
      await p.signOut();
      expect(p.debts, isEmpty);
    });
  });

  // --------------------------------------------------------------- schema
  group('supabase schema (static check of the SQL)', () {
    String sql(String path) =>
        File(path).readAsStringSync().replaceAll('\r\n', '\n');

    test('debts table has ownership, constraints and RLS', () {
      final schema = sql('lib/supabase/schema.sql');
      expect(schema, contains('create table if not exists public.debts'));
      final table = RegExp(r'create table if not exists public\.debts \((.*?)\n\);',
              dotAll: true)
          .firstMatch(schema)!
          .group(1)!;
      expect(
          RegExp(r'user_id\s+uuid not null references auth\.users \(id\) on delete cascade')
              .hasMatch(table),
          isTrue);
      expect(table, contains("check (type in ('i_owe', 'owed_to_me'))"));
      expect(table, contains("check (status in ('active', 'paid'))"));
      expect(table, contains('check (original_amount > 0)'));
      expect(table, contains('check (amount_paid >= 0)'));
      expect(table, contains('check (amount_paid <= original_amount)'));
      expect(RegExp(r'title\s+text not null').hasMatch(table), isTrue);

      // 'debts' is in the list the RLS loop turns into select/insert/
      // update/delete policies on (select auth.uid()) = user_id.
      final rls = RegExp(r"foreach t in array array\[([^\]]*)\] loop\n\s+execute format\('alter table public.%I enable row level security'",
              dotAll: true)
          .firstMatch(schema);
      expect(rls, isNotNull);
      expect(rls!.group(1), contains("'debts'"));
      expect(schema, contains('(select auth.uid()) = user_id'));
    });

    test('migration only adds debts: RLS on, 4 own-row policies, no drops', () {
      final m = sql('lib/supabase/migrations/2026-10-03_add_debts.sql');
      expect(m, contains('alter table public.debts enable row level security'));
      for (final op in ['select', 'insert', 'update', 'delete']) {
        expect(m, contains('create policy "debts_${op}_own" on public.debts'));
      }
      expect(m, contains('(select auth.uid()) = user_id'));
      expect(m, isNot(contains('using (true)')));
      expect(m, isNot(contains('with check (true)')));
      expect(m, isNot(contains('disable row level security')));
      expect(m, isNot(contains(RegExp(r'drop table', caseSensitive: false))));
      expect(m, isNot(contains(RegExp(r'truncate', caseSensitive: false))));
      expect(m, contains('revoke all on public.debts from anon'));
    });
  });

  // --------------------------------------------------------------- screen
  group('DebtTrackerScreen', () {
    late FakeBackend backend;
    late AppStateProvider provider;

    Future<void> setUpProvider(WidgetTester t,
        {void Function(AppStateProvider p)? seed}) async {
      backend = FakeBackend();
      provider = AppStateProvider(
          backend: backend, clock: () => DateTime(2026, 10, 2, 10));
      await t.runAsync(() async {
        final r = await provider.register(
            username: 'Tester', email: 'a@test.com', password: 'secret12');
        expect(r.success, isTrue);
        seed?.call(provider);
        await provider.flush();
      });
    }

    Future<void> show(WidgetTester t) async {
      await t.pumpWidget(
        ChangeNotifierProvider<AppStateProvider>.value(
          value: provider,
          child: const MaterialApp(home: DebtTrackerScreen()),
        ),
      );
      await t.pumpAndSettle();
    }

    testWidgets('shows friendly empty states for both tabs', (t) async {
      await setUpProvider(t);
      await show(t);

      expect(find.text('Debt Tracker'), findsOneWidget);
      expect(find.text('Keep track of money you owe and money owed to you.'),
          findsWidgets);
      expect(find.text('You don\'t have any debts you\'re tracking yet.'),
          findsOneWidget);
      expect(find.text('Add Debt'), findsWidgets);

      await t.tap(find.text('Money Owed to Me'));
      await t.pumpAndSettle();
      expect(find.text('No money owed to you is being tracked yet.'),
          findsOneWidget);
    });

    testWidgets('lists real debts with remaining balance and progress',
        (t) async {
      await setUpProvider(t, seed: (p) {
        p.addDebt(
            type: DebtType.iOwe,
            title: 'Laptop Installment',
            personName: 'Juan',
            amount: 5000,
            dueDate: DateTime(2099, 11, 30));
        p.recordDebtPayment(p.debts.first.id, 2000);
        p.addDebt(
            type: DebtType.owedToMe,
            title: 'Borrowed Money',
            personName: 'Juan',
            amount: 1000);
        p.recordDebtPayment(
            p.debtsOfType(DebtType.owedToMe).first.id, 200);
      });
      await show(t);

      expect(find.text('Laptop Installment'), findsOneWidget);
      expect(find.text('Owe: Juan'), findsOneWidget);
      expect(find.text('\u20b13,000 remaining'), findsOneWidget);
      expect(find.text('\u20b12,000 / \u20b15,000 paid'), findsOneWidget);
      expect(find.text('Due: Nov 30, 2099'), findsOneWidget);
      expect(find.text('Record Payment'), findsWidgets);

      await t.tap(find.text('Money Owed to Me'));
      await t.pumpAndSettle();
      expect(find.text('Borrowed Money'), findsOneWidget);
      expect(find.text('Owed by: Juan'), findsOneWidget);
      expect(find.text('\u20b1800 remaining'), findsOneWidget);
      expect(find.text('\u20b1200 / \u20b11,000 received'), findsOneWidget);
    });

    testWidgets('overpayment is blocked in the dialog; exact payment settles',
        (t) async {
      await setUpProvider(t, seed: (p) {
        p.addDebt(type: DebtType.iOwe, title: 'Laptop', amount: 5000);
        p.recordDebtPayment(p.debts.first.id, 2000);
      });
      await show(t);

      await t.tap(find.text('Record Payment'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), '3500');
      await t.tap(find.text('Save Payment'));
      await t.pumpAndSettle();
      expect(find.text('That\'s more than the \u20b13,000 left.'),
          findsOneWidget);
      expect(provider.debts.single.amountPaid, 2000);

      await t.enterText(find.byType(TextField), '3000');
      await t.tap(find.text('Save Payment'));
      await t.pumpAndSettle();
      expect(provider.debts.single.amountPaid, 5000);
      expect(provider.debts.single.status, DebtStatus.paid);
      expect(find.text('Fully paid'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
    });

    testWidgets('delete asks for confirmation first', (t) async {
      await setUpProvider(t, seed: (p) {
        p.addDebt(type: DebtType.iOwe, title: 'Laptop', amount: 5000);
      });
      await show(t);

      await t.tap(find.byTooltip('Delete'));
      await t.pumpAndSettle();
      expect(find.text('Delete this debt?'), findsOneWidget);
      expect(provider.debts.length, 1);

      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(provider.debts.length, 1);

      await t.tap(find.byTooltip('Delete'));
      await t.pumpAndSettle();
      await t.tap(find.text('Delete'));
      await t.pumpAndSettle();
      expect(provider.debts, isEmpty);
    });

    testWidgets('adding a debt validates, then saves', (t) async {
      await setUpProvider(t);
      await show(t);

      await t.tap(find.text('Add Debt').first);
      await t.pumpAndSettle();
      await t.tap(find.text('Save Debt'));
      await t.pumpAndSettle();
      expect(find.textContaining('Enter a short title'), findsOneWidget);
      expect(find.text('Enter the amount as a number.'), findsOneWidget);
      expect(provider.debts, isEmpty);

      await t.enterText(find.widgetWithText(TextField, 'Title'), 'Laptop');
      await t.enterText(
          find.widgetWithText(TextField, 'Original amount'), '0');
      await t.tap(find.text('Save Debt'));
      await t.pumpAndSettle();
      expect(find.text('The amount must be greater than 0.'), findsOneWidget);

      await t.enterText(
          find.widgetWithText(TextField, 'Original amount'), '1,500.50');
      await t.tap(find.text('Save Debt'));
      await t.pumpAndSettle();
      expect(provider.debts.single.originalAmount, 1500.5);
      expect(provider.debts.single.type, DebtType.iOwe);
    });

    testWidgets('narrow phone width does not overflow', (t) async {
      t.view.physicalSize = const Size(320, 640);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);

      await setUpProvider(t, seed: (p) {
        p.addDebt(
            type: DebtType.iOwe,
            title: 'A very long debt title that keeps going and going',
            personName: 'Somebody With A Really Long Name Here',
            amount: 123456789.5,
            dueDate: DateTime(2020, 1, 1),
            notes: 'Some notes that are fairly long, '
                'long enough to wrap over more than a single line of text.');
      });
      await show(t);

      expect(t.takeException(), isNull);
      expect(find.text('Overdue \u2022 Due: Jan 1, 2020'), findsOneWidget);
    });
  });
}
