enum TransactionType { income, expense }

/// Represents a single income or expense entry.
class Transaction {
  final String id;
  final TransactionType type;
  final String category; // e.g. "Food", "Allowance"
  final double amount;
  final DateTime date;
  final String? note;

  Transaction({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
  });
}
