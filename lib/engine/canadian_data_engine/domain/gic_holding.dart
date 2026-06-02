import 'figure_source.dart';

/// Maturity state of a tracked GIC.
enum GicStatus {
  /// No GIC tracked.
  none,

  /// Matures more than the "soon" window away.
  later,

  /// Matures within the soon window (≤ 60 days).
  maturingSoon,

  /// Maturity date has passed.
  matured,
}

/// Result of the GIC rule. Pure data.
class GicResult {
  final GicStatus status;
  final double amount;
  final DateTime? maturityDate;

  /// Days from the as-of date to maturity (negative if matured).
  final int daysToMaturity;
  final List<FigureSource> sources;

  const GicResult({
    required this.status,
    required this.amount,
    required this.maturityDate,
    required this.daysToMaturity,
    this.sources = const [],
  });
}
