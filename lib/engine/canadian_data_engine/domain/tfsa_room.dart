import 'figure_source.dart';

/// Outcome bucket for a TFSA room calculation. Drives both the guardrail
/// (protective) and found-money (opportunity) framings downstream.
enum TfsaStatus {
  /// User turns 18 after the as-of year — no room has accrued yet.
  notYetEligible,

  /// Contributions exceed cumulative room — CRA penalty risk.
  overContributed,

  /// Room is at or below the near-limit threshold (>= 0).
  nearLimit,

  /// Comfortable room remaining — found money.
  healthy,
}

/// Result of the TFSA room rule. Pure data; carries its own provenance
/// ([sources]) and the [isEstimate] flag so the UI can frame it honestly.
class TfsaRoomResult {
  final TfsaStatus status;

  /// Cumulative limit minus contributions. Negative when over-contributed
  /// (the true overage is preserved, not clamped — the UI decides display).
  final double room;

  /// Sum of annual limits from [startYear] through [asOfYear].
  final double cumulativeLimit;

  /// Contributions the calculation used (0 when unknown).
  final double contributed;

  /// First year room accrued for this user (max of 2009 and the year they
  /// turned 18). For the notYetEligible case this is the future year they
  /// turn 18.
  final int startYear;

  /// Calendar year the calculation was run for.
  final int asOfYear;

  /// The TFSA annual limit for [asOfYear].
  final int currentYearLimit;

  final List<FigureSource> sources;

  final bool isEstimate;

  const TfsaRoomResult({
    required this.status,
    required this.room,
    required this.cumulativeLimit,
    required this.contributed,
    required this.startYear,
    required this.asOfYear,
    required this.currentYearLimit,
    required this.sources,
    this.isEstimate = true,
  });

  /// True when we have enough input to show a real number (vs. a setup prompt).
  /// We need a birth year to know eligibility; contributions default to 0.
  bool get isEligibleResult => status != TfsaStatus.notYetEligible;
}
