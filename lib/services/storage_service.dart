import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';

/// This service will be the single place the app goes to read/write
/// data (transactions, budgets, savings goals, etc.).
///
/// Right now it does nothing — it's a placeholder so the rest of the
/// app can be written against a stable interface. When we build each
/// feature (Transactions, Budget, Savings), we'll fill these methods in
/// with in-memory mock data first, then swap to real persistence
/// (e.g. SharedPreferences or a backend) later without changing any
/// screen code.
class StorageService {
  Future<List<Transaction>> getTransactions() async {
    // TODO: return mock transactions once we build the Transactions screen.
    return [];
  }

  Future<List<Budget>> getBudgets() async {
    // TODO: return mock budgets once we build the Budget Planner.
    return [];
  }

  Future<List<SavingsGoal>> getSavingsGoals() async {
    // TODO: return mock savings goals once we build the Savings screen.
    return [];
  }
}
