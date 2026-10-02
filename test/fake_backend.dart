import 'package:bucks/models/user.dart';
import 'package:bucks/services/bucks_backend.dart';

/// In-memory stand-in for Supabase, used only by tests. Data is keyed by
/// user id, like RLS keys rows by auth.uid().
class FakeBackend implements BucksBackend {
  final Map<String, StoredData> _db = {};
  final Map<String, ({String password, String id, String username})> _accounts =
      {};
  String? _current;
  String? _currentEmail;
  int _n = 0;
  bool failSaves = false;

  @override
  String? get currentUserId => _current;
  @override
  String? get currentEmail => _currentEmail;

  @override
  Future<AuthOutcome> signUp(
      {required String email,
      required String password,
      required String username}) async {
    if (_accounts.containsKey(email)) {
      throw const BackendException('User already registered');
    }
    final id = 'uuid-${_n++}';
    _accounts[email] = (password: password, id: id, username: username);
    _current = id;
    _currentEmail = email;
    return AuthOutcome(userId: id, email: email);
  }

  @override
  Future<AuthOutcome> signIn(
      {required String email, required String password}) async {
    final a = _accounts[email];
    if (a == null || a.password != password) {
      throw const BackendException('Invalid login credentials');
    }
    _current = a.id;
    _currentEmail = email;
    return AuthOutcome(userId: a.id, email: email);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _currentEmail = null;
  }

  @override
  Future<StoredData> loadUserData(String userId) async {
    final saved = _db[userId];
    if (saved != null) return saved;
    final acct = _accounts.values.firstWhere((a) => a.id == userId);
    return StoredData(
        user: User(id: userId, username: acct.username, email: _currentEmail ?? ''));
  }

  @override
  Future<void> saveUserData(String userId, StoredData data) async {
    if (failSaves) throw const BackendException('offline');
    _db[userId] = data;
  }

  @override
  Future<void> deleteUserData(String userId) async => _db.remove(userId);

  StoredData? rowsFor(String userId) => _db[userId];
}
