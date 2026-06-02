import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/features/money/presentation/money_insight.dart';

CcbResult result(CcbStatus status, {double annual = 12000}) => CcbResult(
      status: status,
      annualAmount: annual,
      monthlyAmount: annual / 12,
      under6: 1,
      age6to17: 1,
      childCount: 2,
      afni: 45000,
      sources: const [FigureSource('CCB rates', 'Jul 2025–Jun 2026', 'CRA')],
    );

void main() {
  test('missing input yields a CCB setup insight with its CTA', () {
    final i = ccbInsights(result(CcbStatus.receiving), hasRequiredInput: false)
        .single;
    expect(i.kind, InsightKind.setup);
    expect(i.cta?.action, InsightAction.editCcbProfile);
  });

  test('receiving maps to found money carrying the monthly amount', () {
    final i = ccbInsights(result(CcbStatus.receiving, annual: 12000),
            hasRequiredInput: true)
        .single;
    expect(i.kind, InsightKind.foundMoney);
    expect(i.severity, InsightSeverity.positive);
    expect(i.amount, 1000); // 12000 / 12
    expect(i.headline, contains('month'));
  });

  test('notEligible maps to an info insight, not found money', () {
    final i = ccbInsights(result(CcbStatus.notEligible, annual: 0),
            hasRequiredInput: true)
        .single;
    expect(i.kind, InsightKind.info);
  });

  test('zeroByIncome maps to an info insight', () {
    final i = ccbInsights(result(CcbStatus.zeroByIncome, annual: 0),
            hasRequiredInput: true)
        .single;
    expect(i.kind, InsightKind.info);
  });
}
