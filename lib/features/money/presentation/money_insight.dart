import '../../../engine/canadian_data_engine/canadian_data_engine.dart';

/// What kind of thing an insight is, for rendering + (later) ranking.
enum InsightKind { foundMoney, guardrail, setup, info }

/// Visual/emotional weight. Drives accent colour in [InsightCard].
enum InsightSeverity { positive, info, caution, alert }

/// An action a card CTA can trigger. The widget layer interprets these; the
/// mapper stays pure (no callbacks/Flutter), so it's trivially testable.
enum InsightAction { editTfsaProfile, editRrspProfile }

class InsightCta {
  final String label;
  final InsightAction action;
  const InsightCta(this.label, this.action);
}

/// The thin, shared view-model every rule projects onto. Home renders a
/// `List<MoneyInsight>`; a future "best move" surface ranks over the same shape.
/// Deliberately minimal — it earns more generality when a second rule arrives.
class MoneyInsight {
  /// Stable id, e.g. 'tfsa_room'.
  final String id;
  final InsightKind kind;
  final InsightSeverity severity;
  final String headline;
  final String? subline;

  /// Primary dollar figure for big-number rendering (already positive).
  final double? amount;
  final List<FigureSource> sources;
  final bool isEstimate;
  final InsightCta? cta;

  const MoneyInsight({
    required this.id,
    required this.kind,
    required this.severity,
    required this.headline,
    this.subline,
    this.amount,
    this.sources = const [],
    this.isEstimate = true,
    this.cta,
  });
}

/// Projects a [TfsaRoomResult] onto presentation insights.
///
/// [hasRequiredInput] is true only when the user has supplied both their birth
/// year and total contributions — otherwise we show a setup prompt rather than
/// a number derived from assumptions.
List<MoneyInsight> tfsaInsights(
  TfsaRoomResult result, {
  required bool hasRequiredInput,
}) {
  const id = 'tfsa_room';

  if (!hasRequiredInput) {
    return const [
      MoneyInsight(
        id: id,
        kind: InsightKind.setup,
        severity: InsightSeverity.info,
        headline: 'Find your TFSA room',
        subline:
            "Add your birth year and total contributions — we'll track your "
            'room and warn you before the CRA does.',
        cta: InsightCta('Set up', InsightAction.editTfsaProfile),
      ),
    ];
  }

  switch (result.status) {
    case TfsaStatus.notYetEligible:
      return [
        MoneyInsight(
          id: id,
          kind: InsightKind.info,
          severity: InsightSeverity.info,
          headline: 'TFSA room starts in ${result.startYear}',
          subline:
              'You begin accumulating contribution room the year you turn 18.',
          sources: result.sources,
          isEstimate: result.isEstimate,
        ),
      ];

    case TfsaStatus.overContributed:
      final overage = -result.room;
      return [
        MoneyInsight(
          id: id,
          kind: InsightKind.guardrail,
          severity: InsightSeverity.alert,
          headline: "You're ${formatDollars(overage)} over your TFSA limit",
          subline:
              'CRA charges a 1% penalty per month on the excess. Consider '
              'withdrawing to stop it.',
          amount: overage,
          sources: result.sources,
          isEstimate: result.isEstimate,
          cta: const InsightCta('Update my number', InsightAction.editTfsaProfile),
        ),
      ];

    case TfsaStatus.nearLimit:
      return [
        MoneyInsight(
          id: id,
          kind: InsightKind.guardrail,
          severity: InsightSeverity.caution,
          headline: '${formatDollars(result.room)} of TFSA room left',
          subline:
              "You're close to your limit — one more deposit could "
              'over-contribute.',
          amount: result.room,
          sources: result.sources,
          isEstimate: result.isEstimate,
          cta: const InsightCta('Update my number', InsightAction.editTfsaProfile),
        ),
      ];

    case TfsaStatus.healthy:
      return [
        MoneyInsight(
          id: id,
          kind: InsightKind.foundMoney,
          severity: InsightSeverity.positive,
          headline: 'You have ${formatDollars(result.room)} in TFSA room',
          subline: 'Tax-free room available to invest or save.',
          amount: result.room,
          sources: result.sources,
          isEstimate: result.isEstimate,
          cta: const InsightCta('Update my number', InsightAction.editTfsaProfile),
        ),
      ];
  }
}

