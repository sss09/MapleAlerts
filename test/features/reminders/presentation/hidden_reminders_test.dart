import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:maple_alerts/features/reminders/presentation/hidden_reminders_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('markDone → isHidden(id, now) == true', () async {
    final notifier = HiddenRemindersNotifier();
    // Allow _load() to complete
    await Future<void>.delayed(Duration.zero);

    await notifier.markDone('rrsp');

    final now = DateTime.now();
    expect(notifier.isHidden('rrsp', now), isTrue);
  });

  test('snooze → hidden now, not hidden in 8 days', () async {
    final notifier = HiddenRemindersNotifier();
    await Future<void>.delayed(Duration.zero);

    await notifier.snooze('ccb');

    final now = DateTime.now();
    expect(notifier.isHidden('ccb', now), isTrue);
    expect(
      notifier.isHidden('ccb', now.add(const Duration(days: 8))),
      isFalse,
    );
  });

  test('unknown id → isHidden == false', () async {
    final notifier = HiddenRemindersNotifier();
    await Future<void>.delayed(Duration.zero);

    expect(notifier.isHidden('nobody', DateTime.now()), isFalse);
  });
}
