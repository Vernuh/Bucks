/// A savings goal like "Laptop: ₱15,000 / ₱25,000".
class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    this.deadline,
  });

  /// 0.0 – 1.0 (clamped so over-saving doesn't overflow progress bars).
  double get progress =>
      targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0.0, 1.0);

  bool get isComplete => targetAmount > 0 && savedAmount >= targetAmount;

  SavingsGoal copyWith({double? savedAmount}) => SavingsGoal(
        id: id,
        name: name,
        targetAmount: targetAmount,
        savedAmount: savedAmount ?? this.savedAmount,
        deadline: deadline,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'deadline': deadline?.toIso8601String(),
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
        id: json['id'] as String,
        name: json['name'] as String,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        savedAmount: (json['savedAmount'] as num).toDouble(),
        deadline: json['deadline'] == null
            ? null
            : DateTime.parse(json['deadline'] as String),
      );
}
