import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/debt.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/formatters.dart';
import '../debt/debt_dialogs.dart';

/// Debt Tracker: "Money I Owe" and "Money Owed to Me".
///
/// Reads everything from [AppStateProvider] (which loads/saves through
/// Supabase). This screen holds no database logic and no sample data.
class DebtTrackerScreen extends StatefulWidget {
  const DebtTrackerScreen({super.key});

  @override
  State<DebtTrackerScreen> createState() => _DebtTrackerScreenState();
}

class _DebtTrackerScreenState extends State<DebtTrackerScreen>
    with SingleTickerProviderStateMixin {
  static const _blue = Color(0xFF1688F5);
  static const _navy = Color(0xFF17213F);
  static const _yellow = Color(0xFFFFD21F);

  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    // Debts were loaded at login; opening the screen refreshes them so
    // changes made on another device show up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppStateProvider>().refreshDebts();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  DebtType get _currentType =>
      _tabs.index == 0 ? DebtType.iOwe : DebtType.owedToMe;

  void _add([DebtType? type]) =>
      showDebtFormDialog(context, initialType: type ?? _currentType);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final ready = app.isSignedIn && app.isLoaded;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Tracker'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: _navy,
          unselectedLabelColor: Colors.black54,
          indicatorColor: _blue,
          tabs: const [
            Tab(text: 'Money I Owe'),
            Tab(text: 'Money Owed to Me'),
          ],
        ),
      ),
      floatingActionButton: ready
          ? FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Add Debt'),
            )
          : null,
      body: !ready
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Please log in to use the Debt Tracker.',
                    textAlign: TextAlign.center),
              ),
            )
          : TabBarView(
              controller: _tabs,
              children: [
                _buildList(app, DebtType.iOwe),
                _buildList(app, DebtType.owedToMe),
              ],
            ),
    );
  }

  Widget _buildList(AppStateProvider app, DebtType type) {
    final owe = type == DebtType.iOwe;
    final debts = app.debtsOfType(type);
    final today = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Center the content on wide screens (desktop / tablet) and keep
        // normal padding on phones.
        final side = constraints.maxWidth > 760
            ? (constraints.maxWidth - 720) / 2
            : 16.0;

        final children = <Widget>[
          const Text(
            'Keep track of money you owe and money owed to you.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          if (app.debtsError != null) _errorBanner(app),
        ];

        if (app.debtsLoading && app.debts.isEmpty) {
          children.add(const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Center(child: CircularProgressIndicator()),
          ));
        } else {
          children.add(_summary(
            label: owe ? 'You still owe' : 'Still owed to you',
            total: owe ? app.totalIOwe : app.totalOwedToMe,
            activeCount: debts.where((d) => d.isActive).length,
          ));
          children.add(const SizedBox(height: 12));
          if (debts.isEmpty) {
            children.add(_emptyState(owe, type));
          } else {
            for (final d in debts) {
              children.add(_DebtCard(
                debt: d,
                today: today,
                onPay: () => showRecordPaymentDialog(context, d),
                onEdit: () => showDebtFormDialog(context, existing: d),
                onDelete: () => confirmDeleteDebt(context, d),
              ));
            }
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            await context.read<AppStateProvider>().refreshDebts();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(side, 16, side, 96),
            children: children,
          ),
        );
      },
    );
  }

  Widget _errorBanner(AppStateProvider app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE74C3C)),
          const SizedBox(width: 8),
          Expanded(child: Text(app.debtsError!)),
          TextButton(
            onPressed: app.debtsLoading ? null : app.refreshDebts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _summary({
    required String label,
    required double total,
    required int activeCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _blue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            formatPeso(total),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
          ),
          Text(
            activeCount == 1 ? '1 active debt' : '$activeCount active debts',
            style: const TextStyle(color: _yellow),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(bool owe, DebtType type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet,
              size: 48, color: _blue.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            owe
                ? 'You don\'t have any debts you\'re tracking yet.'
                : 'No money owed to you is being tracked yet.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _yellow,
              foregroundColor: _navy,
            ),
            onPressed: () => _add(type),
            icon: const Icon(Icons.add),
            label: const Text('Add Debt'),
          ),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  static const _blue = Color(0xFF1688F5);
  static const _navy = Color(0xFF17213F);
  static const _green = Color(0xFF218B0D);
  static const _red = Color(0xFFE74C3C);

  final Debt debt;
  final DateTime today;
  final VoidCallback onPay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DebtCard({
    required this.debt,
    required this.today,
    required this.onPay,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final owe = debt.type == DebtType.iOwe;
    final overdue = debt.isOverdue(today);
    final barColor = !debt.isActive ? _green : (overdue ? _red : _blue);
    final person = debt.personName;
    final notes = debt.notes;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E1D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.title,
                      style: const TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    if (person != null)
                      Text(owe ? 'Owe: $person' : 'Owed by: $person'),
                  ],
                ),
              ),
              _StatusChip(paid: !debt.isActive),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            debt.isActive
                ? '${formatPeso(debt.remaining)} remaining'
                : 'Fully paid',
            style: TextStyle(
                color: debt.isActive ? _navy : _green,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: debt.progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatPeso(debt.amountPaid)} / ${formatPeso(debt.originalAmount)} '
            '${owe ? 'paid' : 'received'}',
            style: const TextStyle(fontSize: 12),
          ),
          if (debt.dueDate != null) ...[
            const SizedBox(height: 4),
            Text(
              overdue
                  ? 'Overdue \u2022 Due: ${formatDate(debt.dueDate!)}'
                  : 'Due: ${formatDate(debt.dueDate!)}',
              style: TextStyle(
                color: overdue ? _red : Colors.black87,
                fontSize: 12,
                fontWeight: overdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
          if (notes != null) ...[
            const SizedBox(height: 4),
            Text(
              notes,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
          if (debt.isActive) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: onPay,
                child: const Text('Record Payment'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool paid;
  const _StatusChip({required this.paid});

  @override
  Widget build(BuildContext context) {
    final color = paid ? const Color(0xFF218B0D) : const Color(0xFF1688F5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        paid ? 'Paid' : 'Active',
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
