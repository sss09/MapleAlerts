import 'dart:math' as math;

import '../data/data_pack.dart';
import '../domain/fhsa_account.dart';
import '../domain/figure_source.dart';
import '../domain/money_profile.dart';
import '../util/money_format.dart';
import 'tax_rule.dart';

/// Room at or below this (and >= 0) is treated as "near the limit".
const double kFhsaNearLimitThreshold = 1000;

/// Computes FHSA lifetime room, what's contributable this year, and the tax it
/// could save (FHSA contributions are deductible like an RRSP).
///
/// Single-number v1: lifetime room = $40,000 − contributed. The $8,000 annual
/// limit (+ carry-forward) is surfaced as the per-year contributable amount.
FhsaResult fhsaRule({
  required MoneyProfile profile,
  required DateTime asOf,
  required DataPack dataPack,
}) {
  final contributed = profile.fhsaContributed ?? 0;
  final lifetimeLimit = dataPack.fhsaLifetimeLimit;
  final annualLimit = dataPack.fhsaAnnualLimit;
  final room = lifetimeLimit - contributed;
  final annualContributable = math.max(0.0, math.min(annualLimit, room));

  final province = profile.province;
  final income = profile.annualIncome;
  final marginalRate = (province == null || income == null)
      ? 0.0
      : marginalTaxRate(
          year: asOf.year,
          province: province,
          income: income,
          dataPack: dataPack,
        );
  final estimatedTaxSavings = annualContributable * marginalRate;

  final FhsaStatus status;
  if (room < 0) {
    status = FhsaStatus.overContributed;
  } else if (room <= kFhsaNearLimitThreshold) {
    status = FhsaStatus.nearLimit;
  } else {
    status = FhsaStatus.healthy;
  }

  final sources = <FigureSource>[
    FigureSource('FHSA lifetime limit', formatDollars(lifetimeLimit), 'CRA'),
    FigureSource('Annual limit', formatDollars(annualLimit), 'CRA'),
    if (contributed > 0)
      FigureSource('Contributed', formatDollars(contributed), 'Your input'),
    if (marginalRate > 0)
      FigureSource('Marginal tax rate', '~${(marginalRate * 100).round()}%',
          '${asOf.year} ${province!.code} tax brackets'),
  ];

  return FhsaResult(
    status: status,
    room: room,
    contributed: contributed,
    annualContributable: annualContributable,
    marginalRate: marginalRate,
    estimatedTaxSavings: estimatedTaxSavings,
    lifetimeLimit: lifetimeLimit,
    annualLimit: annualLimit,
    sources: sources,
  );
}
