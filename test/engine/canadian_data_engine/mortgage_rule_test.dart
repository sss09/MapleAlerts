import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  final asOf = DateTime(2026, 6, 7);

  MortgageResult run({DateTime? renewal}) => mortgageRule(
        profile: MoneyProfile(mortgageRenewalDate: renewal),
        asOf: asOf,
      );

  test('no renewal date → none', () {
    expect(run().status, MortgageStatus.none);
  });

  test('renewal 60 days out → renewalSoon with day count', () {
    final r = run(renewal: asOf.add(const Duration(days: 60)));
    expect(r.status, MortgageStatus.renewalSoon);
    expect(r.daysToRenewal, 60);
  });

  test('renewal 15 days out → renewalUrgent', () {
    final r = run(renewal: asOf.add(const Duration(days: 15)));
    expect(r.status, MortgageStatus.renewalUrgent);
    expect(r.daysToRenewal, 15);
  });

  test('renewal past (negative days) → renewalUrgent', () {
    final r = run(renewal: asOf.subtract(const Duration(days: 5)));
    expect(r.status, MortgageStatus.renewalUrgent);
    expect(r.daysToRenewal, lessThan(0));
  });

  test('renewal exactly kMortgageUrgentDays out → renewalUrgent', () {
    final r = run(renewal: asOf.add(const Duration(days: kMortgageUrgentDays)));
    expect(r.status, MortgageStatus.renewalUrgent);
  });

  test('renewal one day past kMortgageUrgentDays → renewalSoon', () {
    final r =
        run(renewal: asOf.add(const Duration(days: kMortgageUrgentDays + 1)));
    expect(r.status, MortgageStatus.renewalSoon);
  });

  test('renewal beyond kMortgageSoonDays → renewalFar', () {
    final renewal = DateTime(2026, 12, 25); // well beyond 120 days from Jun 7
    final r = run(renewal: renewal);
    expect(r.status, MortgageStatus.renewalFar);
    expect(r.daysToRenewal, greaterThan(kMortgageSoonDays));
  });

  test('sources contain the formatted renewal date', () {
    final renewal = DateTime(2026, 9, 15);
    final r = run(renewal: renewal);
    expect(r.sources, isNotEmpty);
    expect(r.sources.first.value, '2026-09-15');
    expect(r.sources.first.source, 'Your input');
  });
}
