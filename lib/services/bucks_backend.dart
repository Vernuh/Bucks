import '../models/budget.dart';
import '../models/mission.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../models/upcoming_item.dart';
import '../models/user.dart';

/// Everything BUCKS keeps for one signed-in user, as a plain snapshot.
/// AppStateProvider hands this to the backend to save and receives it back
/// when loading. It is never stored locally; Supabase is the only
/// persistent source of truth.
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

/// Result of a sign-up / sign-in call.
class AuthOutcome {
  /// auth.users.id of the signed-in user, or null if no session was created
  /// (for example when the project requires email confirmation).
  final String? userId;
  final String? email;
  final bool needsEmailConfirmation;

  const AuthOutcome({
    this.userId,
    this.email,
    this.needsEmailConfirmation = false,
  });
}

/// A readable error for the UI (wrong password, network down, ...).
class BackendException implements Exception {
  final String message;
  const BackendException(this.message);

  @override
  String toString() => message;
}

/// What AppStateProvider needs from the backend. [SupabaseService] is the
/// real implementation; tests use an in-memory fake.
abstract class BucksBackend {
  /// UUID of the restored/active auth session, or null if signed out.
  String? get currentUserId;
  String? get currentEmail;

  Future<AuthOutcome> signUp({
    required String email,
    required String password,
    required String username,
  });

  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Loads (creating the profile / stats rows if missing) the user's data.
  Future<StoredData> loadUserData(String userId);

  /// Writes whatever changed since the last successful load/save.
  /// Throws if anything could not be written; the next call retries.
  Future<void> saveUserData(String userId, StoredData data);

  /// Deletes the user's BUCKS data (not the account) and resets stats.
  Future<void> deleteUserData(String userId);
}
