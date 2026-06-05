import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/models/alert.dart';
import 'package:maple_alerts/features/reminders/presentation/alert_presentation.dart';

Alert _a(AlertType t, DateTime d) => Alert(id: 'x', title: 'T', description: 'D', type: t, deadline: d);

void main() {
  final now = DateTime(2026, 2, 24);
  group('AlertPresentation.map', () {
    test('maps RRSP to finance, CCB to family, custom to custom', () {
      expect(AlertPresentation.map(_a(AlertType.rrsp, DateTime(2026, 3, 1)), now).categoryId, 'finance');
      expect(AlertPresentation.map(_a(AlertType.ccb, DateTime(2026, 3, 1)), now).categoryId, 'family');
      expect(AlertPresentation.map(_a(AlertType.custom, DateTime(2026, 3, 1)), now).categoryId, 'custom');
    });
    test('maps tax to finance', () {
      expect(AlertPresentation.map(_a(AlertType.tax, DateTime(2026, 4, 30)), now).categoryId, 'finance');
    });
    test('section: today / this week / upcoming', () {
      expect(AlertPresentation.map(_a(AlertType.tfsa, DateTime(2026, 2, 24)), now).section, 'Today');
      expect(AlertPresentation.map(_a(AlertType.tfsa, DateTime(2026, 2, 28)), now).section, 'This Week');
      expect(AlertPresentation.map(_a(AlertType.tfsa, DateTime(2026, 4, 1)), now).section, 'Upcoming');
    });
    test('status: due-soon urgent, far-off planning', () {
      expect(AlertPresentation.map(_a(AlertType.boc, DateTime(2026, 2, 25)), now).status, 'urgent');
      expect(AlertPresentation.map(_a(AlertType.mortgage, DateTime(2026, 6, 1)), now).status, 'planning');
    });
    test('whenLabel reads naturally', () {
      expect(AlertPresentation.map(_a(AlertType.tfsa, DateTime(2026, 2, 24)), now).whenLabel, 'Today');
      expect(AlertPresentation.map(_a(AlertType.tfsa, DateTime(2026, 2, 26)), now).whenLabel, 'In 2 days');
    });
    test('progress is 0..1 and higher when closer', () {
      final near = AlertPresentation.map(_a(AlertType.boc, DateTime(2026, 2, 25)), now).progress;
      final far  = AlertPresentation.map(_a(AlertType.mortgage, DateTime(2026, 6, 1)), now).progress;
      expect(near, inInclusiveRange(0, 1));
      expect(near, greaterThan(far));
    });
    test('custom alert reads its category from metadata', () {
      final a = Alert(id:'x', title:'T', description:'D', type: AlertType.custom, deadline: DateTime(2026,3,1), metadata: const {'category': 'vehicle'});
      expect(AlertPresentation.map(a, now).categoryId, 'vehicle');
    });
    test('amount comes from metadata when present', () {
      final a = Alert(id:'x', title:'T', description:'D', type: AlertType.gic, deadline: DateTime(2026,3,1), metadata: const {'amount': '\$3,200 room'});
      expect(AlertPresentation.map(a, now).amount, '\$3,200 room');
    });
  });
}
