import '../../widgets/bucks_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../models/mission.dart';
import '../../models/upcoming_item.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/formatters.dart';

/// The Home dashboard tab: blue header, Bucks + today's budget message,
/// balance/spent cards, Daily Missions, and Upcoming items.

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

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Tapping an upcoming item: record it as a real transaction, or remove.
  Future<void> _onUpcomingTap(BuildContext context, UpcomingItem item) async {
    final app = context.read<AppStateProvider>();
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item.name),
        content: Text(
          '${item.isExpense ? 'Expense' : 'Income'} of '
          '${formatPeso(item.amount)} on ${formatDate(item.date)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'remove'),
            child: const Text('Remove'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'done'),
            child: Text(item.isExpense ? 'Mark as paid' : 'Mark as received'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (choice == 'remove') {
      _toast(context, app.removeUpcoming(item.id).message);
    } else if (choice == 'done') {
      _toast(context, app.completeUpcoming(item.id).message);
    }
  }

  Future<void> _openAddUpcomingDialog(BuildContext context) async {
    final app = context.read<AppStateProvider>();
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    var isExpense = true;
    var date = DateTime.now();
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Upcoming'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Expense'),
                      selected: isExpense,
                      onSelected: (_) => setDialogState(() => isExpense = true),
                    ),
                    ChoiceChip(
                      label: const Text('Income'),
                      selected: !isExpense,
                      onSelected: (_) =>
                          setDialogState(() => isExpense = false),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\u20b1 ',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(formatDate(date)),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: date,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setDialogState(() => date = picked);
                  },
                ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final result = app.addUpcoming(
                  name: nameController.text,
                  amount: double.tryParse(amountController.text.trim()) ?? 0,
                  isExpense: isExpense,
                  date: date,
                );
                if (!result.success) {
                  setDialogState(() => error = result.message);
                  return;
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    amountController.dispose();
  }

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
              _HomeHeader(
                blue: _blue,
                yellow: _yellow,
                level: appState.level,
                progress: appState.levelProgress,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _BucksDashboardSection(
                  message: appState.bucksMessage,
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
                    amount: appState.availableBalance,
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
                    amount: appState.spentToday,
                    blue: _blue,
                    yellow: _yellow,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _DailyMissionsSection(
                missions: appState.missions,
                yellow: _yellow,
                blue: _blue,
                darkText: _darkText,
                gray: _gray,
                onHeaderTap: () =>
                    Navigator.pushNamed(context, Routes.missions),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _UpcomingSection(
                  items: appState.upcomingItems,
                  lightYellow: _lightYellow,
                  blue: _blue,
                  gray: _gray,
                  darkText: _darkText,
                  incomeGreen: _incomeGreen,
                  expenseRed: _expenseRed,
                  onItemTap: (item) => _onUpcomingTap(context, item),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => _openAddUpcomingDialog(context),
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

/// Bright blue header: "BUCKS" logotype on the left, the real level on the
/// right, with a thin yellow XP progress bar along the bottom edge.
class _HomeHeader extends StatelessWidget {
  final Color blue;
  final Color yellow;
  final int level;
  final double progress;

  const _HomeHeader({
    required this.blue,
    required this.yellow,
    required this.level,
    required this.progress,
  });

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
                'Level $level',
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
              value: progress,
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
  final String message;
  final Color darkText;

  const _BucksDashboardSection({
    required this.message,
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
              padding: EdgeInsets.only(bottom: 2),
              child: BucksAvatar(size: 110),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            message,
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
  final double amount;
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
                formatNumber(amount),
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

/// Yellow-headed "Daily Missions" section containing today's missions.
/// Tapping the header opens the full Missions screen. Missions complete
/// automatically when the user does the real action — the checkbox is
/// display-only so it can't be faked.
class _DailyMissionsSection extends StatelessWidget {
  final List<Mission> missions;
  final Color yellow;
  final Color blue;
  final Color darkText;
  final Color gray;
  final VoidCallback onHeaderTap;

  const _DailyMissionsSection({
    required this.missions,
    required this.yellow,
    required this.blue,
    required this.darkText,
    required this.gray,
    required this.onHeaderTap,
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
                    isCompleted: missions[index].isCompleted,
                    blue: blue,
                    darkText: darkText,
                    gray: gray,
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
  final Mission mission;
  final bool isCompleted;
  final Color blue;
  final Color darkText;
  final Color gray;

  const _MissionCard({
    required this.mission,
    required this.isCompleted,
    required this.blue,
    required this.darkText,
    required this.gray,
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
          Container(
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
                  '+${mission.bucksReward}',
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

/// Pale-yellow "Upcoming" container listing the user's upcoming
/// income/expense items. Tapping an item lets them mark it done (which
/// records a real transaction) or remove it.
class _UpcomingSection extends StatelessWidget {
  final List<UpcomingItem> items;
  final Color lightYellow;
  final Color blue;
  final Color gray;
  final Color darkText;
  final Color incomeGreen;
  final Color expenseRed;
  final ValueChanged<UpcomingItem> onItemTap;

  const _UpcomingSection({
    required this.items,
    required this.lightYellow,
    required this.blue,
    required this.gray,
    required this.darkText,
    required this.incomeGreen,
    required this.expenseRed,
    required this.onItemTap,
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
          if (items.isEmpty)
            Text(
              'Nothing upcoming yet. Tap "Add Upcoming" to plan ahead.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: gray,
              ),
            ),
          ...items.map((item) {
            final color = item.isExpense ? expenseRed : incomeGreen;
            final sign = item.isExpense ? '-' : '+';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onItemTap(item),
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
                              formatDate(item.date),
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: gray),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$sign${formatPeso(item.amount)}',
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
