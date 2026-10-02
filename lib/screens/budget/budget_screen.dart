import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/budget.dart';
import '../../models/categories.dart';
import '../../models/mission.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/formatters.dart';

/// Monthly budgets per expense category. "Spent" is derived by
/// [AppStateProvider] from the same transactions Home uses, so the two
/// screens can never disagree.
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  static const _blue = Color(0xFF1688F5);
  static const _navy = Color(0xFF17213F);
  static const _green = Color(0xFF218B0D);
  static const _red = Color(0xFFE74C3C);
  static const _orange = Color(0xFFFFA726);

  @override
  void initState() {
    super.initState();
    // Opening the Budget Planner counts for budget-check missions.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppStateProvider>().recordVisit(MissionAction.openBudget);
      }
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openBudgetDialog({Budget? existing}) async {
    final app = context.read<AppStateProvider>();
    final limitController = TextEditingController(
      text: existing == null ? '' : existing.limit.toStringAsFixed(0),
    );
    // Categories that don't have a budget yet (plus the one being edited).
    final used = app.budgets.map((b) => b.category).toSet();
    final available = Categories.expense
        .where((c) => !used.contains(c) || c == existing?.category)
        .toList();
    String? category = existing?.category;
    String? error;

    if (available.isEmpty) {
      _toast('Every category already has a budget.');
      limitController.dispose();
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'New Budget' : 'Edit Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (existing == null)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: available
                      .map((c) => ChoiceChip(
                            label: Text(c),
                            selected: category == c,
                            onSelected: (_) =>
                                setDialogState(() => category = c),
                          ))
                      .toList(),
                )
              else
                Text(existing.category,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: limitController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monthly limit',
                  prefixText: '\u20b1 ',
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (category == null) {
                  setDialogState(() => error = 'Pick a category.');
                  return;
                }
                final limit = double.tryParse(limitController.text.trim());
                final result =
                    app.setBudget(category: category!, limit: limit ?? 0);
                if (!result.success) {
                  setDialogState(() => error = result.message);
                  return;
                }
                Navigator.pop(dialogContext);
                _toast(result.message);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    limitController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final budgets = app.budgets;

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Planner')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBudgetDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
      ),
      body: budgets.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No budgets yet. Add one to track your monthly spending '
                  'per category.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _summary(app),
                const SizedBox(height: 12),
                for (final b in budgets) _budgetCard(b),
              ],
            ),
    );
  }

  Widget _summary(AppStateProvider app) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _blue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This month',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            '${formatPeso(app.totalBudgetSpent)} spent of '
            '${formatPeso(app.totalBudgetLimit)}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            '${formatPeso(app.budgetRemaining)} remaining',
            style: const TextStyle(color: Color(0xFFFFD21F)),
          ),
        ],
      ),
    );
  }

  Widget _budgetCard(Budget b) {
    final color = b.isOver ? _red : (b.isNearLimit ? _orange : _green);
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
            children: [
              Expanded(
                child: Text(
                  b.category,
                  style: const TextStyle(
                      color: _navy, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _openBudgetDialog(existing: b),
              ),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () {
                  final result =
                      context.read<AppStateProvider>().removeBudget(b.id);
                  _toast(result.message);
                },
              ),
            ],
          ),
          Text('${formatPeso(b.spent)} / ${formatPeso(b.limit)}'),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: b.progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            b.isOver
                ? 'Over budget by ${formatPeso(-b.remaining)}'
                : '${formatPeso(b.remaining)} remaining',
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
