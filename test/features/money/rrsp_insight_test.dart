import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/features/money/presentation/money_insight.dart';

RrspResult result(
  RrspStatus status, {
  double room = 30000,
  double savings = 8895,
  int daysToDeadline = 270,
}) {
  return RrspResult(
    status: status,
    room: room,
    deductionLimit: 50000,
    contributed: 50000 - room,
    marginalRate: 0.2965,
    estimatedTaxSavings: savings,
    nextDeadline: DateTime(2027, 3, 1),
    daysToDeadline: daysToDeadline,
    asOfYear: 2026,
    province: Province.on,
    sources: const [FigureSource('Marginal tax rate', '~30%', '2026 ON')],
  );
}

void main() {
  test('missing input yields an RRSP setup insight with its CTA', () {
    final i = rrspInsights(result(RrspStatus.healthy), hasRequiredInput: false)
        .single;
    expect(i.kind, InsightKind.setup);
    expect(i.cta?.action, InsightAction.editRrspProfile);
  });

  test('healthy maps to found money carrying room + tax-savings in the copy', () {
    final i = rrspInsights(result(RrspStatus.healthy, room: 30000, savings: 8895),
            hasRequiredInput: true)
        .single;
    expect(i.kind, InsightKind.foundMoney);
    expect(i.severity, InsightSeverity.positive);
    expect(i.amount, 30000);
    expect(i.subline, contains('8,895')); // the savings estimate
  });

  test('overContributed maps to an alert guardrail', () {
    final i = rrspInsights(result(RrspStatus.overContributed, room: -3000),
            hasRequiredInput: true)
        .single;
    expect(i.kind, InsightKind.guardrail);
    expect(i.severity, InsightSeverity.alert);
    expect(i.amount, 3000); // overage as a positive figure
  });

  test('withinBuffer maps to a caution guardrail', () {
    final i = rrspInsights(result(RrspStatus.withinBuffer, room: -1500),
            hasRequiredInput: true)
        .single;
    expect(i.kind, InsightKind.guardrail);
    expect(i.severity, InsightSeverity.caution);
  });

  test('noLongerEligible maps to an info insight', () {
    final i = rrspInsights(result(RrspStatus.noLongerEligible),
            hasRequiredInput: true)
        .single;
    expect(i.kind, InsightKind.info);
  });

  test('healthy near the deadline escalates to a caution', () {
    final i = rrspInsights(
      result(RrspStatus.healthy, daysToDeadline: 30),
      hasRequiredInput: true,
    ).single;
    expect(i.severity, InsightSeverity.caution);
    expect(i.subline, contains('deadline'));
  });
}
