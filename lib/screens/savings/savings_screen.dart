import 'package:flutter/material.dart';
import '../../app/routes.dart';

/// The "Goals" bottom-nav tab.
///
/// The class is still named [SavingsScreen] because `main_shell.dart`
/// references it directly by that name, and that file is off-limits
/// to modify here — but this now implements the full Goals dashboard:
/// Bucks message, savings goal card(s), Create Goal, Budget Planner,
/// and a Reports chart.
///
/// Goal data is local/in-memory (a `List<_GoalData>` in this State) —
/// there's no AppStateProvider field for goals and no storage backend
/// yet, so this is sample data until that's wired up.
class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  static const _blue = Color(0xFF1688F5);
  static const _darkNavy = Color(0xFF17213F);
  static const _yellow = Color(0xFFFFD21F);
  static const _green = Color(0xFF218B0D);

  final List<_GoalData> _goals = [
    _GoalData(name: 'Laptop', saved: 15000, target: 25000),
  ];

  // Sample report data — not wired to real transactions yet.
  static const List<double> _reportValues = [1000, 2000, 2800, 3300, 2488];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _GoalsHeader(blue: _blue, yellow: _yellow),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _BucksGoalSection(),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: _goals
                      .map(
                        (goal) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SavingsGoalCard(
                            goal: goal,
                            blue: _blue,
                            darkNavy: _darkNavy,
                            yellow: _yellow,
                            green: _green,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 20),
                  child: _CreateGoalButton(
                    yellow: _yellow,
                    darkNavy: _darkNavy,
                    onCreate: _addGoal,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _BudgetPlannerButton(
                  blue: _blue,
                  yellow: _yellow,
                  darkNavy: _darkNavy,
                  onTap: () => Navigator.pushNamed(context, Routes.budget),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Reports and Charts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _darkNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ReportsChart(
                  values: _reportValues,
                  blue: _blue,
                  darkNavy: _darkNavy,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _addGoal(String name, double target) {
    setState(() {
      _goals.add(_GoalData(name: name, saved: 0, target: target));
    });
  }
}

/// Data for a single savings goal. `progress` is always calculated
/// (saved / target, clamped 0.0–1.0) rather than stored directly.
class _GoalData {
  final String name;
  final double saved;
  final double target;

  _GoalData({required this.name, required this.saved, required this.target});

  double get progress => target <= 0 ? 0 : (saved / target).clamp(0.0, 1.0);
}

/// Bright blue header: "BUCKS" (gold, left), a white "Buck's Insights"
/// pill (right), and a thin yellow progress line along the bottom.
class _GoalsHeader extends StatelessWidget {
  final Color blue;
  final Color yellow;

  const _GoalsHeader({required this.blue, required this.yellow});

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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  "Buck's Insights",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.6, // placeholder — no real level/XP data yet
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

/// Bucks icon on a green ground shadow (left) + the goal-progress
/// message (right). Reuses the same Icons.emoji_nature placeholder
/// used on the other tabs, without touching BucksCompanion's file.
class _BucksGoalSection extends StatelessWidget {
  const _BucksGoalSection();

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
            "Bawk! Great progress!\nYou're one step closer to\nyour savings goal!",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF17213F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Blue savings goal card: name + percentage, saved/target amount,
/// and a yellow-on-green progress bar.
class _SavingsGoalCard extends StatelessWidget {
  final _GoalData goal;
  final Color blue;
  final Color darkNavy;
  final Color yellow;
  final Color green;

  const _SavingsGoalCard({
    required this.goal,
    required this.blue,
    required this.darkNavy,
    required this.yellow,
    required this.green,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (goal.progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: blue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  goal.name,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: darkNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: darkNavy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '\u20b1${goal.saved.toStringAsFixed(0)} / \u20b1${goal.target.toStringAsFixed(0)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: darkNavy),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 10,
              backgroundColor: green,
              valueColor: AlwaysStoppedAnimation<Color>(yellow),
            ),
          ),
        ],
      ),
    );
  }
}

/// Yellow pill button that opens a dialog for creating a new goal.
/// Validates the name (non-empty) and target amount (a positive
/// number) before calling [onCreate].
class _CreateGoalButton extends StatelessWidget {
  final Color yellow;
  final Color darkNavy;
  final void Function(String name, double target) onCreate;

  const _CreateGoalButton({
    required this.yellow,
    required this.darkNavy,
    required this.onCreate,
  });

  Future<void> _openDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Goal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Goal Name'),
                  TextField(controller: nameController),
                  const SizedBox(height: 12),
                  const Text('Target Amount'),
                  TextField(
                    controller: targetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(errorText!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final target = double.tryParse(
                      targetController.text.trim(),
                    );

                    if (name.isEmpty) {
                      setDialogState(() => errorText = 'Enter a goal name.');
                      return;
                    }
                    if (target == null || target <= 0) {
                      setDialogState(
                        () => errorText = 'Enter a valid target amount.',
                      );
                      return;
                    }

                    onCreate(name, target);
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Create Goal'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      targetController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: yellow,
      borderRadius: BorderRadius.circular(100),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () => _openDialog(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Text(
            'Create Goal',
            style: TextStyle(color: darkNavy, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

/// Large blue rounded button leading to the Budget Planner.
class _BudgetPlannerButton extends StatelessWidget {
  final Color blue;
  final Color yellow;
  final Color darkNavy;
  final VoidCallback onTap;

  const _BudgetPlannerButton({
    required this.blue,
    required this.yellow,
    required this.darkNavy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: blue,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Planner',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.calculate, color: darkNavy, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

/// A simple bar chart built with plain Flutter widgets (no chart
/// package/dependency). Shows [values] as vertical bars against a
/// fixed $0–$4k axis on the left; the last bar is highlighted in a
/// darker color with its value labeled above it.
class _ReportsChart extends StatelessWidget {
  final List<double> values;
  final Color blue;
  final Color darkNavy;

  const _ReportsChart({
    required this.values,
    required this.blue,
    required this.darkNavy,
  });

  static const double _chartHeight = 140;
  static const double _maxValue = 4000; // matches the $4k axis top

  @override
  Widget build(BuildContext context) {
    final lastIndex = values.length - 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _chartHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$4k', style: TextStyle(color: blue, fontSize: 11)),
              Text('\$3k', style: TextStyle(color: blue, fontSize: 11)),
              Text('\$2k', style: TextStyle(color: blue, fontSize: 11)),
              Text('\$1k', style: TextStyle(color: blue, fontSize: 11)),
              Text('\$0', style: TextStyle(color: blue, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: _chartHeight,
            // stretch so each bar's Stack gets a real bounded height —
            // without this, FractionallySizedBox below has nothing to
            // size itself relative to.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(values.length, (index) {
                final isLast = index == lastIndex;
                final heightFactor = (values[index] / _maxValue).clamp(
                  0.0,
                  1.0,
                );

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: heightFactor,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isLast ? darkNavy : blue,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isLast)
                          Positioned(
                            top: (_chartHeight * (1 - heightFactor) - 22).clamp(
                              0,
                              _chartHeight,
                            ),
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '\$${values[index].toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
