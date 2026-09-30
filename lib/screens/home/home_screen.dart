import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../providers/app_state_provider.dart';

/// The Home dashboard tab: blue header, Bucks + today's budget message,
/// balance/spent cards, Daily Missions, and Upcoming items.
///
/// This replaces the old placeholder (AppBar + "Go to:" grid). None of
/// this data is wired to real storage yet — balance, spent, missions,
/// and upcoming items are all local sample data for now, per the
/// project's "use sample data until a backend exists" rule. The one
/// piece of real data available is the username from [AppStateProvider],
/// used in the greeting message.
///
/// Note on Bucks' character: we're not embedding the [BucksCompanion]
/// widget directly here, since its Row + speech-bubble-card layout
/// doesn't match this screen's side-by-side plain-text + ground-shadow
/// look. Instead we reuse the same icon it uses to represent Bucks
/// (Icons.emoji_nature) so the visual language stays consistent,
/// without modifying that widget's file.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Colors from the reference design.
  static const _blue = Color(0xFF1688F5);
  static const _yellow = Color(0xFFFFD21F);
  static const _dateGreen = Color(0xFF218B0D);
  static const _lightYellow = Color(0xFFFFF9A8);
  static const _darkText = Color(0xFF222222);
  static const _gray = Color(0xFF777777);
  static const _expenseRed = Color(0xFFF44336);
  static const _incomeGreen = Color(0xFF168B2D);

  // Sample data — will be replaced once budgets/missions/upcoming are
  // wired to real storage.
  static const int _todaysBalance = 200;
  static const int _spentToday = 150;
  static const int _budgetRemaining = 200;

  final List<_MissionData> _missions = const [
    _MissionData(
      title: 'Log an Expense',
      description: 'Record 1 expense today.',
      coinReward: 10,
      xpReward: 20,
    ),
    _MissionData(
      title: 'Stay on Budget',
      description: "Don't exceed your budget today.",
      coinReward: 15,
      xpReward: 30,
    ),
    _MissionData(
      title: 'Save Money',
      description: 'Add any amount to a savings goal.',
      coinReward: 15,
      xpReward: 35,
    ),
  ];

  // Tracks which missions are checked. Purely local/visual for now —
  // not persisted anywhere.
  late final List<bool> _missionCompleted = List<bool>.filled(
    _missions.length,
    false,
  );

  static const List<_UpcomingItemData> _upcoming = [
    _UpcomingItemData(
      name: 'Weekly Allowance',
      date: 'August 10',
      amount: 5000,
      isExpense: false,
    ),
    _UpcomingItemData(
      name: 'Mobile Load',
      date: 'August 11',
      amount: 300,
      isExpense: false,
    ),
    _UpcomingItemData(
      name: 'Netflix Subscription',
      date: 'August 15',
      amount: 249,
      isExpense: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HomeHeader(blue: _blue, yellow: _yellow),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _BucksDashboardSection(
                  username: appState.username,
                  budgetRemaining: _budgetRemaining,
                  darkText: _darkText,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _formatDashboardDate(DateTime.now()),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _dateGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, Routes.transactions),
                  child: _BalanceCard(
                    label: "Today's Balance",
                    amount: _todaysBalance,
                    blue: _blue,
                    yellow: _yellow,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, Routes.transactions),
                  child: _BalanceCard(
                    label: 'Spent Today',
                    amount: _spentToday,
                    blue: _blue,
                    yellow: _yellow,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _DailyMissionsSection(
                missions: _missions,
                completed: _missionCompleted,
                yellow: _yellow,
                blue: _blue,
                darkText: _darkText,
                gray: _gray,
                onHeaderTap: () =>
                    Navigator.pushNamed(context, Routes.missions),
                onToggle: (index) {
                  setState(
                    () => _missionCompleted[index] = !_missionCompleted[index],
                  );
                },
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _UpcomingSection(
                  items: _upcoming,
                  lightYellow: _lightYellow,
                  blue: _blue,
                  gray: _gray,
                  darkText: _darkText,
                  incomeGreen: _incomeGreen,
                  expenseRed: _expenseRed,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text('Add Upcoming coming soon!'),
                        ),
                      );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _yellow,
                    foregroundColor: _dateGreen,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Add Upcoming',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Formats a date like "Monday, July 24, 2026" without adding a new
// dependency (no intl package).
String _formatDashboardDate(DateTime date) {
  const weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final weekday = weekdayNames[date.weekday - 1];
  final month = monthNames[date.month - 1];
  return '$weekday, $month ${date.day}, ${date.year}';
}

/// Bright blue header: "BUCKS" logotype on the left, "Level 17" on the
/// right, with a thin yellow progress bar along the bottom edge.
class _HomeHeader extends StatelessWidget {
  final Color blue;
  final Color yellow;

  const _HomeHeader({required this.blue, required this.yellow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      color: blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'BUCKS',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Level 17',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.6, // placeholder — no real XP/level data yet
              minHeight: 4,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(yellow),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bucks (left) + today's budget message (right), with a green ground
/// shadow under the character.
class _BucksDashboardSection extends StatelessWidget {
  final String username;
  final int budgetRemaining;
  final Color darkText;

  const _BucksDashboardSection({
    required this.username,
    required this.budgetRemaining,
    required this.darkText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 64,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF218B0D),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Icon(
                Icons.emoji_nature,
                size: 56,
                color: Color(0xFF8D5A2B),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            "Bawk! You're doing great, $username! Only "
            '\u20b1$budgetRemaining left in today\'s budget.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: darkText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Blue rounded card used for both "Today's Balance" and "Spent Today":
/// a section label above, "Php" on the left and the amount on the
/// right, both in gold.
class _BalanceCard extends StatelessWidget {
  final String label;
  final int amount;
  final Color blue;
  final Color yellow;

  const _BalanceCard({
    required this.label,
    required this.amount,
    required this.blue,
    required this.yellow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: blue,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: blue,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Php',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$amount',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Data for a single daily mission. Local sample data only for now.
class _MissionData {
  final String title;
  final String description;
  final int coinReward;
  final int xpReward;

  const _MissionData({
    required this.title,
    required this.description,
    required this.coinReward,
    required this.xpReward,
  });
}

/// Yellow-headed "Daily Missions" section containing three mission
/// rows. Tapping the header navigates to the full Missions screen;
/// tapping a mission's checkbox toggles it locally (not persisted).
class _DailyMissionsSection extends StatelessWidget {
  final List<_MissionData> missions;
  final List<bool> completed;
  final Color yellow;
  final Color blue;
  final Color darkText;
  final Color gray;
  final VoidCallback onHeaderTap;
  final ValueChanged<int> onToggle;

  const _DailyMissionsSection({
    required this.missions,
    required this.completed,
    required this.yellow,
    required this.blue,
    required this.darkText,
    required this.gray,
    required this.onHeaderTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: yellow,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onHeaderTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Text(
                'Daily Missions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF17213F),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(missions.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == missions.length - 1 ? 0 : 10,
                  ),
                  child: _MissionCard(
                    mission: missions[index],
                    isCompleted: completed[index],
                    blue: blue,
                    darkText: darkText,
                    gray: gray,
                    onTap: () => onToggle(index),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single white rounded mission row: checkbox, title + description,
/// and a blue rewards pill.
class _MissionCard extends StatelessWidget {
  final _MissionData mission;
  final bool isCompleted;
  final Color blue;
  final Color darkText;
  final Color gray;
  final VoidCallback onTap;

  const _MissionCard({
    required this.mission,
    required this.isCompleted,
    required this.blue,
    required this.darkText,
    required this.gray,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isCompleted ? blue : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: darkText,
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  mission.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: gray),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: blue,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on,
                  size: 14,
                  color: Color(0xFFFFD21F),
                ),
                const SizedBox(width: 2),
                Text(
                  '+${mission.coinReward}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.bolt, size: 14, color: Color(0xFFFFA726)),
                const SizedBox(width: 2),
                Text(
                  '+${mission.xpReward}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Data for a single upcoming income/expense item.
class _UpcomingItemData {
  final String name;
  final String date;
  final int amount;
  final bool isExpense;

  const _UpcomingItemData({
    required this.name,
    required this.date,
    required this.amount,
    required this.isExpense,
  });
}

/// Pale-yellow "Upcoming" container listing upcoming income/expense
/// items. Tapping an item shows a snackbar for now — no dedicated
/// screen exists yet.
class _UpcomingSection extends StatelessWidget {
  final List<_UpcomingItemData> items;
  final Color lightYellow;
  final Color blue;
  final Color gray;
  final Color darkText;
  final Color incomeGreen;
  final Color expenseRed;

  const _UpcomingSection({
    required this.items,
    required this.lightYellow,
    required this.blue,
    required this.gray,
    required this.darkText,
    required this.incomeGreen,
    required this.expenseRed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightYellow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map((item) {
            final color = item.isExpense ? expenseRed : incomeGreen;
            final sign = item.isExpense ? '-' : '+';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text('${item.name} — coming soon!')),
                    );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: darkText,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              item.date,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: gray),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$sign${item.amount}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
