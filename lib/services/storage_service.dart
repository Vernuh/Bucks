import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/budget.dart';
import '../models/mission.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../models/upcoming_item.dart';
import '../models/user.dart';

/// Everything BUCKS persists, as one plain snapshot. AppStateProvider hands
/// this to [StorageService.save] and gets it back from [StorageService.load].
class StoredData {
  final User? user;
  final List<Transaction> transactions;
  final List<SavingsGoal> goals;
  final List<Budget> budgets;
  final List<UpcomingItem> upcoming;
  final List<Mission> missions;
  final Set<String> achievements;
  final Set<String> unlockedCustomization;

  /// category -> equipped item id.
  final Map<String, String> equippedCustomization;

  const StoredData({
    this.user,
    this.transactions = const [],
    this.goals = const [],
    this.budgets = const [],
    this.upcoming = const [],
    this.missions = const [],
    this.achievements = const {},
    this.unlockedCustomization = const {},
    this.equippedCustomization = const {},
  });
}

/// The single place the app reads/writes persistent data.
///
/// Today this is local (SharedPreferences). The rest of the app only talks
/// to this class's methods, so a Supabase-backed version can replace the
/// internals later without touching AppStateProvider or any screen.
///
/// NOTE: no passwords or credentials are ever stored here.
class StorageService {
  static const _prefix = 'bucks.v1.';
  static const _kUser = '${_prefix}user';
  static const _kTransactions = '${_prefix}transactions';
  static const _kGoals = '${_prefix}goals';
  static const _kBudgets = '${_prefix}budgets';
  static const _kUpcoming = '${_prefix}upcoming';
  static const _kMissions = '${_prefix}missions';
  static const _kAchievements = '${_prefix}achievements';
  static const _kUnlocked = '${_prefix}unlocked_customization';
  static const _kEquipped = '${_prefix}equipped_customization';

  static const _allKeys = [
    _kUser,
    _kTransactions,
    _kGoals,
    _kBudgets,
    _kUpcoming,
    _kMissions,
    _kAchievements,
    _kUnlocked,
    _kEquipped,
  ];

  /// Loads everything. A corrupted or missing entry falls back to empty
  /// for that entry only; it never throws and never wipes the others.
  Future<StoredData> load() async {
    final prefs = await SharedPreferences.getInstance();

    return StoredData(
      user: _decodeObject(prefs, _kUser, User.fromJson),
      transactions: _decodeList(prefs, _kTransactions, Transaction.fromJson),
      goals: _decodeList(prefs, _kGoals, SavingsGoal.fromJson),
      budgets: _decodeList(prefs, _kBudgets, Budget.fromJson),
      upcoming: _decodeList(prefs, _kUpcoming, UpcomingItem.fromJson),
      missions: _decodeList(prefs, _kMissions, Mission.fromJson),
      achievements: (prefs.getStringList(_kAchievements) ?? const []).toSet(),
      unlockedCustomization:
          (prefs.getStringList(_kUnlocked) ?? const []).toSet(),
      equippedCustomization: _decodeStringMap(prefs, _kEquipped),
    );
  }

  Future<void> save(StoredData data) async {
    final prefs = await SharedPreferences.getInstance();

    if (data.user != null) {
      await prefs.setString(_kUser, jsonEncode(data.user!.toJson()));
    }
    await prefs.setString(_kTransactions,
        jsonEncode(data.transactions.map((e) => e.toJson()).toList()));
    await prefs.setString(
        _kGoals, jsonEncode(data.goals.map((e) => e.toJson()).toList()));
    await prefs.setString(
        _kBudgets, jsonEncode(data.budgets.map((e) => e.toJson()).toList()));
    await prefs.setString(
        _kUpcoming, jsonEncode(data.upcoming.map((e) => e.toJson()).toList()));
    await prefs.setString(
        _kMissions, jsonEncode(data.missions.map((e) => e.toJson()).toList()));
    await prefs.setStringList(_kAchievements, data.achievements.toList());
    await prefs.setStringList(_kUnlocked, data.unlockedCustomization.toList());
    await prefs.setString(_kEquipped, jsonEncode(data.equippedCustomization));
  }

  /// Deletes only BUCKS' own keys.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _allKeys) {
      await prefs.remove(key);
    }
  }

  // --- helpers -----------------------------------------------------------

  T? _decodeObject<T>(
    SharedPreferences prefs,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('StorageService: could not read "$key": $e');
      return null;
    }
  }

  List<T> _decodeList<T>(
    SharedPreferences prefs,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = prefs.getString(key);
    if (raw == null) return <T>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('StorageService: could not read "$key": $e');
      return <T>[];
    }
  }

  Map<String, String> _decodeStringMap(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as String));
    } catch (e) {
      debugPrint('StorageService: could not read "$key": $e');
      return {};
    }
  }
}
