// test/features/reminders/domain/reminder_schedule_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/features/reminders/domain/recurrence.dart';
import 'package:maple_alerts/features/reminders/domain/reminder_schedule.dart';

void main() {
  group('OneTimeSchedule', () {
    test('returns the date when it is in the future', () {
      final s = OneTimeSchedule(DateTime(2026, 3, 1));
      expect(s.nextOccurrenceAfter(DateTime(2026, 1, 1)), DateTime(2026, 3, 1));
    });

    test('returns null when the date is in the past', () {
      final s = OneTimeSchedule(DateTime(2026, 3, 1));
      expect(s.nextOccurrenceAfter(DateTime(2026, 4, 1)), isNull);
    });

    test('round-trips through json', () {
      final s = OneTimeSchedule(DateTime(2026, 3, 1));
      final back = ReminderSchedule.fromJson(s.toJson());
      expect(back, isA<OneTimeSchedule>());
      expect((back as OneTimeSchedule).date, DateTime(2026, 3, 1));
    });
  });

  group('RecurringSchedule (annual)', () {
    final annual = RecurringSchedule(
      rule: const Recurrence(frequency: RecurrenceFrequency.annual),
      anchor: DateTime(2020, 3, 1),
    );

    test('returns this year occurrence when still upcoming', () {
      expect(annual.nextOccurrenceAfter(DateTime(2026, 1, 15)),
          DateTime(2026, 3, 1));
    });

    test('rolls to next year when this year has passed', () {
      expect(annual.nextOccurrenceAfter(DateTime(2026, 6, 1)),
          DateTime(2027, 3, 1));
    });

    test('respects until bound', () {
      final bounded = RecurringSchedule(
        rule: const Recurrence(frequency: RecurrenceFrequency.annual),
        anchor: DateTime(2020, 3, 1),
        until: DateTime(2026, 12, 31),
      );
      expect(bounded.nextOccurrenceAfter(DateTime(2027, 1, 1)), isNull);
    });
  });

  group('RecurringSchedule (monthly)', () {
    final monthly = RecurringSchedule(
      rule: const Recurrence(frequency: RecurrenceFrequency.monthly),
      anchor: DateTime(2024, 1, 20),
    );

    test('returns this month occurrence when still upcoming', () {
      expect(monthly.nextOccurrenceAfter(DateTime(2026, 5, 1)),
          DateTime(2026, 5, 20));
    });

    test('rolls to next month when this month has passed', () {
      expect(monthly.nextOccurrenceAfter(DateTime(2026, 5, 25)),
          DateTime(2026, 6, 20));
    });

    test('rolls across year boundary from December', () {
      expect(monthly.nextOccurrenceAfter(DateTime(2026, 12, 25)),
          DateTime(2027, 1, 20));
    });

    test('clamps day to last day of short months', () {
      final endOfMonth = RecurringSchedule(
        rule: const Recurrence(frequency: RecurrenceFrequency.monthly),
        anchor: DateTime(2024, 1, 31),
      );
      expect(endOfMonth.nextOccurrenceAfter(DateTime(2026, 2, 1)),
          DateTime(2026, 2, 28));
    });

    test('round-trips through json', () {
      final back = ReminderSchedule.fromJson(monthly.toJson());
      expect(back, isA<RecurringSchedule>());
      final r = back as RecurringSchedule;
      expect(r.rule.frequency, RecurrenceFrequency.monthly);
      expect(r.anchor, DateTime(2024, 1, 20));
    });
  });
}
