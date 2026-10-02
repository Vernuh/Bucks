/// One month of derived chart data (never stored).
class MonthlySummary {
  final String month; // "May"
  final double income;
  final double expenses;

  /// Money moved into savings goals during this month.
  final double saved;

  /// Total savings contributed up to the end of this month.
  final double cumulativeSavings;

  const MonthlySummary({
    required this.month,
    required this.income,
    required this.expenses,
    required this.saved,
    required this.cumulativeSavings,
  });
}
