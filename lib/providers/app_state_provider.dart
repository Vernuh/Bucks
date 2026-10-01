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
  // Starts at 250 to match the sample balance the Bucks screen already
  // displayed. TODO: load/persist via StorageService once it's implemented.
  int _buckPoints = 250;

  // Customization state. Item ids are plain strings (see
  // customize_bucks_screen.dart). TODO: persist via StorageService later.
  final Set<String> _unlockedItems = {};
  // category -> equipped item id (only one per category).
  final Map<String, String> _equippedItems = {};

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

  bool isCustomizationUnlocked(String itemId) =>
      _unlockedItems.contains(itemId);

  bool isCustomizationEquipped(String category, String itemId) =>
      _equippedItems[category] == itemId;

  /// Buys an item. Returns false (and changes nothing) if the item is
  /// already unlocked or the balance is too low.
  bool purchaseCustomizationItem(String itemId, int cost) {
    if (_unlockedItems.contains(itemId) || _buckPoints < cost) return false;
    _buckPoints -= cost;
    _unlockedItems.add(itemId);
    notifyListeners();
    return true;
  }

  /// Equips an unlocked item, replacing whatever was equipped in the
  /// same category.
  bool equipCustomizationItem(String category, String itemId) {
    if (!_unlockedItems.contains(itemId)) return false;
    _equippedItems[category] = itemId;
    notifyListeners();
    return true;
  }
}
