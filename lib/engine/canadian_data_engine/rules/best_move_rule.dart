import 'dart:math' as math;

import '../data/data_pack.dart';
import '../domain/best_move.dart';
import '../domain/fhsa_account.dart';
import '../domain/figure_source.dart';
import '../domain/gic_holding.dart';
import '../domain/money_profile.dart';
import '../domain/rrsp_room.dart';
import '../domain/tfsa_room.dart';
import '../util/money_format.dart';
import 'fhsa_rule.dart';
import 'gic_rule.dart';
import 'rrsp_rule.dart';
import 'tfsa_rule.dart';

/// At or above this combined marginal rate, an RRSP contribution is preferred
/// over a TFSA one (deductible now at a high rate). A tunable guidance heuristic.
const double kRrspPreferredMarginalRate = 0.30;

/// The single best action to take right now, or null if nothing is actionable.
///
/// Deterministic priority cascade across the configured accounts:
///   1. Fix an RRSP over-contribution (penalty accruing).
///   2. Fix a TFSA over-contribution.
///   3. RRSP contribution deadline within 60 days (with room + tax savings).
///   4. Opportunity: RRSP if marginal rate ≥ threshold, else TFSA, else RRSP.
/// CCB is excluded — it's automatic money, not an action.
BestMove? bestMove({
  required MoneyProfile profile,
  required DateTime asOf,
  required DataPack dataPack,
}) {
  final tfsaConfigured =
      profile.birthYear != null && profile.tfsaContributed != null;
  final rrspConfigured = profile.province != null &&
      profile.annualIncome != null &&
      profile.rrspDeductionLimit != null &&
      profile.rrspContributed != null;

  final fhsaConfigured = profile.fhsaContributed != null;

  final tfsa =
      tfsaConfigured ? tfsaRule(profile: profile, asOf: asOf, dataPack: dataPack) : null;
  final rrsp =
      rrspConfigured ? rrspRule(profile: profile, asOf: asOf, dataPack: dataPack) : null;
  final fhsa =
      fhsaConfigured ? fhsaRule(profile: profile, asOf: asOf, dataPack: dataPack) : null;

  // 1. RRSP over-contribution.
  if (rrsp != null && rrsp.status == RrspStatus.overContributed) {
    final overage = -rrsp.room;
    return BestMove(
      kind: BestMoveKind.fixGuardrail,
      title: 'Fix your RRSP over-contribution',
      detail:
          "You're ${formatDollars(overage)} past your limit and the \$2,000 "
          'buffer — CRA charges 1%/month on the excess. Withdraw it to stop the '
          'penalty.',
      dollarValue: overage,
      targetInsightId: 'rrsp_room',
      sources: rrsp.sources,
    );
  }

  // 2. TFSA over-contribution.
  if (tfsa != null && tfsa.status == TfsaStatus.overContributed) {
    final overage = -tfsa.room;
    return BestMove(
      kind: BestMoveKind.fixGuardrail,
      title: 'Fix your TFSA over-contribution',
      detail:
          "You're ${formatDollars(overage)} over your TFSA limit — CRA charges "
          '1%/month on the excess. Withdraw it to stop the penalty.',
      dollarValue: overage,
      targetInsightId: 'tfsa_room',
      sources: tfsa.sources,
    );
  }

  // 2b. FHSA over-contribution.
  if (fhsa != null && fhsa.status == FhsaStatus.overContributed) {
    final overage = -fhsa.room;
    return BestMove(
      kind: BestMoveKind.fixGuardrail,
      title: 'Fix your FHSA over-contribution',
      detail:
          "You're ${formatDollars(overage)} over the \$40,000 FHSA lifetime "
          'limit — CRA charges 1%/month on the excess. Withdraw it to stop the '
          'penalty.',
      dollarValue: overage,
      targetInsightId: 'fhsa',
      sources: fhsa.sources,
    );
  }

  // Room available to shelter freed-up cash (TFSA preferred, then RRSP).
  final hasTfsaRoomNow =
      tfsa != null && tfsa.status != TfsaStatus.notYetEligible && tfsa.room > 0;
  final hasRrspRoomNow = rrsp != null && rrsp.isEligibleResult && rrsp.room > 0;

  // 3. A GIC maturing soon + somewhere to shelter the proceeds.
  final gic = gicRule(profile: profile, asOf: asOf);
  if (gic.status == GicStatus.maturingSoon && (hasTfsaRoomNow || hasRrspRoomNow)) {
    final intoTfsa = hasTfsaRoomNow;
    final room = intoTfsa ? tfsa.room : rrsp!.room;
    final value = math.min(gic.amount, room);
    final account = intoTfsa ? 'TFSA' : 'RRSP';
    return BestMove(
      kind: BestMoveKind.deadline,
      title: 'Shelter your maturing GIC',
      detail:
          'Your ${formatDollars(gic.amount)} GIC matures in ${gic.daysToMaturity} '
          'days. Move up to ${formatDollars(value)} into your $account so the '
          'cash keeps growing tax-sheltered instead of sitting idle.',
      dollarValue: value,
      targetInsightId: intoTfsa ? 'tfsa_room' : 'rrsp_room',
      sources: gic.sources,
    );
  }

  // 4. RRSP contribution deadline within 60 days.
  if (rrsp != null &&
      rrsp.room > 0 &&
      rrsp.estimatedTaxSavings > 0 &&
      rrsp.daysToDeadline <= 60) {
    return BestMove(
      kind: BestMoveKind.deadline,
      title: 'Contribute to your RRSP before the deadline',
      detail:
          'The RRSP deadline is in ${rrsp.daysToDeadline} days. Contributing '
          'your ${formatDollars(rrsp.room)} of room could save ≈'
          '${formatDollars(rrsp.estimatedTaxSavings)} in tax.',
      dollarValue: rrsp.estimatedTaxSavings,
      targetInsightId: 'rrsp_room',
      sources: rrsp.sources,
    );
  }

  // 5. FHSA opportunity — for first-home savers it beats RRSP/TFSA (deductible
  //    now AND tax-free on withdrawal for a home). Opting into the FHSA topic
  //    signals the intent, so a configured FHSA with room ranks first here.
  if (fhsa != null && fhsa.room > 0) {
    final savingsNote = fhsa.estimatedTaxSavings > 0
        ? ' Contributing this year could save '
            '≈${formatDollars(fhsa.estimatedTaxSavings)} in tax, and it '
            'grows tax-free.'
        : ' Contributions grow tax-free.';
    return BestMove(
      kind: BestMoveKind.opportunity,
      title: 'Contribute to your FHSA',
      detail:
          'The FHSA is hard to beat for a first home — deductible like an RRSP '
          'and tax-free on withdrawal.$savingsNote '
          'Up to ${formatDollars(fhsa.annualContributable)} this year.',
      dollarValue: fhsa.estimatedTaxSavings > 0
          ? fhsa.estimatedTaxSavings
          : fhsa.annualContributable,
      targetInsightId: 'fhsa',
      sources: fhsa.sources,
    );
  }

  // 6. Opportunity tie-break (RRSP vs TFSA).
  final hasRrspRoom = hasRrspRoomNow;
  final hasTfsaRoom = hasTfsaRoomNow;

  if (hasRrspRoom && rrsp.marginalRate >= kRrspPreferredMarginalRate) {
    final pct = (rrsp.marginalRate * 100).round();
    return BestMove(
      kind: BestMoveKind.opportunity,
      title: 'Contribute to your RRSP',
      detail:
          'At your ~$pct% marginal rate, an RRSP contribution saves more tax '
          'than a TFSA right now. Using your ${formatDollars(rrsp.room)} of room '
          'could save ≈${formatDollars(rrsp.estimatedTaxSavings)}.',
      dollarValue: rrsp.estimatedTaxSavings,
      targetInsightId: 'rrsp_room',
      sources: [
        FigureSource('Why RRSP over TFSA', 'Marginal rate ~$pct%',
            'At or above ${(kRrspPreferredMarginalRate * 100).round()}% the deduction wins'),
        ...rrsp.sources,
      ],
    );
  }

  if (hasTfsaRoom) {
    return BestMove(
      kind: BestMoveKind.opportunity,
      title: 'Use your TFSA room',
      detail:
          'Shelter up to ${formatDollars(tfsa.room)} from tax. TFSA growth and '
          'withdrawals are tax-free and flexible.',
      dollarValue: tfsa.room,
      targetInsightId: 'tfsa_room',
      sources: tfsa.sources,
    );
  }

  if (hasRrspRoom) {
    return BestMove(
      kind: BestMoveKind.opportunity,
      title: 'Contribute to your RRSP',
      detail:
          'Using your ${formatDollars(rrsp.room)} of RRSP room could save ≈'
          '${formatDollars(rrsp.estimatedTaxSavings)} in tax.',
      dollarValue: rrsp.estimatedTaxSavings,
      targetInsightId: 'rrsp_room',
      sources: rrsp.sources,
    );
  }

  return null;
}
