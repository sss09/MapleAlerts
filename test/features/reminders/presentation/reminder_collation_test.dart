import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/models/alert.dart';
import 'package:maple_alerts/features/reminders/presentation/reminder_collation.dart';

// Helper to build a minimal Alert quickly.
Alert _alert({
  required String id,
  required AlertType type,
  required DateTime deadline,
}) =>
    Alert(
      id: id,
      title: id,
      description: '',
      type: type,
      deadline: deadline,
    );

void main() {
  // Anchor "now" so tests are deterministic.
  final now = DateTime(2026, 6, 1);

  group('collapseRecurringSeries', () {
    test(
        'keeps only the earliest future CCB and earliest future BoC; '
        'passes RRSP and custom through unchanged', () {
      final alerts = [
        // CCB — three future months; June is earliest
        _alert(
            id: 'ccb_jun',
            type: AlertType.ccb,
            deadline: DateTime(2026, 6, 20)),
        _alert(
            id: 'ccb_jul',
            type: AlertType.ccb,
            deadline: DateTime(2026, 7, 20)),
        _alert(
            id: 'ccb_aug',
            type: AlertType.ccb,
            deadline: DateTime(2026, 8, 20)),
        // BoC — two future dates; July is earliest
        _alert(
            id: 'boc_jul',
            type: AlertType.boc,
            deadline: DateTime(2026, 7, 30)),
        _alert(
            id: 'boc_sep',
            type: AlertType.boc,
            deadline: DateTime(2026, 9, 4)),
        // Non-recurring — pass through
        _alert(
            id: 'rrsp',
            type: AlertType.rrsp,
            deadline: DateTime(2027, 3, 1)),
        _alert(
            id: 'custom',
            type: AlertType.custom,
            deadline: DateTime(2026, 8, 15)),
      ];

      final result = collapseRecurringSeries(alerts, now);

      // Exactly 4 items: 1 CCB + 1 BoC + RRSP + custom.
      expect(result.length, 4);

      final ids = result.map((a) => a.id).toList();
      // The survivors must be the earliest future ones.
      expect(ids.contains('ccb_jun'), isTrue);
      expect(ids.contains('boc_jul'), isTrue);
      expect(ids.contains('rrsp'), isTrue);
      expect(ids.contains('custom'), isTrue);

      // No other CCB / BoC entries.
      expect(ids.contains('ccb_jul'), isFalse);
      expect(ids.contains('ccb_aug'), isFalse);
      expect(ids.contains('boc_sep'), isFalse);
    });

    test('past-only recurring series is dropped entirely', () {
      final alerts = [
        // All CCB entries in the past.
        _alert(
            id: 'ccb_apr',
            type: AlertType.ccb,
            deadline: DateTime(2026, 4, 20)),
        _alert(
            id: 'ccb_may',
            type: AlertType.ccb,
            deadline: DateTime(2026, 5, 20)),
        // A future custom to verify pass-through still works.
        _alert(
            id: 'custom',
            type: AlertType.custom,
            deadline: DateTime(2026, 9, 1)),
      ];

      final result = collapseRecurringSeries(alerts, now);

      expect(result.length, 1);
      expect(result.first.id, 'custom');
    });

    test('non-recurring alerts always pass through unchanged', () {
      final alerts = [
        _alert(
            id: 'rrsp',
            type: AlertType.rrsp,
            deadline: DateTime(2027, 3, 1)),
        _alert(
            id: 'tfsa',
            type: AlertType.tfsa,
            deadline: DateTime(2026, 12, 31)),
        _alert(
            id: 'custom',
            type: AlertType.custom,
            deadline: DateTime(2026, 7, 4)),
      ];

      final result = collapseRecurringSeries(alerts, now);

      expect(result.length, 3);
      final ids = result.map((a) => a.id).toList();
      expect(ids, containsAll(['rrsp', 'tfsa', 'custom']));
    });

    test('today deadline is NOT considered past — included as survivor', () {
      final alerts = [
        _alert(
            id: 'ccb_today',
            type: AlertType.ccb,
            deadline: now), // exactly today
        _alert(
            id: 'ccb_next',
            type: AlertType.ccb,
            deadline: DateTime(2026, 7, 20)),
      ];

      final result = collapseRecurringSeries(alerts, now);

      // today is earliest → it should be the survivor
      expect(result.length, 1);
      expect(result.first.id, 'ccb_today');
    });
  });
}
