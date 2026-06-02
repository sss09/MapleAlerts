import 'dart:math' as math;

import '../data/data_pack.dart';
import '../domain/figure_source.dart';
import '../domain/money_profile.dart';
import '../domain/tfsa_room.dart';
import '../util/money_format.dart';

/// Room at or below this (and >= 0) is treated as "near the limit" — a gentle
/// guardrail before the user risks over-contributing.
const double kTfsaNearLimitThreshold = 1000;

/// Computes a user's cumulative TFSA contribution room as of [asOf].
///
/// Deterministic and total: every [MoneyProfile] yields a valid result, never
/// throws. Missing contributions are treated as $0. The math:
///
///   startYear       = max(firstDataYear, yearTurned18)
///   cumulativeLimit = Σ annual limits for [startYear .. asOfYear]
///   room            = cumulativeLimit − contributed
///
/// Room is left negative when over-contributed so callers see the true overage.
TfsaRoomResult tfsaRule({
  required MoneyProfile profile,
  required DateTime asOf,
  required DataPack dataPack,
}) {
  final asOfYear = asOf.year;
  final contributed = profile.tfsaContributed ?? 0;
  final birthYear = profile.birthYear;
  final currentYearLimit = dataPack.tfsaAnnualLimit(asOfYear) ?? 0;
  final firstDataYear = dataPack.tfsaFirstYear;

  // ── Not yet eligible: user turns 18 after the as-of year ─────────────────
  if (birthYear != null && (birthYear + 18) > asOfYear) {
    return TfsaRoomResult(
      status: TfsaStatus.notYetEligible,
      room: 0,
      cumulativeLimit: 0,
      contributed: contributed,
      startYear: birthYear + 18,
      asOfYear: asOfYear,
      currentYearLimit: currentYearLimit,
      sources: [
        FigureSource(
          'TFSA eligibility',
          'Age 18 (${birthYear + 18})',
          'CRA',
        ),
      ],
    );
  }

  // ── Eligible: accrue room from the later of 2009 / the year they turned 18 ─
  final eligibilityYear = birthYear == null ? firstDataYear : birthYear + 18;
  final startYear = math.max(firstDataYear, eligibilityYear);

  var cumulative = 0.0;
  for (var y = startYear; y <= asOfYear; y++) {
    cumulative += (dataPack.tfsaAnnualLimit(y) ?? 0).toDouble();
  }
  final room = cumulative - contributed;

  final TfsaStatus status;
  if (room < 0) {
    status = TfsaStatus.overContributed;
  } else if (room <= kTfsaNearLimitThreshold) {
    status = TfsaStatus.nearLimit;
  } else {
    status = TfsaStatus.healthy;
  }

  final sources = <FigureSource>[
    FigureSource('$asOfYear TFSA limit', formatDollars(currentYearLimit), 'CRA'),
    FigureSource(
      'Room counted from',
      '$startYear',
      birthYear == null
          ? 'TFSA started in $firstDataYear'
          : 'You turned 18 that year',
    ),
    if (contributed > 0)
      FigureSource(
        'You told us you contributed',
        formatDollars(contributed),
        'Your input',
      ),
  ];

  return TfsaRoomResult(
    status: status,
    room: room,
    cumulativeLimit: cumulative,
    contributed: contributed,
    startYear: startYear,
    asOfYear: asOfYear,
    currentYearLimit: currentYearLimit,
    sources: sources,
  );
}
