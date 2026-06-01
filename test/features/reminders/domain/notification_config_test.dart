// test/features/reminders/domain/notification_config_test.dart
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/features/reminders/domain/notification_config.dart';

void main() {
  group('NotificationConfig', () {
    test('has sensible defaults', () {
      const c = NotificationConfig();
      expect(c.enabled, isTrue);
      expect(c.leadTimes, const [Duration(days: 7), Duration(days: 1)]);
      expect(c.timeOfDay, const TimeOfDay(hour: 9, minute: 0));
    });

    test('round-trips through json', () {
      const c = NotificationConfig(
        enabled: false,
        leadTimes: [Duration(days: 30), Duration(days: 1)],
        timeOfDay: TimeOfDay(hour: 8, minute: 30),
      );
      final back = NotificationConfig.fromJson(c.toJson());
      expect(back.enabled, isFalse);
      expect(back.leadTimes, const [Duration(days: 30), Duration(days: 1)]);
      expect(back.timeOfDay, const TimeOfDay(hour: 8, minute: 30));
    });
  });
}
