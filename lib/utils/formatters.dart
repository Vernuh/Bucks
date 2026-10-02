/// Number/date helpers shared by screens (no intl dependency).

/// 15000 -> "15,000"; 1250.5 -> "1,250.50"; -300 -> "-300".
String formatNumber(double value) {
  final negative = value < 0;
  final abs = value.abs();
  final isWhole = (abs - abs.roundToDouble()).abs() < 0.005;
  final fixed = isWhole ? abs.round().toString() : abs.toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  final decimals = parts.length > 1 ? '.${parts[1]}' : '';
  return '${negative ? '-' : ''}$buf$decimals';
}

/// 15000 -> "₱15,000"; -300 -> "-₱300".
String formatPeso(double value) {
  final text = formatNumber(value.abs());
  return '${value < 0 ? '-' : ''}\u20b1$text';
}

const _monthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String monthShort(int month) => _monthShort[month - 1];

/// "Oct 2, 2026"
String formatDate(DateTime d) => '${monthShort(d.month)} ${d.day}, ${d.year}';

/// "yyyy-MM-dd" — used as the stable key for a calendar day.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
