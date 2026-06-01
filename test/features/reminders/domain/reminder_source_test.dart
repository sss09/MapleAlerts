import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/features/reminders/domain/reminder_source.dart';

void main() {
  group('ReminderSource', () {
    test('value returns the enum name', () {
      expect(ReminderSource.system.value, 'system');
      expect(ReminderSource.user.value, 'user');
      expect(ReminderSource.derived.value, 'derived');
    });

    test('fromValue parses known values', () {
      expect(ReminderSourceX.fromValue('system'), ReminderSource.system);
      expect(ReminderSourceX.fromValue('user'), ReminderSource.user);
      expect(ReminderSourceX.fromValue('derived'), ReminderSource.derived);
    });

    test('fromValue falls back to user for unknown values', () {
      expect(ReminderSourceX.fromValue('garbage'), ReminderSource.user);
    });
  });
}
