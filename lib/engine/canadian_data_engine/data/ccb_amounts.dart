/// Canada Child Benefit parameters for a benefit year.
///
/// All dollars annual. The two-step phase-out applies above [threshold1] and
/// again above [threshold2]; the Step-2 base is computed as
/// `step1Rate × (threshold2 − threshold1)` so it can't drift from the rates.
class CcbParams {
  final double maxUnder6;
  final double max6to17;
  final double threshold1;
  final double threshold2;

  /// Step-1 reduction rates by child-count bucket [1, 2, 3, 4+].
  final List<double> step1Rates;

  /// Step-2 additional reduction rates by child-count bucket [1, 2, 3, 4+].
  final List<double> step2Rates;

  const CcbParams({
    required this.maxUnder6,
    required this.max6to17,
    required this.threshold1,
    required this.threshold2,
    required this.step1Rates,
    required this.step2Rates,
  });

  static double _bucket(List<double> rates, int childCount) {
    if (childCount <= 0) return 0;
    final index = (childCount.clamp(1, 4)) - 1;
    return rates[index];
  }

  double step1Rate(int childCount) => _bucket(step1Rates, childCount);
  double step2Rate(int childCount) => _bucket(step2Rates, childCount);
}

/// CCB parameters for the July 2025–June 2026 benefit year (2024 base year).
/// SOURCE: CRA CCB calculation sheet. Max amounts + thresholds index each July;
/// re-verify at the next benefit year. Reduction rates are long-stable.
const CcbParams kCcbParams2025 = CcbParams(
  maxUnder6: 7997,
  max6to17: 6748,
  threshold1: 37487,
  threshold2: 81222,
  step1Rates: [0.07, 0.135, 0.19, 0.23],
  step2Rates: [0.032, 0.057, 0.08, 0.095],
);

/// CCB data pack vintage.
const String kCcbDataPackVersion = 'ccb-embedded-2025-26.1';
