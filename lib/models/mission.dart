enum MissionCategory { budget, tracking, savings, learning, streak }

/// Represents a single daily mission (e.g. "Log today's expenses").
class Mission {
  final String id;
  final String title;
  final MissionCategory category;
  final int rewardPoints;
  final bool isCompleted;

  Mission({
    required this.id,
    required this.title,
    required this.category,
    required this.rewardPoints,
    this.isCompleted = false,
  });
}
