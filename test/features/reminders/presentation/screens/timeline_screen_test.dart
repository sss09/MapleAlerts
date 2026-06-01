import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/models/alert.dart';
import 'package:maple_alerts/providers/alerts_provider.dart';
import 'package:maple_alerts/features/reminders/presentation/screens/timeline_screen.dart';

void main() {
  testWidgets('TimelineScreen renders header + alert titles', (t) async {
    final now = DateTime.now();
    final sample = [
      Alert(
        id: 'rrsp-tl',
        title: 'RRSP top-up window',
        description: 'Contribute before the deadline',
        type: AlertType.rrsp,
        deadline: now.add(const Duration(days: 5)),
      ),
      Alert(
        id: 'boc-tl',
        title: 'BOC rate decision',
        description: 'Bank of Canada rate announcement',
        type: AlertType.boc,
        deadline: now.add(const Duration(days: 2)),
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
        home: const Scaffold(body: TimelineScreen()),
      ),
    ));

    // Drain microtasks — superclass _load() may set error; then force data.
    await t.pump();
    stub.forceData(sample);
    await t.pump(const Duration(milliseconds: 50));

    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('RRSP top-up window'), findsOneWidget);
  });
}

/// Stub notifier — mirrors the pattern in home_screen_v2_test.dart.
class _StubAlerts extends AlertsNotifier {
  _StubAlerts(List<Alert> initial) {
    state = AsyncData(initial);
  }

  void forceData(List<Alert> data) => state = AsyncData(data);
}
