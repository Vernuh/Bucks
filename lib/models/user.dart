/// The app user's profile and progression. There is exactly one Bucks Coins
/// balance ([buckCoins]) and one XP value ([xp]) in the whole app, and they
/// live here. Level is DERIVED from [xp] by AppStateProvider.
///
/// Auth is still a placeholder, so no password is ever stored.
class User {
  final String id;
  final String username;
  final String email;
  final int buckCoins;
  final int xp;
  final int currentStreak;

  /// "yyyy-MM-dd" of the last day the user was active, or null.
  final String? lastActivityDate;

  User({
    required this.id,
    required this.username,
    this.email = '',
    this.buckCoins = 0,
    this.xp = 0,
    this.currentStreak = 0,
    this.lastActivityDate,
  });

  User copyWith({
    String? username,
    String? email,
    int? buckCoins,
    int? xp,
    int? currentStreak,
    String? lastActivityDate,
  }) =>
      User(
        id: id,
        username: username ?? this.username,
        email: email ?? this.email,
        buckCoins: buckCoins ?? this.buckCoins,
        xp: xp ?? this.xp,
        currentStreak: currentStreak ?? this.currentStreak,
        lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'buckCoins': buckCoins,
        'xp': xp,
        'currentStreak': currentStreak,
        'lastActivityDate': lastActivityDate,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        username: json['username'] as String,
        email: json['email'] as String? ?? '',
        buckCoins: json['buckCoins'] as int? ?? 0,
        xp: json['xp'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        lastActivityDate: json['lastActivityDate'] as String?,
      );
}
