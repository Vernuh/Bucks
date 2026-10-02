import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/formatters.dart';

/// Full transaction history, newest first, read straight from
/// [AppStateProvider]. Adding transactions happens on the "Add" tab.
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  static const _navy = Color(0xFF17213F);
  static const _incomeGreen = Color(0xFF168B2D);
  static const _expenseRed = Color(0xFFF44336);
  static const _savingsBlue = Color(0xFF1688F5);

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<AppStateProvider>().transactions;

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: transactions.isEmpty
          ? const Center(child: Text('No transactions yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _TransactionTile(tx: transactions[i]),
            ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final (label, color, sign, icon) = switch (tx.type) {
      TransactionType.income => (
          'Income',
          TransactionsScreen._incomeGreen,
          '+',
          Icons.arrow_downward,
        ),
      TransactionType.expense => (
          'Expense',
          TransactionsScreen._expenseRed,
          '-',
          Icons.arrow_upward,
        ),
      TransactionType.savings => (
          'Savings',
          TransactionsScreen._savingsBlue,
          '-',
          Icons.savings,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E1D3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(30),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label \u2022 ${tx.category}',
                  style: const TextStyle(
                    color: TransactionsScreen._navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formatDate(tx.date),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (tx.note != null)
                  Text(
                    tx.note!,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            '$sign${formatPeso(tx.amount)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
