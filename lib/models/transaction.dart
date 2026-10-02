/// Income and expenses are the two "real" money-in / money-out types.
/// [savings] is a contribution to a [SavingsGoal]: money moved out of the
/// available balance, but NOT counted as an expense.
enum TransactionType { income, expense, savings }

/// A single entry in the user's history. There is exactly one object per
/// entry; every screen derives its numbers from the shared list.
class Transaction {
  final String id;
  final TransactionType type;
  final String category; // e.g. "Food", "Allowance", or the goal's name
  final double amount;
  final DateTime date;
  final String? note;

  /// Only set for [TransactionType.savings].
  final String? goalId;

  Transaction({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
    this.goalId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        'goalId': goalId,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        type: TransactionType.values.byName(json['type'] as String),
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
        goalId: json['goalId'] as String?,
      );
}
