import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/categories.dart';
import '../../models/transaction.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_theme.dart';

enum _EntryType { income, expense, savings }

/// The "Add" bottom-nav tab: lets the user log an income/expense entry or contribute to a savings goal.

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  _EntryType _type = _EntryType.expense;
  String? _selectedCategory;
  String? _selectedGoalId;

  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  List<String> get _categoriesForType {
    return switch (_type) {
      _EntryType.income => Categories.income,
      _EntryType.expense => Categories.expense,
      _EntryType.savings => const [],
    };
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectType(_EntryType type) {
    setState(() {
      _type = type;
      _selectedCategory = null; // reset category when switching type
      _selectedGoalId = null;
    });
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      _showMessage('Enter a valid amount.');
      return;
    }
    if (_type != _EntryType.savings && _selectedCategory == null) {
      _showMessage('Pick a category.');
      return;
    }
    if (_type == _EntryType.savings && _selectedGoalId == null) {
      _showMessage('Pick a savings goal.');
      return;
    }

    final txType = switch (_type) {
      _EntryType.income => TransactionType.income,
      _EntryType.expense => TransactionType.expense,
      _EntryType.savings => TransactionType.savings,
    };

    final result = context.read<AppStateProvider>().addTransaction(
          type: txType,
          amount: amount,
          category: _selectedCategory,
          goalId: _selectedGoalId,
          note: _notesController.text,
        );

    _showMessage(result.message);
    if (!result.success) return;

    setState(() {
      _amountController.clear();
      _notesController.clear();
      _selectedCategory = null;
      _selectedGoalId = null;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<AppStateProvider>().goals;
    // If the selected goal vanished (e.g. data reset), clear the selection.
    if (_selectedGoalId != null && !goals.any((g) => g.id == _selectedGoalId)) {
      _selectedGoalId = null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TypeToggle(selected: _type, onSelected: _selectType),
              const SizedBox(height: 24),
              Text('Amount', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixText: '₱ ',
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 24),
              if (_type == _EntryType.savings) ...[
                Text('Savings Goal', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (goals.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'No savings goals yet. Create one in the Goals tab first.',
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: goals.map((goal) {
                      final isSelected = goal.id == _selectedGoalId;
                      return ChoiceChip(
                        label: Text(goal.name),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedGoalId = goal.id),
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textDark,
                        ),
                      );
                    }).toList(),
                  ),
              ] else ...[
                Text('Category', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categoriesForType.map((category) {
                    final isSelected = category == _selectedCategory;
                    return ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategory = category),
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textDark,
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
              Text('Notes (optional)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Add a note...'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Income / Expense / Savings toggle row at the top of the screen.
class _TypeToggle extends StatelessWidget {
  final _EntryType selected;
  final ValueChanged<_EntryType> onSelected;

  const _TypeToggle({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _EntryType.values.map((type) {
        final isSelected = type == selected;
        final label = switch (type) {
          _EntryType.income => 'Income',
          _EntryType.expense => 'Expense',
          _EntryType.savings => 'Savings',
        };
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Center(child: Text(label)),
              selected: isSelected,
              onSelected: (_) => onSelected(type),
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
