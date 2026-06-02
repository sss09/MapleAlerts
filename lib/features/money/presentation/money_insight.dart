import '../../../engine/canadian_data_engine/canadian_data_engine.dart';

/// What kind of thing an insight is, for rendering + (later) ranking.
enum InsightKind { foundMoney, guardrail, setup, info }

/// Visual/emotional weight. Drives accent colour in [InsightCard].
enum InsightSeverity { positive, info, caution, alert }

/// An action a card CTA can trigger. The widget layer interprets these; the
/// mapper stays pure (no callbacks/Flutter), so it's trivially testable.
enum InsightAction { editTfsaProfile }

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
