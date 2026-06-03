import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/models/alert.dart';
import 'package:maple_alerts/providers/alerts_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('addCustom keeps the alert in memory when SQLite is unavailable',
      () async {
    // In tests (like on web) sqflite is not initialised — insertAlert throws.
    // The added reminder must still appear in state for the session instead
    // of silently vanishing (user-reported: added reminder never showed).
    SharedPreferences.setMockInitialValues({});
    final notifier = AlertsNotifier();
    // Let the initial _load (which degrades to built-ins) settle.
    await Future<void>.delayed(Duration.zero);

    final custom = Alert(
      id: 'custom-1',
      title: 'Renew my passport',
      description: '',
      type: AlertType.custom,
      deadline: DateTime.now().add(const Duration(days: 30)),
      metadata: const {'category': 'government'},
    );

    await notifier.addCustom(custom);

    final alerts = notifier.state.value ?? [];
    expect(alerts.any((a) => a.id == 'custom-1'), isTrue,
        reason: 'unsaved custom reminder must survive the reload');
    // And it survives a subsequent refresh too.
    await notifier.refresh();
    expect((notifier.state.value ?? []).any((a) => a.id == 'custom-1'), isTrue);
  });
}
