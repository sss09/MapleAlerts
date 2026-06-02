import 'figure_source.dart';

/// Outcome bucket for an FHSA room calculation.
enum FhsaStatus { overContributed, nearLimit, healthy }

/// Result of the FHSA rule. Pure data with provenance + estimate flag.
class FhsaResult {
  final FhsaStatus status;

  /// Remaining lifetime room ($40,000 − contributed; negative if over).
  final double room;
  final double contributed;

  /// What can be contributed this year: min(annual limit, remaining room).
  final double annualContributable;

  /// Combined marginal rate (0 if province/income unknown).
  final double marginalRate;

  /// Tax saved by contributing [annualContributable] (deductible like RRSP).
  final double estimatedTaxSavings;

  final double lifetimeLimit;
  final double annualLimit;
  final List<FigureSource> sources;
  final bool isEstimate;

  const FhsaResult({
    required this.status,
    required this.room,
    required this.contributed,
    required this.annualContributable,
    required this.marginalRate,
    required this.estimatedTaxSavings,
    required this.lifetimeLimit,
    required this.annualLimit,
    required this.sources,
    this.isEstimate = true,
  });
}
