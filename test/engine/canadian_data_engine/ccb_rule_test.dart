import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  final asOf = DateTime(2026, 6, 1);
  const pack = EmbeddedDataPack();

  CcbResult run({int under6 = 0, int age6to17 = 0, double? afni}) => ccbRule(
        profile: MoneyProfile(
          kidsUnder6: under6,
          kids6to17: age6to17,
          familyNetIncome: afni,
        ),
        asOf: asOf,
        dataPack: pack,
      );

  test('income below the first threshold gives the full amount', () {
    final r = run(under6: 1, afni: 30000);
    expect(r.annualAmount, closeTo(7997, 1e-6));
    expect(r.monthlyAmount, closeTo(7997 / 12, 1e-6));
    expect(r.status, CcbStatus.receiving);
    expect(r.isEstimate, isTrue);
  });

  test('Step 1 reduction for two children of different ages', () {
    // base 7997 + 6748 = 14745; 2-child rate 13.5% over (50000 - 37487).
    final r = run(under6: 1, age6to17: 1, afni: 50000);
    final expected = 14745 - 0.135 * (50000 - 37487);
    expect(r.annualAmount, closeTo(expected, 1e-6));
    expect(r.status, CcbStatus.receiving);
  });

  test('Step 2 phase-out drives the amount to zero at high income', () {
    final r = run(under6: 1, afni: 300000);
    expect(r.annualAmount, 0);
    expect(r.status, CcbStatus.zeroByIncome);
  });

  test('four-or-more child bucket uses the 23% / 9.5% rates', () {
    // base 4×6748 = 26992; base reduction 0.23×(81222−37487) + 0.095×(100000−81222).
    final r = run(age6to17: 4, afni: 100000);
    final expected = 26992 -
        (0.23 * (81222 - 37487) + 0.095 * (100000 - 81222));
    expect(r.annualAmount, closeTo(expected, 1e-6));
  });

  test('no children is notEligible', () {
    final r = run(under6: 0, age6to17: 0, afni: 40000);
    expect(r.status, CcbStatus.notEligible);
    expect(r.annualAmount, 0);
  });
}
