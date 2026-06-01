import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/features/reminders/domain/reminder_category.dart';

void main() {
  group('ReminderCategory registry', () {
    test('contains the 8 MVP categories plus custom', () {
      for (final id in ['rrsp', 'tfsa', 'tax', 'boc', 'ccb', 'gic', 'mortgage', 'osap', 'custom']) {
        expect(kReminderCategories.containsKey(id), isTrue, reason: 'missing $id');
      }
    });

    test('free categories are not premium by default', () {
      for (final id in ['rrsp', 'tfsa', 'tax', 'boc', 'ccb', 'custom']) {
        expect(kReminderCategories[id]!.premiumByDefault, isFalse, reason: '$id should be free');
      }
    });

    test('tracker categories are premium by default', () {
      for (final id in ['gic', 'mortgage', 'osap']) {
        expect(kReminderCategories[id]!.premiumByDefault, isTrue, reason: '$id should be premium');
      }
    });

    test('categoryFor returns the category for a known id', () {
      expect(categoryFor('rrsp').id, 'rrsp');
    });

    test('categoryFor falls back to custom for unknown id', () {
      expect(categoryFor('does-not-exist').id, 'custom');
    });

    test('every map key equals its category id', () {
      for (final entry in kReminderCategories.entries) {
        expect(entry.value.id, entry.key,
            reason: 'id mismatch for key ${entry.key}');
      }
    });

    test('custom category exists (categoryFor fallback invariant)', () {
      expect(kReminderCategories.containsKey('custom'), isTrue);
    });
  });
}
