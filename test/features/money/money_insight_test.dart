import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/features/money/presentation/money_insight.dart';

TfsaRoomResult result(TfsaStatus status, {double room = 5000, int startYear = 2018}) {
  return TfsaRoomResult(
    status: status,
    room: room,
    cumulativeLimit: 50000,
    contributed: 50000 - room,
    startYear: startYear,
    asOfYear: 2026,
    currentYearLimit: 7000,
    sources: const [FigureSource('2026 TFSA limit', '\$7,000', 'CRA')],
  );
}

void main() {
  test('missing input yields a single setup insight', () {
    final insights = tfsaInsights(result(TfsaStatus.healthy), hasRequiredInput: false);
    expect(insights, hasLength(1));
    expect(insights.single.kind, InsightKind.setup);
    expect(insights.single.cta, isNotNull);
  });

  test('healthy maps to a positive found-money insight carrying the room', () {
    final insights = tfsaInsights(result(TfsaStatus.healthy, room: 14000), hasRequiredInput: true);
    final i = insights.single;
    expect(i.kind, InsightKind.foundMoney);
    expect(i.severity, InsightSeverity.positive);
    expect(i.amount, 14000);
    expect(i.sources, isNotEmpty);
    expect(i.isEstimate, isTrue);
  });

  test('nearLimit maps to a caution guardrail', () {
    final i = tfsaInsights(result(TfsaStatus.nearLimit, room: 500), hasRequiredInput: true).single;
    expect(i.kind, InsightKind.guardrail);
    expect(i.severity, InsightSeverity.caution);
    expect(i.amount, 500);
  });

  test('overContributed maps to an alert guardrail showing the overage', () {
    final i = tfsaInsights(result(TfsaStatus.overContributed, room: -1000), hasRequiredInput: true).single;
    expect(i.kind, InsightKind.guardrail);
    expect(i.severity, InsightSeverity.alert);
    expect(i.amount, 1000); // overage shown as a positive figure
  });

  test('notYetEligible maps to an info insight, not a guardrail', () {
    final i = tfsaInsights(
      result(TfsaStatus.notYetEligible, room: 0, startYear: 2028),
      hasRequiredInput: true,
    ).single;
    expect(i.kind, InsightKind.info);
    expect(i.headline, contains('2028'));
  });
}
