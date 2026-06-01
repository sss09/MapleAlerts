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

    test('copyWith overrides only specified fields', () {
      const c = NotificationConfig();
      final c2 = c.copyWith(enabled: false);
      expect(c2.enabled, isFalse);
      expect(c2.leadTimes, c.leadTimes);
      expect(c2.timeOfDay, c.timeOfDay);
    });

    test('fromJson with absent leadTimeMinutes falls back to default', () {
      final back = NotificationConfig.fromJson({'enabled': true});
      expect(back.leadTimes, const [Duration(days: 7), Duration(days: 1)]);
    });

    test('fromJson respects an explicitly empty leadTimeMinutes list', () {
      final back = NotificationConfig.fromJson({'leadTimeMinutes': []});
      expect(back.leadTimes, isEmpty);
    });
  });
}
