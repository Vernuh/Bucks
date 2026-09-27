import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// UI-only entry type for this screen's toggle. This is separate from
/// [TransactionType] in models/transaction.dart because "Savings" here
/// means "contribute to a SavingsGoal", not a new transaction category —
/// those are different concepts once we wire up real data.
enum _EntryType { income, expense, savings }

/// The "Add" bottom-nav tab: lets the user log an income/expense entry
/// or contribute to a savings goal.
///
/// NOTE: Save doesn't persist anywhere yet — there's no StorageService
/// or provider wired up for transactions/goals yet. It validates the
/// form and confirms via a snackbar so you can see the flow works.
/// Wiring this into real state (so it shows up in Transactions history
/// and updates Home's balance) is the next step.
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  _EntryType _type = _EntryType.expense;
  String? _selectedCategory;

  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  // Matches the categories from the project spec. If these end up
  // needed elsewhere (e.g. editing a transaction later), we'll pull
  // them into a shared constants file — not worth it for one screen yet.
  static const _incomeCategories = ['Allowance', 'Salary', 'Freelance', 'Gift', 'Other'];
  static const _expenseCategories = [
    'Food',
    'Transportation',
    'School',
    'Entertainment',
    'Shopping',
    'Bills',
    'Other',
  ];

  List<String> get _categoriesForType {
    return switch (_type) {
      _EntryType.income => _incomeCategories,
      _EntryType.expense => _expenseCategories,
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
    });
  }

  void _save() {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      _showMessage('Enter a valid amount.');
      return;
    }
    if (_type != _EntryType.savings && _selectedCategory == null) {
      _showMessage('Pick a category.');
      return;
    }

    final label = switch (_type) {
      _EntryType.income => 'Income',
      _EntryType.expense => 'Expense',
      _EntryType.savings => 'Savings contribution',
    };
    final categorySuffix = _selectedCategory != null ? ' ($_selectedCategory)' : '';
    _showMessage('$label saved: ₱$amountText$categorySuffix');

    setState(() {
      _amountController.clear();
      _notesController.clear();
      _selectedCategory = null;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Goal picker will appear here once Savings Goals are wired up.',
                  ),
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
