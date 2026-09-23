import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/transactions/add_transaction_screen.dart';
import '../screens/budget/budget_screen.dart';
import '../screens/savings/savings_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/missions/missions_screen.dart';
import '../screens/bucksboard/bucksboard_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';

/// All named routes for BUCKS live here. Keeping them as constants
/// avoids typos when navigating (e.g. `Navigator.pushNamed(context, Routes.home)`).
class Routes {
  Routes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String transactions = '/transactions';
  static const String addTransaction = '/add-transaction';
  static const String budget = '/budget';
  static const String savings = '/savings';
  static const String reports = '/reports';
  static const String missions = '/missions';
  static const String bucksboard = '/bucksboard';
  static const String profile = '/profile';
  static const String settings = '/settings';

  /// Maps every route name to the screen that should be shown.
  static Map<String, WidgetBuilder> get all => {
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
        home: (_) => const HomeScreen(),
        transactions: (_) => const TransactionsScreen(),
        addTransaction: (_) => const AddTransactionScreen(),
        budget: (_) => const BudgetScreen(),
        savings: (_) => const SavingsScreen(),
        reports: (_) => const ReportsScreen(),
        missions: (_) => const MissionsScreen(),
        bucksboard: (_) => const BucksboardScreen(),
        profile: (_) => const ProfileScreen(),
        settings: (_) => const SettingsScreen(),
      };
}
