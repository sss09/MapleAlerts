import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/features/money/presentation/money_insight.dart';

FhsaResult result(
  FhsaStatus status, {
  double room = 40000,
  double savings = 2372,
}) =>
    FhsaResult(
      status: status,
      room: room,
      contributed: 40000 - room,
      annualContributable: room < 8000 ? room : 8000,
      marginalRate: 0.2965,
      estimatedTaxSavings: savings,
      lifetimeLimit: 40000,
      annualLimit: 8000,
      sources: const [FigureSource('FHSA lifetime limit', r'$40,000', 'CRA')],
    );

void main() {
  test('missing input → FHSA setup insight with CTA', () {
    final i = fhsaInsights(result(FhsaStatus.healthy), hasRequiredInput: false)
        .single;
    expect(i.kind, InsightKind.setup);
    expect(i.cta?.action, InsightAction.editFhsaProfile);
  });

  test('healthy → found money carrying room + tax-savings in copy', () {
    final i = fhsaInsights(result(FhsaStatus.healthy, room: 40000, savings: 2372),
            hasRequiredInput: true)
        .single;
    expect(i.kind, InsightKind.foundMoney);
    expect(i.severity, InsightSeverity.positive);
    expect(i.amount, 40000);
    expect(i.subline, contains('2,372'));
  });

  test('overContributed → alert guardrail with the overage', () {
    final i = fhsaInsights(result(FhsaStatus.overContributed, room: -2000),
            hasRequiredInput: true)
        .single;
    expect(i.kind, InsightKind.guardrail);
    expect(i.severity, InsightSeverity.alert);
    expect(i.amount, 2000);
  });

  test('nearLimit → caution guardrail', () {
    final i = fhsaInsights(result(FhsaStatus.nearLimit, room: 500),
            hasRequiredInput: true)
        .single;
    expect(i.kind, InsightKind.guardrail);
    expect(i.severity, InsightSeverity.caution);
  });
}
