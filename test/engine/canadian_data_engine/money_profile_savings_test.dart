import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  group('MoneyProfile.savingsBalance', () {
    test('copyWith sets savingsBalance and preserves other fields', () {
      const original = MoneyProfile(birthYear: 1990, tfsaContributed: 5000);
      final updated = original.copyWith(savingsBalance: 25000);

      expect(updated.savingsBalance, 25000);
      expect(updated.birthYear, 1990);
      expect(updated.tfsaContributed, 5000);
    });

    test('copyWith clearSavingsBalance=true sets it to null', () {
      const original = MoneyProfile(savingsBalance: 10000, birthYear: 1985);
      final cleared = original.copyWith(clearSavingsBalance: true);

      expect(cleared.savingsBalance, isNull);
      expect(cleared.birthYear, 1985);
    });

    test('copyWith without args preserves existing savingsBalance', () {
      const original = MoneyProfile(savingsBalance: 8000);
      final copy = original.copyWith(birthYear: 1990);

      expect(copy.savingsBalance, 8000);
      expect(copy.birthYear, 1990);
    });

    test('toJson includes savingsBalance when set', () {
      const profile = MoneyProfile(savingsBalance: 15000);
      final json = profile.toJson();

      expect(json['savingsBalance'], 15000);
    });

    test('toJson omits savingsBalance when null', () {
      const profile = MoneyProfile(birthYear: 1990);
      final json = profile.toJson();

      expect(json.containsKey('savingsBalance'), isFalse);
    });

    test('fromJson round-trips savingsBalance', () {
      const original = MoneyProfile(savingsBalance: 42000, birthYear: 1988);
      final json = original.toJson();
      final restored = MoneyProfile.fromJson(json);

      expect(restored.savingsBalance, 42000);
      expect(restored.birthYear, 1988);
    });

    test('fromJson treats absent key as null', () {
      final profile = MoneyProfile.fromJson({'birthYear': 1980});
      expect(profile.savingsBalance, isNull);
    });

    test('fromJson treats null value as null', () {
      final profile = MoneyProfile.fromJson({'savingsBalance': null});
      expect(profile.savingsBalance, isNull);
    });

    test('equality respects savingsBalance', () {
      const a = MoneyProfile(savingsBalance: 10000);
      const b = MoneyProfile(savingsBalance: 10000);
      const c = MoneyProfile(savingsBalance: 20000);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode respects savingsBalance', () {
      const a = MoneyProfile(savingsBalance: 10000);
      const b = MoneyProfile(savingsBalance: 10000);
      const c = MoneyProfile(savingsBalance: 20000);

      expect(a.hashCode, equals(b.hashCode));
      expect(a.hashCode, isNot(equals(c.hashCode)));
    });
  });
}
