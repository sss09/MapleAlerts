import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/features/reminders/presentation/seasonal_events.dart';

void main() {
  group('upcomingSeasonalEvents', () {
    test('returns only future events within the window, soonest first', () {
      final now = DateTime(2026, 6, 1);
      final items = upcomingSeasonalEvents(now);
      final today = DateTime(2026, 6, 1);

      expect(items, isNotEmpty);
      for (final e in items) {
        expect(e.date.isBefore(today), isFalse, reason: '${e.title} is past');
        expect(e.date.difference(today).inDays, lessThanOrEqualTo(75));
      }
      for (var i = 1; i < items.length; i++) {
        expect(items[i].date.isBefore(items[i - 1].date), isFalse);
      }
    });

    test('does not show CRA Apr 30 in June (past this year)', () {
      final items = upcomingSeasonalEvents(DateTime(2026, 6, 1));
      expect(items.any((e) => e.title.contains('CRA')), isFalse);
    });

    test('shows the quarterly July events in early June', () {
      final items = upcomingSeasonalEvents(DateTime(2026, 6, 1));
      final titles = items.map((e) => e.title).toList();
      expect(titles, contains('Canada Carbon Rebate'));
      expect(titles, contains('GST/HST credit'));
    });

    test('all returned events resolve to a non-past date for any month', () {
      for (var month = 1; month <= 12; month++) {
        final now = DateTime(2026, month, 10);
        final today = DateTime(2026, month, 10);
        for (final e in upcomingSeasonalEvents(now)) {
          expect(e.date.isBefore(today), isFalse,
              reason: 'month $month produced past event ${e.title}');
        }
      }
    });
  });
}
