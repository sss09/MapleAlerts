import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/features/money/presentation/money_insight.dart';

GicResult result(GicStatus status, {int days = 18}) => GicResult(
      status: status,
      amount: 20000,
      maturityDate: DateTime(2026, 6, 20),
      daysToMaturity: days,
      sources: const [FigureSource('GIC principal', r'$20,000', 'Your input')],
    );

void main() {
  test('missing input → GIC setup insight with CTA', () {
    final i = gicInsights(result(GicStatus.none), hasRequiredInput: false).single;
    expect(i.kind, InsightKind.setup);
    expect(i.cta?.action, InsightAction.editGicProfile);
  });

  test('maturing soon → found money carrying the amount and day count', () {
    final i = gicInsights(result(GicStatus.maturingSoon, days: 18),
            hasRequiredInput: true)
        .single;
    expect(i.kind, InsightKind.foundMoney);
    expect(i.amount, 20000);
    expect(i.headline, contains('18'));
  });

  test('matured → info', () {
    final i =
        gicInsights(result(GicStatus.matured), hasRequiredInput: true).single;
    expect(i.kind, InsightKind.info);
  });

  test('later → info', () {
    final i =
        gicInsights(result(GicStatus.later), hasRequiredInput: true).single;
    expect(i.kind, InsightKind.info);
  });
}
