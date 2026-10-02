enum MissionCategory { budget, tracking, savings, learning, streak }

/// The real user action that completes a mission. Missions are completed by
/// AppStateProvider when it sees the matching action, never by a tap on a
/// checkbox.
enum MissionAction {
  logExpense,
  logIncome,
  addNote,
  saveMoney,
  stayOnBudget,
  openBudget,
  openGoals,
  openReports,
  openApp,
  anyActivity,
}

/// One of today's missions. Bucks Coins ([bucksReward]) are spendable;
/// XP ([xpReward]) is not.
class Mission {
  /// Unique per day: "<date>_<templateId>".
  final String id;
  final String templateId;
  final String title;
  final String description;
  final MissionCategory category;
  final MissionAction action;
  final int bucksReward;
  final int xpReward;

  /// "yyyy-MM-dd" the mission belongs to.
  final String date;
  final bool isCompleted;

  /// Persisted guard that makes rewards idempotent.
  final bool rewardGranted;

  Mission({
    required this.id,
    required this.templateId,
    required this.title,
    required this.description,
    required this.category,
    required this.action,
    required this.bucksReward,
    required this.xpReward,
    required this.date,
    this.isCompleted = false,
    this.rewardGranted = false,
  });

  Mission copyWith({bool? isCompleted, bool? rewardGranted}) => Mission(
        id: id,
        templateId: templateId,
        title: title,
        description: description,
        category: category,
        action: action,
        bucksReward: bucksReward,
        xpReward: xpReward,
        date: date,
        isCompleted: isCompleted ?? this.isCompleted,
        rewardGranted: rewardGranted ?? this.rewardGranted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'templateId': templateId,
        'title': title,
        'description': description,
        'category': category.name,
        'action': action.name,
        'bucksReward': bucksReward,
        'xpReward': xpReward,
        'date': date,
        'isCompleted': isCompleted,
        'rewardGranted': rewardGranted,
      };

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
        id: json['id'] as String,
        templateId: json['templateId'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: MissionCategory.values.byName(json['category'] as String),
        action: MissionAction.values.byName(json['action'] as String),
        bucksReward: json['bucksReward'] as int,
        xpReward: json['xpReward'] as int,
        date: json['date'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
        rewardGranted: json['rewardGranted'] as bool? ?? false,
      );
}
