import 'package:flutter/material.dart';

/// A small example provider so you can see how `provider` works before
/// we wire up real features (transactions, budgets, etc.).
///
/// How it works:
/// 1. This class extends [ChangeNotifier].
/// 2. Whenever a value changes, we call `notifyListeners()`.
/// 3. Any widget listening (via `context.watch<AppStateProvider>()`)
///    automatically rebuilds.
///
/// Later, we'll add more providers like `TransactionProvider`,
/// `BudgetProvider`, etc., following this same pattern.
class AppStateProvider extends ChangeNotifier {
  String _username = 'Student';
  int _buckPoints = 0;

  String get username => _username;
  int get buckPoints => _buckPoints;

  void setUsername(String name) {
    _username = name;
    notifyListeners();
  }

  void addPoints(int amount) {
    _buckPoints += amount;
    notifyListeners();
  }
}