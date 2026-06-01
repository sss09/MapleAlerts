import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/features/reminders/domain/recurrence.dart';

void main() {
  group('Recurrence', () {
    test('defaults interval to 1', () {
      const r = Recurrence(frequency: RecurrenceFrequency.annual);
      expect(r.interval, 1);
    });

    test('round-trips through json', () {
      const r = Recurrence(frequency: RecurrenceFrequency.monthly, interval: 2);
      final json = r.toJson();
      expect(json, {'frequency': 'monthly', 'interval': 2});
      final back = Recurrence.fromJson(json);
      expect(back.frequency, RecurrenceFrequency.monthly);
      expect(back.interval, 2);
    });

    test('fromJson defaults missing interval to 1', () {
      final back = Recurrence.fromJson({'frequency': 'annual'});
      expect(back.interval, 1);
    });

    test('fromJson falls back to annual for unknown frequency', () {
      final back = Recurrence.fromJson({'frequency': 'weekly'});
      expect(back.frequency, RecurrenceFrequency.annual);
    });
  });
}
