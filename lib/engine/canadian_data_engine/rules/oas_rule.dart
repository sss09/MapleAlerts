import 'dart:math' as math;

import '../data/data_pack.dart';
import '../data/oas_amounts.dart';
import '../domain/figure_source.dart';
import '../domain/money_profile.dart';
import '../domain/oas_result.dart';
import '../util/money_format.dart';

/// Age at which OAS becomes available.
const int kOasEligibilityAge = 65;

/// Estimates OAS recovery tax ("clawback"): 15% of net income above the
/// threshold, capped at the maximum OAS for the person's age band.
///
/// Deterministic and total. Uses [MoneyProfile.annualIncome] as the net-income
/// proxy and [MoneyProfile.birthYear] for age — no extra inputs.
OasResult oasRule({
  required MoneyProfile profile,
  required DateTime asOf,
  required DataPack dataPack,
}) {
  final params = dataPack.oasParams(asOf.year);
  final income = profile.annualIncome ?? 0;
  final birthYear = profile.birthYear;
  final age = birthYear == null ? null : asOf.year - birthYear;
  final threshold = params.recoveryThreshold;
  final age75plus = age != null && age >= 75;
  final maxOas = params.maxOasFor(age75plus: age75plus);

  OasResult result(OasStatus status, double clawback) => OasResult(
        status: status,
        clawbackAnnual: clawback,
        income: income,
        threshold: threshold,
        age: age,
        maxOas: maxOas,
        sources: [
          FigureSource('OAS clawback threshold', formatDollars(threshold),
              '${asOf.year} · Service Canada'),
          FigureSource('Recovery rate',
              '${(params.recoveryRate * 100).round()}%', 'of income over the threshold'),
          if (income > 0)
            FigureSource('Your income', formatDollars(income), 'Your input'),
        ],
      );

  if (age != null && age < kOasEligibilityAge) {
    return result(OasStatus.notYetEligible, 0);
  }

  if (income <= threshold) {
    final approaching = income > threshold - kOasApproachingBand;
    return result(approaching ? OasStatus.approaching : OasStatus.safe, 0);
  }

  final clawback =
      math.min(maxOas, params.recoveryRate * (income - threshold));
  return result(OasStatus.clawback, clawback);
}
