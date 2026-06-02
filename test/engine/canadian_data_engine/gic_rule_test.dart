import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  final asOf = DateTime(2026, 6, 2);

  GicResult run({double? amount, DateTime? maturity}) => gicRule(
        profile: MoneyProfile(gicAmount: amount, gicMaturityDate: maturity),
        asOf: asOf,
      );

  test('no GIC entered → none', () {
    expect(run().status, GicStatus.none);
  });

  test('maturing within 60 days → maturingSoon with day count', () {
    final r = run(amount: 20000, maturity: DateTime(2026, 6, 20));
    expect(r.status, GicStatus.maturingSoon);
    expect(r.daysToMaturity, 18);
  });

  test('exactly 60 days out is maturingSoon; 61 is later', () {
    expect(run(amount: 1, maturity: asOf.add(const Duration(days: 60))).status,
        GicStatus.maturingSoon);
    expect(run(amount: 1, maturity: asOf.add(const Duration(days: 61))).status,
        GicStatus.later);
  });

  test('past maturity → matured', () {
    final r = run(amount: 20000, maturity: DateTime(2026, 5, 1));
    expect(r.status, GicStatus.matured);
    expect(r.daysToMaturity, lessThan(0));
  });

  test('zero/absent amount → none even with a date', () {
    expect(run(amount: 0, maturity: DateTime(2026, 6, 20)).status,
        GicStatus.none);
  });
}
