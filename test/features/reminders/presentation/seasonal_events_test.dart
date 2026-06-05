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

    test('shows the quarterly July GST/HST event in early June', () {
      final items = upcomingSeasonalEvents(DateTime(2026, 6, 1));
      final titles = items.map((e) => e.title).toList();
      expect(titles, contains('GST/HST credit'));
    });

    test('never shows the discontinued Canada Carbon Rebate', () {
      // CCR for individuals ended (final payment Apr 2025); showing it would
      // surface money that no longer exists. Check across the whole year.
      for (var month = 1; month <= 12; month++) {
        final items = upcomingSeasonalEvents(DateTime(2026, month, 10),
            withinDays: 400, max: 50);
        expect(items.any((e) => e.title.contains('Carbon')), isFalse,
            reason: 'Carbon Rebate must not appear (month $month)');
      }
    });

    test('covers the added universal deadlines somewhere in the year', () {
      // Each should surface within its lead window at some point in the year.
      final seen = <String>{};
      for (var month = 1; month <= 12; month++) {
        for (final e in upcomingSeasonalEvents(DateTime(2026, month, 1),
            withinDays: 400, max: 50)) {
          seen.add(e.title);
        }
      }
      // 'CRA tax filing deadline' (Apr 30) and 'Self-employed tax filing'
      // (Jun 15) are now built-in AlertType.tax alerts; removed from rail.
      expect(seen, containsAll(<String>[
        'RESP contribution cutoff',
        'FHSA room opens',
        'Charitable donation cutoff',
        'Tax instalment due',
      ]));
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
