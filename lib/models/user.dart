/// Represents the app user. Fields are intentionally minimal for now —
/// we'll expand this once auth/backend is implemented.
class User {
  final String id;
  final String username;
  final String email;
  final int buckPoints;
  final int currentStreak;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.buckPoints = 0,
    this.currentStreak = 0,
  });
}
