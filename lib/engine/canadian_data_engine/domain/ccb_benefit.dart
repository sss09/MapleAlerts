import 'figure_source.dart';

/// Outcome bucket for a Canada Child Benefit calculation.
enum CcbStatus {
  /// No eligible children — CCB does not apply.
  notEligible,

  /// Has children, but family income phases the benefit out to $0.
  zeroByIncome,

  /// Receiving a positive benefit.
  receiving,
}

/// Result of the CCB rule. Pure data; carries provenance + estimate flag.
class CcbResult {
  final CcbStatus status;
  final double annualAmount;
  final double monthlyAmount;
  final int under6;
  final int age6to17;
  final int childCount;
  final double afni;
  final List<FigureSource> sources;
  final bool isEstimate;

  const CcbResult({
    required this.status,
    required this.annualAmount,
    required this.monthlyAmount,
    required this.under6,
    required this.age6to17,
    required this.childCount,
    required this.afni,
    required this.sources,
    this.isEstimate = true,
  });
}
