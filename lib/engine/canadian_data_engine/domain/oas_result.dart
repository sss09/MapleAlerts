import 'figure_source.dart';

/// Outcome bucket for an OAS clawback (recovery-tax) calculation.
enum OasStatus {
  /// Under 65 — OAS hasn't started.
  notYetEligible,

  /// Income below the recovery threshold — full OAS kept.
  safe,

  /// Income within the warning band just below the threshold.
  approaching,

  /// Income above the threshold — some/all OAS recovered.
  clawback,
}

/// Result of the OAS recovery-tax rule. Pure data with provenance.
class OasResult {
  final OasStatus status;

  /// Annual OAS recovered (0 unless [status] == clawback), capped at max OAS.
  final double clawbackAnnual;

  final double income;
  final double threshold;
  final int? age;
  final double maxOas;
  final List<FigureSource> sources;
  final bool isEstimate;

  const OasResult({
    required this.status,
    required this.clawbackAnnual,
    required this.income,
    required this.threshold,
    required this.age,
    required this.maxOas,
    required this.sources,
    this.isEstimate = true,
  });
}
