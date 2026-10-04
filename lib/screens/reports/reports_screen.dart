import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/mission.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/formatters.dart';

/// Reports & Charts, drawn with plain Flutter widgets (no chart package)
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _blue = Color(0xFF1688F5);
  static const _navy = Color(0xFF17213F);
  static const _green = Color(0xFF2ECC71);
  static const _red = Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    // Opening Reports counts for learning missions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppStateProvider>().recordVisit(MissionAction.openReports);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Charts')),
      body: !app.hasTransactions
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Add more transactions to see your spending trends.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _incomeVsExpenses(app),
                const SizedBox(height: 16),
                _spendingByCategory(app),
                const SizedBox(height: 16),
                _monthlySpending(app),
                const SizedBox(height: 16),
                _savingsProgress(app),
              ],
            ),
    );
  }

  Widget _card(String title, String subtitle, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E1D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: _navy, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _barRow(String label, double value, double max, Color color) {
    final factor = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: _navy, fontSize: 13)),
              Text(formatPeso(value),
                  style: const TextStyle(
                      color: _navy, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: factor,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  double _maxOf(Iterable<double> values) =>
      values.fold(0.0, (a, b) => a > b ? a : b);

  Widget _incomeVsExpenses(AppStateProvider app) {
    final income = app.incomeThisMonth;
    final expenses = app.expensesThisMonth;
    final max = _maxOf([income, expenses]);
    return _card('Income vs Expenses', 'This month', [
      _barRow('Income', income, max, _green),
      _barRow('Expenses', expenses, max, _red),
      Text(
        'Savings contributed: ${formatPeso(app.savedThisMonth)}',
        style: const TextStyle(color: _blue, fontSize: 12),
      ),
    ]);
  }

  Widget _spendingByCategory(AppStateProvider app) {
    final entries = app.spendingByCategoryThisMonth;
    final max = _maxOf(entries.map((e) => e.value));
    return _card('Spending by Category', 'This month', [
      if (entries.isEmpty)
        const Text('No expenses logged this month yet.')
      else
        for (final e in entries) _barRow(e.key, e.value, max, _blue),
    ]);
  }

  Widget _monthlySpending(AppStateProvider app) {
    final months = app.monthlySummaries(count: 6);
    final max = _maxOf(months.map((m) => m.expenses));
    return _card('Monthly Spending', 'Last 6 months', [
      if (max <= 0)
        const Text('No expenses logged in the last 6 months.')
      else
        for (final m in months) _barRow(m.month, m.expenses, max, _navy),
    ]);
  }

  Widget _savingsProgress(AppStateProvider app) {
    final goals = app.goals;
    return _card('Savings Progress', 'Your goals', [
      if (goals.isEmpty)
        const Text('No savings goals yet. Create one in the Goals tab.')
      else
        for (final g in goals) ...[
          _barRow(g.name, g.savedAmount, g.targetAmount, _green),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${(g.progress * 100).round()}% of ${formatPeso(g.targetAmount)}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
            ),
          ),
        ],
    ]);
  }
}
