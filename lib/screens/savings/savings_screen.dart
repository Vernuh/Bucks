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

  // Sample monthly data for the Savings Progress and Savings vs Expenses
  // graphs. TODO: replace with real Provider/Supabase data — build a
  // List<_MonthlyFinance> from transactions and pass it in the same way.
  static const List<_MonthlyFinance> _monthlyFinance = [
    _MonthlyFinance(month: 'May', savings: 4000, expenses: 3000),
    _MonthlyFinance(month: 'Jun', savings: 6500, expenses: 3500),
    _MonthlyFinance(month: 'Jul', savings: 9000, expenses: 4000),
    _MonthlyFinance(month: 'Aug', savings: 11500, expenses: 4500),
    _MonthlyFinance(month: 'Sep', savings: 15000, expenses: 5000),
  ];

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SavingsProgressCard(
                  data: _monthlyFinance,
                  blue: _blue,
                  darkNavy: _darkNavy,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SavingsVsExpensesCard(
                  data: _monthlyFinance,
                  blue: _blue,
                  yellow: _yellow,
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

/// One month of sample finance data. Swap the sample list in
/// [_SavingsScreenState._monthlyFinance] for real data later.
class _MonthlyFinance {
  final String month;
  final double savings;
  final double expenses;

  const _MonthlyFinance({
    required this.month,
    required this.savings,
    required this.expenses,
  });
}

const Color _chartGrid = Color(0xFFE6E1D3);
const Color _chartCardBg = Color(0xFFFFFBF2);
const Color _expenseGreen = Color(0xFF2ECC71);

/// Formats a value compactly with the peso sign, e.g. 6500 -> "₱6.5k".
String _pesoK(double v) {
  final k = v / 1000;
  final text = k == k.roundToDouble()
      ? k.toStringAsFixed(0)
      : k.toStringAsFixed(1);
  return '\u20b1${text}k';
}

/// Full peso format with thousands separators, e.g. 15000 -> "₱15,000".
String _pesoFull(double v) {
  final digits = v.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '\u20b1$buf';
}

/// Rounds [maxValue] up to a tidy axis top (multiple of 4 steps of 1k+).
double _niceMax(double maxValue) {
  const step = 4000.0;
  return ((maxValue / step).ceil().clamp(1, 1000)) * step;
}

void _paintText(
  Canvas canvas,
  String text,
  Offset anchor, {
  required Color color,
  double fontSize = 10,
  FontWeight weight = FontWeight.normal,
  // alignX: 0 = anchor is left edge, 0.5 = centered, 1 = right edge.
  double alignX = 0.5,
  // alignY: 0 = anchor is top edge, 0.5 = centered, 1 = bottom edge.
  double alignY = 0.5,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  tp.paint(
    canvas,
    Offset(anchor.dx - tp.width * alignX, anchor.dy - tp.height * alignY),
  );
}

/// Shared rounded card with title + description around a chart.
class _ChartCard extends StatelessWidget {
  final String title;
  final String description;
  final Color darkNavy;
  final Widget child;
  final Widget? legend;

  const _ChartCard({
    required this.title,
    required this.description,
    required this.darkNavy,
    required this.child,
    this.legend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: _chartCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _chartGrid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: darkNavy,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: darkNavy.withAlpha(180),
            ),
          ),
          if (legend != null) ...[const SizedBox(height: 10), legend!],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Graph 2: line chart of savings over time.
class _SavingsProgressCard extends StatelessWidget {
  final List<_MonthlyFinance> data;
  final Color blue;
  final Color darkNavy;

  const _SavingsProgressCard({
    required this.data,
    required this.blue,
    required this.darkNavy,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'Savings Progress',
      description: 'Track how your savings grow over time.',
      darkNavy: darkNavy,
      child: SizedBox(
        width: double.infinity,
        height: 170,
        child: CustomPaint(
          painter: _SavingsLinePainter(
            data: data,
            blue: blue,
            darkNavy: darkNavy,
          ),
        ),
      ),
    );
  }
}

class _SavingsLinePainter extends CustomPainter {
  final List<_MonthlyFinance> data;
  final Color blue;
  final Color darkNavy;

  _SavingsLinePainter({
    required this.data,
    required this.blue,
    required this.darkNavy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const leftPad = 40.0;
    const rightPad = 14.0;
    const topPad = 14.0;
    const bottomPad = 22.0;

    final plot = Rect.fromLTRB(
      leftPad,
      topPad,
      size.width - rightPad,
      size.height - bottomPad,
    );
    final maxValue = _niceMax(
      data.map((d) => d.savings).reduce((a, b) => a > b ? a : b),
    );

    final gridPaint = Paint()
      ..color = _chartGrid
      ..strokeWidth = 1;

    // Horizontal grid lines + y-axis labels (0 .. max in 4 steps).
    for (var i = 0; i <= 4; i++) {
      final y = plot.bottom - plot.height * i / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      _paintText(
        canvas,
        _pesoK(maxValue * i / 4),
        Offset(plot.left - 6, y),
        color: blue,
        fontSize: 10,
        alignX: 1,
      );
    }

    // Point positions (inset half a slot so end points aren't clipped).
    final slot = plot.width / data.length;
    final points = <Offset>[
      for (var i = 0; i < data.length; i++)
        Offset(
          plot.left + slot * (i + 0.5),
          plot.bottom - plot.height * (data[i].savings / maxValue),
        ),
    ];

    // Soft fill under the line.
    final fill = Path()..moveTo(points.first.dx, plot.bottom);
    for (final p in points) {
      fill.lineTo(p.dx, p.dy);
    }
    fill
      ..lineTo(points.last.dx, plot.bottom)
      ..close();
    canvas.drawPath(fill, Paint()..color = blue.withAlpha(26));

    // The line.
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Visible points + month labels.
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(points[i], 4, Paint()..color = blue);
      _paintText(
        canvas,
        data[i].month,
        Offset(points[i].dx, plot.bottom + 6),
        color: darkNavy,
        fontSize: 10,
        alignY: 0,
      );
    }

    // Value label on the latest point only, keeping the chart uncluttered.
    final last = points.last;
    _paintText(
      canvas,
      _pesoFull(data.last.savings),
      Offset(last.dx + 4, last.dy - 9),
      color: darkNavy,
      fontSize: 10,
      weight: FontWeight.bold,
      alignX: 1,
    );
  }

  @override
  bool shouldRepaint(covariant _SavingsLinePainter old) =>
      old.data != data || old.blue != blue || old.darkNavy != darkNavy;
}

/// Graph 3: grouped bars (savings vs expenses) per month.
class _SavingsVsExpensesCard extends StatelessWidget {
  final List<_MonthlyFinance> data;
  final Color blue;
  final Color yellow;
  final Color darkNavy;

  const _SavingsVsExpensesCard({
    required this.data,
    required this.blue,
    required this.yellow,
    required this.darkNavy,
  });

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: darkNavy, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'Savings vs Expenses',
      description: 'See how much you save compared with what you spend.',
      darkNavy: darkNavy,
      legend: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          _legendItem('Savings', blue),
          _legendItem('Expenses', _expenseGreen),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 190,
        child: CustomPaint(
          painter: _GroupedBarPainter(
            data: data,
            savingsColor: blue,
            expensesColor: _expenseGreen,
            labelColor: darkNavy,
          ),
        ),
      ),
    );
  }
}

class _GroupedBarPainter extends CustomPainter {
  final List<_MonthlyFinance> data;
  final Color savingsColor;
  final Color expensesColor;
  final Color labelColor;

  _GroupedBarPainter({
    required this.data,
    required this.savingsColor,
    required this.expensesColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const leftPad = 40.0;
    const rightPad = 6.0;
    const topPad = 16.0;
    const bottomPad = 22.0;

    final plot = Rect.fromLTRB(
      leftPad,
      topPad,
      size.width - rightPad,
      size.height - bottomPad,
    );
    final maxValue = _niceMax(
      data
          .map((d) => d.savings > d.expenses ? d.savings : d.expenses)
          .reduce((a, b) => a > b ? a : b),
    );

    final gridPaint = Paint()
      ..color = _chartGrid
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = plot.bottom - plot.height * i / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      _paintText(
        canvas,
        _pesoK(maxValue * i / 4),
        Offset(plot.left - 6, y),
        color: savingsColor,
        fontSize: 10,
        alignX: 1,
      );
    }

    final slot = plot.width / data.length;
    // Bars scale with the slot width so they always fit small screens.
    final barWidth = (slot * 0.34).clamp(8.0, 24.0);
    const barGap = 2.0;

    void drawBar(double centerX, double value, Color color) {
      final h = plot.height * (value / maxValue);
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(centerX - barWidth / 2, plot.bottom - h, barWidth, h),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = color);
      _paintText(
        canvas,
        _pesoK(value),
        Offset(centerX, plot.bottom - h - 2),
        color: labelColor,
        fontSize: 8,
        weight: FontWeight.w600,
        alignY: 1,
      );
    }

    for (var i = 0; i < data.length; i++) {
      final cx = plot.left + slot * (i + 0.5);
      final offset = (barWidth + barGap) / 2;
      drawBar(cx - offset, data[i].savings, savingsColor);
      drawBar(cx + offset, data[i].expenses, expensesColor);
      _paintText(
        canvas,
        data[i].month,
        Offset(cx, plot.bottom + 6),
        color: labelColor,
        fontSize: 10,
        alignY: 0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GroupedBarPainter old) =>
      old.data != data ||
      old.savingsColor != savingsColor ||
      old.expensesColor != expensesColor ||
      old.labelColor != labelColor;
}
