import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/main_shell.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/budget/budget_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/missions/missions_screen.dart';
import '../screens/bucksboard/bucksboard_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/customize-bucks/customize_bucks_screen.dart';
import '../screens/achievements/achievements_screen.dart';
import '../screens/chat/chat_screen.dart';


/// All named routes for BUCKS live here. Keeping them as constants
/// avoids typos when navigating (e.g. `Navigator.pushNamed(context, Routes.transactions)`).
///
/// Note: Home, Bucks, Add, Goals (Savings), and Profile are no longer
/// separate named routes — they're tabs inside [MainShell], switched
/// with local state rather than the Navigator. Everything below is
/// either a pre-login screen or a screen reached by pushing on top of
/// the shell (e.g. tapping "Budget Planner" inside the Goals tab).
class Routes {
  Routes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String transactions = '/transactions';
  static const String budget = '/budget';
  static const String reports = '/reports';
  static const String missions = '/missions';
  static const String bucksboard = '/bucksboard';
  static const String achievements = '/achievements';
  static const String chat = '/chat';
  static const String customizeBucks = '/customize-bucks';
  static const String settings = '/settings';

  /// Maps every route name to the screen that should be shown.
  static Map<String, WidgetBuilder> get all => {
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
        main: (_) => const MainShell(),
        transactions: (_) => const TransactionsScreen(),
        budget: (_) => const BudgetScreen(),
        reports: (_) => const ReportsScreen(),
        missions: (_) => const MissionsScreen(),
        bucksboard: (_) => const BucksboardScreen(),
        customizeBucks: (_) => const CustomizeBucksScreen(),
        achievements: (_) => const AchievementsScreen(),
        chat: (_) => const ChatScreen(),
        settings: (_) => const SettingsScreen(),
      };
}
