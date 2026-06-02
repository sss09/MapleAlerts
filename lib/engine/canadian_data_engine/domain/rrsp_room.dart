import 'figure_source.dart';
import 'province.dart';

/// Outcome bucket for an RRSP room calculation.
enum RrspStatus {
  /// Over 71 in the as-of year — RRSP must convert to a RRIF.
  noLongerEligible,

  /// Contributions exceed the deduction limit by more than the $2,000 buffer.
  overContributed,

  /// Contributions exceed the limit but stay within the $2,000 lifetime buffer.
  withinBuffer,

  /// Room is at or below the near-limit threshold (>= 0).
  nearLimit,

  /// Comfortable room remaining — found money / tax-saving opportunity.
  healthy,
}

/// Result of the RRSP room rule. Pure data; carries provenance + estimate flag.
class RrspResult {
  final RrspStatus status;

  /// Deduction limit minus contributions (negative when over-contributed).
  final double room;

  final double deductionLimit;
  final double contributed;

  /// Combined federal + provincial marginal rate (fraction), 0 if no province.
  final double marginalRate;

  /// Estimated tax reduction from contributing the remaining room.
  final double estimatedTaxSavings;

  final DateTime nextDeadline;
  final int daysToDeadline;
  final int asOfYear;
  final Province? province;

  final List<FigureSource> sources;
  final bool isEstimate;

  const RrspResult({
    required this.status,
    required this.room,
    required this.deductionLimit,
    required this.contributed,
    required this.marginalRate,
    required this.estimatedTaxSavings,
    required this.nextDeadline,
    required this.daysToDeadline,
    required this.asOfYear,
    required this.province,
    required this.sources,
    this.isEstimate = true,
  });

  bool get isEligibleResult => status != RrspStatus.noLongerEligible;
}
