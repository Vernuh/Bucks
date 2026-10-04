/// A monthly spending limit for one expense category
/// (e.g. "Food: ₱3,000 / month").

class Budget {
  final String id;
  final String category;
  final double limit;
  final double spent;

  Budget({
    required this.id,
    required this.category,
    required this.limit,
    this.spent = 0,
  });

  double get remaining => limit - spent;

  /// Value from 0.0 to 1.0+ representing how much of the budget is used.
  double get progress => limit <= 0 ? 0 : spent / limit;

  bool get isOver => spent > limit;

  /// 80% or more used, but not over yet.
  bool get isNearLimit => !isOver && progress >= 0.8;

  Budget copyWith({double? limit, double? spent}) => Budget(
        id: id,
        category: category,
        limit: limit ?? this.limit,
        spent: spent ?? this.spent,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'limit': limit,
      };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'] as String,
        category: json['category'] as String,
        limit: (json['limit'] as num).toDouble(),
      );
}