/// RRSP contributions deadline gets urgent within this many days.
const int _rrspDeadlineWindowDays = 60;

/// Projects an [RrspResult] onto presentation insights. [hasRequiredInput] is
/// true only when province, income, deduction limit, and contributions are all
/// set — otherwise a setup prompt is shown.
List<MoneyInsight> rrspInsights(
  RrspResult result, {
  required bool hasRequiredInput,
}) {
  const id = 'rrsp_room';

  if (!hasRequiredInput) {
    return const [
      MoneyInsight(
        id: id,
        kind: InsightKind.setup,
        severity: InsightSeverity.info,
        headline: 'Estimate your RRSP refund',
        subline:
            'Add your province, income, and RRSP deduction limit — we’ll show '
            'your room and the tax it could save.',
        cta: InsightCta('Set up', InsightAction.editRrspProfile),
      ),
    ];
  }

  final ratePct = (result.marginalRate * 100).round();
  final savings = formatDollars(result.estimatedTaxSavings);
  const editCta = InsightCta('Update my numbers', InsightAction.editRrspProfile);

  switch (result.status) {
    case RrspStatus.noLongerEligible:
      return [
        MoneyInsight(
          id: id,
          kind: InsightKind.info,
          severity: InsightSeverity.info,
          headline: 'RRSP converts to a RRIF at 71',
          subline:
              'You can no longer contribute to an RRSP — talk to your '
              'institution about converting to a RRIF.',
          sources: result.sources,
          isEstimate: result.isEstimate,
        ),
      ];

    case RrspStatus.overContributed:
      final overage = -result.room;
      return [
        MoneyInsight(
          id: id,
          kind: InsightKind.guardrail,
          severity: InsightSeverity.alert,
          headline: "You're ${formatDollars(overage)} over your RRSP limit",
          subline:
              'Past the \$2,000 buffer — CRA charges 1%/month on the excess. '
              'Consider withdrawing to stop it.',
          amount: overage,
          sources: result.sources,
          isEstimate: result.isEstimate,
          cta: editCta,
        ),
      ];

    case RrspStatus.withinBuffer:
      final into = -result.room;
      return [
        MoneyInsight(
          id: id,
          kind: InsightKind.guardrail,
          severity: InsightSeverity.caution,
          headline: '${formatDollars(into)} into your \$2,000 RRSP buffer',
          subline:
              "No penalty yet, but you're past your deduction limit — best to "
              'stop contributing.',
          amount: into,
          sources: result.sources,
          isEstimate: result.isEstimate,
          cta: editCta,
        ),
      ];

    case RrspStatus.nearLimit:
      return [
        MoneyInsight(
          id: id,
          kind: InsightKind.guardrail,
          severity: InsightSeverity.caution,
          headline: '${formatDollars(result.room)} of RRSP room left',
          subline: "You're almost at your deduction limit.",
          amount: result.room,
          sources: result.sources,
          isEstimate: result.isEstimate,
          cta: editCta,
        ),
      ];

    case RrspStatus.healthy:
      final nearDeadline = result.daysToDeadline <= _rrspDeadlineWindowDays;
      final subline = nearDeadline
          ? 'RRSP deadline ${_formatDate(result.nextDeadline)} — contributing '
              'your room could save ≈$savings at ~$ratePct%.'
          : 'Contributing it could save ≈$savings at your ~$ratePct% '
              'marginal rate.';
      return [
        MoneyInsight(
          id: id,
          kind: InsightKind.foundMoney,
          severity:
              nearDeadline ? InsightSeverity.caution : InsightSeverity.positive,
          headline: 'You have ${formatDollars(result.room)} of RRSP room',
          subline: subline,
          amount: result.room,
          sources: result.sources,
          isEstimate: result.isEstimate,
          cta: editCta,
        ),
      ];
  }
}

const _monthsAbbr = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime d) => '${_monthsAbbr[d.month]} ${d.day}, ${d.year}';
