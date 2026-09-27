/// Represents a savings goal like "New Laptop: ₱15,000 / ₱30,000".
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

  double get progress =>
      targetAmount == 0 ? 0 : savedAmount / targetAmount;
}
