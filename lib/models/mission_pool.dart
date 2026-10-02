import 'mission.dart';

/// A predefined mission. The pool below is local and deterministic —
/// no AI is involved in choosing or completing missions.
class MissionTemplate {
  final String id;
  final String title;
  final String description;
  final MissionCategory category;
  final MissionAction action;
  final int bucksReward;
  final int xpReward;

  const MissionTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.action,
    required this.bucksReward,
    required this.xpReward,
  });
}

class MissionPool {
  MissionPool._();

  static const List<MissionTemplate> all = [
    // TRACKING
    MissionTemplate(
      id: 'log_expense',
      title: 'Log an Expense',
      description: 'Record 1 expense today.',
      category: MissionCategory.tracking,
      action: MissionAction.logExpense,
      bucksReward: 10,
      xpReward: 20,
    ),
    MissionTemplate(
      id: 'log_income',
      title: 'Log an Income',
      description: 'Record 1 income today.',
      category: MissionCategory.tracking,
      action: MissionAction.logIncome,
      bucksReward: 10,
      xpReward: 20,
    ),
    MissionTemplate(
      id: 'add_note',
      title: 'Add a Note to a Transaction',
      description: 'Save a transaction with a note.',
      category: MissionCategory.tracking,
      action: MissionAction.addNote,
      bucksReward: 10,
      xpReward: 20,
    ),
    // BUDGET
    MissionTemplate(
      id: 'stay_on_budget',
      title: 'Stay on Budget',
      description: "Log spending today without going over any budget.",
      category: MissionCategory.budget,
      action: MissionAction.stayOnBudget,
      bucksReward: 15,
      xpReward: 30,
    ),
    MissionTemplate(
      id: 'check_todays_budget',
      title: "Check Today's Budget",
      description: 'Open the Budget Planner.',
      category: MissionCategory.budget,
      action: MissionAction.openBudget,
      bucksReward: 10,
      xpReward: 20,
    ),
    MissionTemplate(
      id: 'review_budget',
      title: 'Review Your Budget',
      description: 'Open the Budget Planner and look it over.',
      category: MissionCategory.budget,
      action: MissionAction.openBudget,
      bucksReward: 10,
      xpReward: 20,
    ),
    // SAVINGS
    MissionTemplate(
      id: 'save_money',
      title: 'Save Money',
      description: 'Add any amount to a savings goal.',
      category: MissionCategory.savings,
      action: MissionAction.saveMoney,
      bucksReward: 15,
      xpReward: 35,
    ),
    MissionTemplate(
      id: 'add_to_goal',
      title: 'Add Money to a Savings Goal',
      description: 'Contribute to one of your goals.',
      category: MissionCategory.savings,
      action: MissionAction.saveMoney,
      bucksReward: 20,
      xpReward: 40,
    ),
    MissionTemplate(
      id: 'check_savings_goal',
      title: 'Check Your Savings Goal',
      description: 'Open the Goals tab.',
      category: MissionCategory.savings,
      action: MissionAction.openGoals,
      bucksReward: 10,
      xpReward: 20,
    ),
    // LEARNING
    MissionTemplate(
      id: 'view_reports',
      title: 'View Reports',
      description: 'Open Reports & Charts.',
      category: MissionCategory.learning,
      action: MissionAction.openReports,
      bucksReward: 10,
      xpReward: 20,
    ),
    MissionTemplate(
      id: 'review_spending',
      title: 'Review Spending',
      description: 'Open Reports & Charts and review your spending.',
      category: MissionCategory.learning,
      action: MissionAction.openReports,
      bucksReward: 10,
      xpReward: 20,
    ),
    MissionTemplate(
      id: 'check_categories',
      title: 'Check Your Spending Categories',
      description: 'Open Reports & Charts to see where money goes.',
      category: MissionCategory.learning,
      action: MissionAction.openReports,
      bucksReward: 10,
      xpReward: 20,
    ),
    // STREAK
    MissionTemplate(
      id: 'open_bucks',
      title: 'Open BUCKS Today',
      description: 'Start your day with BUCKS.',
      category: MissionCategory.streak,
      action: MissionAction.openApp,
      bucksReward: 5,
      xpReward: 10,
    ),
    MissionTemplate(
      id: 'one_activity',
      title: 'Complete One Financial Activity',
      description: 'Add a transaction, goal or budget.',
      category: MissionCategory.streak,
      action: MissionAction.anyActivity,
      bucksReward: 10,
      xpReward: 20,
    ),
    MissionTemplate(
      id: 'maintain_streak',
      title: 'Maintain Your Streak',
      description: 'Open BUCKS today to keep your streak going.',
      category: MissionCategory.streak,
      action: MissionAction.openApp,
      bucksReward: 10,
      xpReward: 20,
    ),
  ];
}
