/// Old Age Security recovery-tax ("clawback") parameters for a year.
///
/// SOURCE: Canada.ca OAS recovery tax. Verified for 2025. Re-verify each year
/// (thresholds index). `maxOas` is derived as `rate × (upper − threshold)`.
class OasParams {
  /// Net income above which OAS starts being recovered.
  final double recoveryThreshold;

  /// Recovery rate (0.15 = 15 cents per dollar over the threshold).
  final double recoveryRate;

  /// Income at which OAS is fully recovered, ages 65–74.
  final double upperThreshold65to74;

  /// Income at which OAS is fully recovered, ages 75+.
  final double upperThreshold75plus;

  const OasParams({
    required this.recoveryThreshold,
    required this.recoveryRate,
    required this.upperThreshold65to74,
    required this.upperThreshold75plus,
  });

  double maxOasFor({required bool age75plus}) =>
      recoveryRate *
      ((age75plus ? upperThreshold75plus : upperThreshold65to74) -
          recoveryThreshold);
}

/// OAS recovery-tax parameters for 2025. SOURCE: Canada.ca.
const OasParams kOasParams2025 = OasParams(
  recoveryThreshold: 93454,
  recoveryRate: 0.15,
  upperThreshold65to74: 151668,
  upperThreshold75plus: 157490,
);

/// Income within this much below the threshold counts as "approaching".
const double kOasApproachingBand = 10000;

/// OAS data pack vintage.
const String kOasDataPackVersion = 'oas-embedded-2025.1';
