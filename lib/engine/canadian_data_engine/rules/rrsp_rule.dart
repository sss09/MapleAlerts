import 'dart:math' as math;

import '../data/data_pack.dart';
import '../data/rrsp_limits.dart';
import '../domain/figure_source.dart';
import '../domain/money_profile.dart';
import '../domain/rrsp_room.dart';
import '../util/money_format.dart';
import 'tax_rule.dart';

/// Room at or below this (and >= 0) is treated as "near the limit".
const double kRrspNearLimitThreshold = 1000;

/// Age (in the as-of year) after which an RRSP must convert to a RRIF.
const int kRrspMaxAge = 71;

/// Computes RRSP room, the estimated tax savings from using it, the next
/// contribution deadline, and a guardrail status.
///
/// Deterministic and total. Room comes from the user's NOA deduction limit
/// (which already folds in carry-forward room + pension adjustment), not from
/// income. Tax savings = remaining room × combined marginal rate (an estimate
/// assuming the contribution stays within the current bracket).
RrspResult rrspRule({
  required MoneyProfile profile,
  required DateTime asOf,
  required DataPack dataPack,
}) {
  final asOfYear = asOf.year;
  final limit = profile.rrspDeductionLimit ?? 0;
  final contributed = profile.rrspContributed ?? 0;
  final income = profile.annualIncome ?? 0;
  final province = profile.province;
  final room = limit - contributed;
  final buffer = dataPack.rrspOverContributionBuffer;

  final marginalRate = province == null
      ? 0.0
      : marginalTaxRate(
          year: asOfYear,
          province: province,
          income: income,
          dataPack: dataPack,
        );
  final estimatedTaxSavings = math.max(0.0, room) * marginalRate;

  final deadline = nextRrspDeadline(asOf);
  final asOfDate = DateTime(asOf.year, asOf.month, asOf.day);
  final daysToDeadline = deadline.difference(asOfDate).inDays;

  // ── Status ────────────────────────────────────────────────────────────────
  final RrspStatus status;
  final birthYear = profile.birthYear;
  if (birthYear != null && (asOfYear - birthYear) > kRrspMaxAge) {
    status = RrspStatus.noLongerEligible;
  } else if (contributed > limit + buffer) {
    status = RrspStatus.overContributed;
  } else if (room < 0) {
    status = RrspStatus.withinBuffer;
  } else if (room <= kRrspNearLimitThreshold) {
    status = RrspStatus.nearLimit;
  } else {
    status = RrspStatus.healthy;
  }

  // ── Sources ─────────────────────────────────────────────────────────────
  final sources = <FigureSource>[
    FigureSource('Your RRSP deduction limit', formatDollars(limit), 'Your CRA NOA'),
    if (contributed > 0)
      FigureSource('Contributed', formatDollars(contributed), 'Your input'),
    if (province != null)
      FigureSource(
        'Marginal tax rate',
        '~${(marginalRate * 100).round()}%',
        '$asOfYear ${province.code} tax brackets',
      ),
    FigureSource('RRSP deadline', _formatDate(deadline), 'CRA'),
  ];

  return RrspResult(
    status: status,
    room: room,
    deductionLimit: limit,
    contributed: contributed,
    marginalRate: marginalRate,
    estimatedTaxSavings: estimatedTaxSavings,
    nextDeadline: deadline,
    daysToDeadline: daysToDeadline,
    asOfYear: asOfYear,
    province: province,
    sources: sources,
  );
}

const _months = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime d) => '${_months[d.month]} ${d.day}, ${d.year}';
