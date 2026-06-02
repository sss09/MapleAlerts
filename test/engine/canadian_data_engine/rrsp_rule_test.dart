import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  final asOf = DateTime(2026, 6, 1);
  const pack = EmbeddedDataPack();

  RrspResult run({
    Province? province = Province.on,
    double income = 80000,
    double limit = 50000,
    double contributed = 20000,
    int? birthYear = 1985,
  }) =>
      rrspRule(
        profile: MoneyProfile(
          birthYear: birthYear,
          province: province,
          annualIncome: income,
          rrspDeductionLimit: limit,
          rrspContributed: contributed,
        ),
        asOf: asOf,
        dataPack: pack,
      );

  group('room, rate, savings', () {
    test('healthy room with tax-savings at the combined marginal rate', () {
      final r = run(); // ON $80k, room 30000, rate 0.2965
      expect(r.room, 30000);
      expect(r.marginalRate, closeTo(0.2965, 1e-9));
      expect(r.estimatedTaxSavings, closeTo(30000 * 0.2965, 1e-6));
      expect(r.status, RrspStatus.healthy);
      expect(r.isEstimate, isTrue);
    });

    test('room just above the threshold is healthy', () {
      final r = run(limit: 10000, contributed: 8999); // room 1001
      expect(r.room, 1001);
      expect(r.status, RrspStatus.healthy);
    });

    test('room of 1000 or less is nearLimit', () {
      final r = run(limit: 10000, contributed: 9500); // room 500
      expect(r.status, RrspStatus.nearLimit);
    });
  });

  group(r'over-contribution guardrail ($2,000 buffer)', () {
    test('within the buffer is a caution, not an alert', () {
      final r = run(limit: 10000, contributed: 11500); // room -1500
      expect(r.room, -1500);
      expect(r.status, RrspStatus.withinBuffer);
    });

    test('past the buffer is overContributed', () {
      final r = run(limit: 10000, contributed: 13000); // 1000 past buffer
      expect(r.status, RrspStatus.overContributed);
    });
  });

  group('eligibility', () {
    test('over 71 is noLongerEligible regardless of room', () {
      final r = run(birthYear: 1950); // age 76 in 2026
      expect(r.status, RrspStatus.noLongerEligible);
    });
  });

  group('deadline', () {
    test('next deadline is the upcoming ~March 1 cutoff', () {
      final r = run();
      expect(r.nextDeadline.year, 2027);
      expect(r.nextDeadline.month, 3);
      expect(r.nextDeadline.day, 1);
      expect(r.daysToDeadline, greaterThan(0));
    });
  });

  group('sources', () {
    test('cites the NOA limit and the province/year for the rate', () {
      final r = run();
      expect(r.sources.any((s) => s.source.contains('NOA')), isTrue);
      expect(
        r.sources.any((s) => s.value.contains('%') || s.label.contains('rate')),
        isTrue,
      );
    });
  });
}
