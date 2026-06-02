import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/features/money/presentation/money_insight.dart';

OasResult result(OasStatus status, {double clawback = 0}) => OasResult(
      status: status,
      clawbackAnnual: clawback,
      income: 120000,
      threshold: 93454,
      age: 70,
      maxOas: 8732,
      sources: const [FigureSource('OAS clawback threshold', r'$93,454', '2026')],
    );

void main() {
  test('missing input yields an OAS setup insight with its CTA', () {
    final i = oasInsights(result(OasStatus.safe), hasRequiredInput: false).single;
    expect(i.kind, InsightKind.setup);
    expect(i.cta?.action, InsightAction.editOasProfile);
  });

  test('clawback maps to a caution guardrail carrying the amount', () {
    final i = oasInsights(result(OasStatus.clawback, clawback: 3982),
            hasRequiredInput: true)
        .single;
    expect(i.kind, InsightKind.guardrail);
    expect(i.severity, InsightSeverity.caution);
    expect(i.amount, 3982);
  });

  test('safe maps to a reassuring info insight', () {
    final i = oasInsights(result(OasStatus.safe), hasRequiredInput: true).single;
    expect(i.kind, InsightKind.info);
  });

  test('approaching maps to a caution guardrail', () {
    final i =
        oasInsights(result(OasStatus.approaching), hasRequiredInput: true).single;
    expect(i.kind, InsightKind.guardrail);
    expect(i.severity, InsightSeverity.caution);
  });

  test('notYetEligible maps to info', () {
    final i = oasInsights(result(OasStatus.notYetEligible), hasRequiredInput: true)
        .single;
    expect(i.kind, InsightKind.info);
  });
}
