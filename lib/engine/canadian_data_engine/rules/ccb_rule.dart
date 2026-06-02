import 'dart:math' as math;

import '../data/data_pack.dart';
import '../domain/ccb_benefit.dart';
import '../domain/figure_source.dart';
import '../domain/money_profile.dart';
import '../util/money_format.dart';

/// Estimates the household's annual + monthly Canada Child Benefit from the
/// number of children by age band and the adjusted family net income (AFNI).
///
/// Deterministic and total. Federal, province-agnostic. The two-step phase-out
/// reduces the base by a child-count-dependent rate above each threshold.
CcbResult ccbRule({
  required MoneyProfile profile,
  required DateTime asOf,
  required DataPack dataPack,
}) {
  final params = dataPack.ccbParams(asOf.year);
  final under6 = profile.kidsUnder6 ?? 0;
  final age6to17 = profile.kids6to17 ?? 0;
  final childCount = under6 + age6to17;
  final afni = profile.familyNetIncome ?? 0;

  CcbResult result(CcbStatus status, double annual, List<FigureSource> sources) =>
      CcbResult(
        status: status,
        annualAmount: annual,
        monthlyAmount: annual / 12,
        under6: under6,
        age6to17: age6to17,
        childCount: childCount,
        afni: afni,
        sources: sources,
      );

  if (childCount <= 0) {
    return result(CcbStatus.notEligible, 0, const []);
  }

  final base = under6 * params.maxUnder6 + age6to17 * params.max6to17;

  double reduction;
  if (afni <= params.threshold1) {
    reduction = 0;
  } else if (afni <= params.threshold2) {
    reduction = params.step1Rate(childCount) * (afni - params.threshold1);
  } else {
    final step1Base =
        params.step1Rate(childCount) * (params.threshold2 - params.threshold1);
    reduction =
        step1Base + params.step2Rate(childCount) * (afni - params.threshold2);
  }

  final annual = math.max(0.0, base - reduction);

  final sources = <FigureSource>[
    FigureSource(
      'Children',
      '$under6 under 6, $age6to17 aged 6–17',
      'Your input',
    ),
    FigureSource('Family net income', formatDollars(afni), 'Your input'),
    FigureSource(
      'CCB rates',
      'Jul 2025–Jun 2026',
      'CRA',
    ),
  ];

  return result(
    annual > 0 ? CcbStatus.receiving : CcbStatus.zeroByIncome,
    annual,
    sources,
  );
}
