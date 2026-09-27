/// Represents a spending limit set for a specific category
/// (e.g. "Food Budget: ₱3,000/month").
class Budget {
  final String id;
  final String category;
  final double limit;
  final double spent;

  Budget({
    required this.id,
    required this.category,
    required this.limit,
    required this.spent,
  });

  double get remaining => limit - spent;

  /// Value from 0.0 to 1.0+ representing how much of the budget is used.
  double get progress => limit == 0 ? 0 : spent / limit;
}
