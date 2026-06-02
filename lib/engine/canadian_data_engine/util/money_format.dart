/// Formats a dollar amount as e.g. `$7,000` or `$1,234.50`.
///
/// Pure Dart (no `intl` dependency) so the engine stays self-contained and
/// liftable. Whole amounts drop the decimals; fractional amounts show two.
String formatDollars(num amount) {
  final negative = amount < 0;
  final abs = amount.abs();
  final whole = abs.truncate();
  final cents = ((abs - whole) * 100).round();

  final digits = whole.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }

  final body = cents == 0
      ? buf.toString()
      : '${buf.toString()}.${cents.toString().padLeft(2, '0')}';
  return '${negative ? '-' : ''}\$$body';
}
