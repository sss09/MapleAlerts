import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/services/notification_service.dart';

void main() {
  group('reminderFireDate', () {
    final now = DateTime(2026, 6, 2, 14); // 2pm

    test('far-off deadline fires 7 days before at 9am', () {
      final fire = reminderFireDate(DateTime(2026, 7, 1), now);
      expect(fire, DateTime(2026, 6, 24, 9));
    });

    test('within 7 days falls back to the day before at 9am', () {
      // Deadline in 5 days — 7-days-before is in the past, so day-before.
      final fire = reminderFireDate(DateTime(2026, 6, 7), now);
      expect(fire, DateTime(2026, 6, 6, 9));
    });

    test('deadline tomorrow → day-before 9am is today 9am (already past) → '
        'fires shortly from now instead of being dropped', () {
      // now is 2pm today; deadline tomorrow. Day-before-9am = today 9am (past).
      final fire = reminderFireDate(DateTime(2026, 6, 3), now);
      expect(fire, isNotNull);
      expect(fire!.isAfter(now), isTrue);
    });

    test('deadline today (later) fires a few minutes from now', () {
      final fire = reminderFireDate(DateTime(2026, 6, 2, 20), now);
      expect(fire, isNotNull);
      expect(fire!.isAfter(now), isTrue);
      expect(fire.isBefore(DateTime(2026, 6, 2, 20)), isTrue);
    });

    test('deadline already in the past returns null (nothing to schedule)', () {
      expect(reminderFireDate(DateTime(2026, 6, 1), now), isNull);
    });

    test('prefers the EARLIEST sensible lead that is still in the future', () {
      // 9 days out: 7-day lead is still ahead → use it, not a later fallback.
      final fire = reminderFireDate(DateTime(2026, 6, 11), now);
      expect(fire, DateTime(2026, 6, 4, 9));
    });
  });
}
