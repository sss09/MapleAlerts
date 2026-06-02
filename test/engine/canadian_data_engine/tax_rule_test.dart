import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  const pack = EmbeddedDataPack();

  double rate(Province p, double income) => marginalTaxRate(
        year: 2025,
        province: p,
        income: income,
        dataPack: pack,
      );

  test(r'ON $80k → federal 20.5% + Ontario 9.15% = 29.65%', () {
    expect(rate(Province.on, 80000), closeTo(0.2965, 1e-9));
  });

  test(r'BC $40k → federal 14.5% + BC 5.06% = 19.56%', () {
    expect(rate(Province.bc, 40000), closeTo(0.1956, 1e-9));
  });

  test(r'AB $200k → federal 29% + Alberta 13% = 42%', () {
    expect(rate(Province.ab, 200000), closeTo(0.42, 1e-9));
  });

  test('income at a federal bracket boundary uses the higher bracket', () {
    // $57,375 is the start of the 20.5% federal bracket; ON is already at 9.15%.
    expect(rate(Province.on, 57375), closeTo(0.205 + 0.0915, 1e-9));
    // Just below stays in the lowest (14.5%) federal bracket; ON still 9.15%.
    expect(rate(Province.on, 57374), closeTo(0.145 + 0.0915, 1e-9));
  });

  test('zero income falls in the lowest brackets', () {
    expect(rate(Province.on, 0), closeTo(0.145 + 0.0505, 1e-9));
  });

  test('every province/territory has brackets and a positive top rate', () {
    for (final p in Province.values) {
      final brackets = pack.provincialBrackets(2025, p);
      expect(brackets, isNotEmpty, reason: '${p.code} has no brackets');
      expect(rate(p, 1000000), greaterThan(0.3),
          reason: '${p.code} top combined rate looks wrong');
    }
  });
}
