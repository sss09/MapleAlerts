import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/features/reminders/domain/reminder_category.dart';

void main() {
  group('ReminderCategory registry (life-domains)', () {
    const ids = ['government','bills','vehicle','health','finance','home','family','seasonal','custom'];

    test('contains the 8 life-domains plus custom', () {
      for (final id in ids) {
        expect(kReminderCategories.containsKey(id), isTrue, reason: 'missing $id');
      }
    });

    test('every map key equals its category id', () {
      for (final e in kReminderCategories.entries) {
        expect(e.value.id, e.key, reason: 'id mismatch for ${e.key}');
      }
    });

    test('categoryFor falls back to custom for unknown id', () {
      expect(categoryFor('nope').id, 'custom');
    });

    test('finance has a label and a non-zero tint', () {
      final fin = kReminderCategories['finance']!;
      expect(fin.label, 'Finance');
      expect(fin.color.toARGB32(), isNot(0));
    });
  });
}
