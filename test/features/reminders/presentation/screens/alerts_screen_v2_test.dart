import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/models/alert.dart';
import 'package:maple_alerts/providers/alerts_provider.dart';
import 'package:maple_alerts/features/reminders/presentation/screens/alerts_screen_v2.dart';

void main() {
  testWidgets('AlertsScreenV2 renders header + alert',
      (t) async {
    final now = DateTime.now();
    final sample = [
      Alert(
        id: 'rrsp-alerts',
        title: 'RRSP top-up window',
        description: 'Contribute before the March 1 deadline',
        type: AlertType.rrsp,
        deadline: now.add(const Duration(days: 5)),
      ),
    ];

    late _StubAlerts stub;

    final container = ProviderContainer(overrides: [
      alertsProvider.overrideWith((ref) {
        stub = _StubAlerts(sample);
        return stub;
      }),
    ]);
    addTearDown(container.dispose);

    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: mapleThemeData(DesignTheme.fog),
        home: const Scaffold(body: AlertsScreenV2()),
      ),
    ));

    // Drain microtasks — superclass _load() may error; then force data.
    await t.pump();
    stub.forceData(sample);
    await t.pump(const Duration(milliseconds: 50));

    expect(find.text('Calm notifications'), findsOneWidget);
    // Title appears in the header row
    expect(find.textContaining('RRSP top-up window'), findsWidgets);
  });
}

/// Stub notifier — mirrors the pattern in home_screen_v2_test.dart.
class _StubAlerts extends AlertsNotifier {
  _StubAlerts(List<Alert> initial) {
    state = AsyncData(initial);
  }

  void forceData(List<Alert> data) => state = AsyncData(data);
}
