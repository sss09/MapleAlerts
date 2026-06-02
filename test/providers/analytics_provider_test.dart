import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maple_alerts/providers/analytics_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('analyticsEnabledProvider defaults to true', () {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(analyticsEnabledProvider), isTrue);
  });

  test('setEnabled(false) flips state and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(analyticsEnabledProvider.notifier).setEnabled(false);
    expect(container.read(analyticsEnabledProvider), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kAnalyticsEnabledKey), isFalse);
  });

  test('analyticsProvider service respects the live kill switch', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final svc = container.read(analyticsProvider);
    expect(svc.isEnabled(), isTrue);
    await container.read(analyticsEnabledProvider.notifier).setEnabled(false);
    // Same service instance (session de-dupe survives), fresh switch read.
    expect(identical(svc, container.read(analyticsProvider)), isTrue);
    expect(svc.isEnabled(), isFalse);
  });
}
