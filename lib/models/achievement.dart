import 'package:flutter/material.dart';

/// Static definition of an achievement. Whether it is unlocked is user
/// state kept by AppStateProvider (a set of ids), not stored here.
/// Unlocking and its one-time reward happen together, so a reward can
/// never be granted twice.
class AchievementDef {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final int bucksReward;
  final int xpReward;

  const AchievementDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.bucksReward,
    required this.xpReward,
  });
}

class AchievementCatalog {
  AchievementCatalog._();

  static const List<AchievementDef> all = [
    AchievementDef(
      id: 'first_transaction',
      name: 'First Transaction',
      description: 'Log your first transaction.',
      icon: Icons.track_changes,
      bucksReward: 20,
      xpReward: 40,
    ),
    AchievementDef(
      id: 'first_goal',
      name: 'First Savings Goal',
      description: 'Create your first savings goal.',
      icon: Icons.flag,
      bucksReward: 20,
      xpReward: 40,
    ),
    AchievementDef(
      id: 'budget_beginner',
      name: 'Budget Beginner',
      description: 'Set your first budget.',
      icon: Icons.star,
      bucksReward: 20,
      xpReward: 40,
    ),
    AchievementDef(
      id: 'savings_starter',
      name: 'Savings Starter',
      description: 'Add money to a savings goal.',
      icon: Icons.savings,
      bucksReward: 25,
      xpReward: 50,
    ),
    AchievementDef(
      id: 'streak_7',
      name: '7-Day Streak',
      description: 'Use BUCKS 7 days in a row.',
      icon: Icons.local_fire_department,
      bucksReward: 50,
      xpReward: 100,
    ),
  ];

  static AchievementDef? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}
