import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/models/alert.dart';
import 'package:maple_alerts/providers/alerts_provider.dart';
import 'package:maple_alerts/features/reminders/presentation/screens/home_screen_v2.dart';

void main() {
  testWidgets('Home renders hero + a reminder from alertsProvider', (t) async {
    final sample = [
      Alert(
        id: 'rrsp',
        title: 'RRSP deadline',
        description: 'Contribute before March 1',
        type: AlertType.rrsp,
        deadline: DateTime.now().add(const Duration(days: 5)),
      ),
      Alert(
        id: 'ccb',
        title: 'CCB payment',
        description: 'Child benefit deposit',
        type: AlertType.ccb,
        deadline: DateTime.now().add(const Duration(days: 1)),
      ),
    ];

    // Keep a reference to the stub so we can reset state after _load() errors.
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
        home: const Scaffold(body: HomeScreenV2()),
      ),
    ));

    // Drain pending microtasks so the superclass _load() can finish (it will
    // set state to AsyncError because sqflite is not initialised in tests).
    await t.pump();

    // Force state back to our data and trigger a rebuild.
    stub.forceData(sample);
    await t.pump();

    expect(find.text('YOUR DAY, HANDLED'), findsOneWidget);
    expect(find.text('RRSP deadline'), findsOneWidget);
  });
}

/// Stub notifier that extends [AlertsNotifier] (required by
/// [StateNotifierProvider.overrideWith]) and exposes [forceData] to reset
/// state after the superclass [_load] has written an error.
class _StubAlerts extends AlertsNotifier {
  _StubAlerts(List<Alert> initial) {
    state = AsyncData(initial);
  }

  void forceData(List<Alert> data) => state = AsyncData(data);
}
