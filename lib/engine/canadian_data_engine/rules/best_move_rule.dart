import '../data/data_pack.dart';
import '../domain/best_move.dart';
import '../domain/figure_source.dart';
import '../domain/money_profile.dart';
import '../domain/rrsp_room.dart';
import '../domain/tfsa_room.dart';
import '../util/money_format.dart';
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

  final tfsa =
      tfsaConfigured ? tfsaRule(profile: profile, asOf: asOf, dataPack: dataPack) : null;
  final rrsp =
      rrspConfigured ? rrspRule(profile: profile, asOf: asOf, dataPack: dataPack) : null;

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

  // 3. RRSP contribution deadline within 60 days.
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

  // 4. Opportunity tie-break.
  final hasRrspRoom = rrsp != null && rrsp.isEligibleResult && rrsp.room > 0;
  final hasTfsaRoom =
      tfsa != null && tfsa.status != TfsaStatus.notYetEligible && tfsa.room > 0;

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
