import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  final asOf = DateTime(2026, 6, 1);
  const pack = EmbeddedDataPack();

  OasResult run({int? birthYear = 1956, double income = 80000}) => oasRule(
        profile: MoneyProfile(birthYear: birthYear, annualIncome: income),
        asOf: asOf,
        dataPack: pack,
      );

  test('under 65 is notYetEligible', () {
    final r = run(birthYear: 1966); // age 60 in 2026
    expect(r.status, OasStatus.notYetEligible);
    expect(r.clawbackAnnual, 0);
  });

  test('income below the threshold keeps full OAS (safe)', () {
    final r = run(income: 80000); // < 93,454
    expect(r.status, OasStatus.safe);
    expect(r.clawbackAnnual, 0);
  });

  test('income just below the threshold is approaching', () {
    final r = run(income: 90000); // within $10k below 93,454
    expect(r.status, OasStatus.approaching);
    expect(r.clawbackAnnual, 0);
  });

  test('income above the threshold is clawed back at 15%', () {
    final r = run(income: 120000); // 0.15 * (120000 - 93454)
    expect(r.status, OasStatus.clawback);
    expect(r.clawbackAnnual, closeTo(0.15 * (120000 - 93454), 1e-6));
  });

  test('clawback is capped at the max OAS (65–74 band)', () {
    final r = run(income: 300000);
    final maxOas = 0.15 * (151668 - 93454);
    expect(r.clawbackAnnual, closeTo(maxOas, 1e-6));
  });

  test('75+ uses the higher upper threshold for the cap', () {
    final r = run(birthYear: 1950, income: 300000); // age 76
    final maxOas = 0.15 * (157490 - 93454);
    expect(r.clawbackAnnual, closeTo(maxOas, 1e-6));
  });
}
