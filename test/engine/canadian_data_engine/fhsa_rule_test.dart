import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  final asOf = DateTime(2026, 6, 1);
  const pack = EmbeddedDataPack();

  FhsaResult run({
    double? contributed,
    Province? province = Province.on,
    double? income = 80000,
  }) =>
      fhsaRule(
        profile: MoneyProfile(
          fhsaContributed: contributed,
          province: province,
          annualIncome: income,
        ),
        asOf: asOf,
        dataPack: pack,
      );

  test(r'zero contributed → full $40k lifetime room, $8k contributable this year', () {
    final r = run(contributed: 0);
    expect(r.room, 40000);
    expect(r.annualContributable, 8000);
    expect(r.status, FhsaStatus.healthy);
  });

  test('tax savings uses the marginal rate on the annual-contributable amount', () {
    final r = run(contributed: 0); // ON $80k → 29.65%
    expect(r.estimatedTaxSavings, closeTo(8000 * 0.2965, 1e-6));
  });

  test('annual contributable is capped by remaining lifetime room', () {
    final r = run(contributed: 35000); // room 5000 < 8000
    expect(r.room, 5000);
    expect(r.annualContributable, 5000);
    expect(r.status, FhsaStatus.healthy);
  });

  test('room at or below 1000 is nearLimit', () {
    final r = run(contributed: 39500); // room 500
    expect(r.status, FhsaStatus.nearLimit);
  });

  test('over the lifetime limit is overContributed (negative room)', () {
    final r = run(contributed: 42000);
    expect(r.room, -2000);
    expect(r.status, FhsaStatus.overContributed);
  });

  test('no province/income → room still computed, savings zero', () {
    final r = run(contributed: 10000, province: null, income: null);
    expect(r.room, 30000);
    expect(r.estimatedTaxSavings, 0);
  });
}
