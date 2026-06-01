import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/models/alert.dart';
import 'package:maple_alerts/providers/alerts_provider.dart';
import 'package:maple_alerts/providers/subscription_provider.dart';
import 'package:maple_alerts/features/reminders/presentation/screens/maple_home_shell.dart';

void main() {
  final now = DateTime.now();
  final sampleAlerts = [
    Alert(
      id: 'test-1',
      title: 'RRSP deadline',
      description: 'Contribute before March 1',
      type: AlertType.rrsp,
      deadline: now.add(const Duration(days: 10)),
    ),
  ];

  /// Build the shell with stubbed providers.
  Widget buildShell() {
    return ProviderScope(
      overrides: [
        alertsProvider.overrideWith((ref) => _StubAlerts(sampleAlerts)),
        subscriptionProvider.overrideWith((_) => _StubSubscription(false)),
      ],
      child: MaterialApp(
        theme: mapleThemeData(DesignTheme.fog),
        home: const MapleHomeShell(),
      ),
    );
  }

  testWidgets('shell renders Home tab by default', (tester) async {
    await tester.pumpWidget(buildShell());
    // Single pump — aurora has infinite animations so never pumpAndSettle
    await tester.pump(const Duration(milliseconds: 50));

    // Home tab is active — tab bar shows all labels
    expect(find.text('Timeline'), findsWidgets);
    expect(find.text('Alerts'), findsWidgets);
    expect(find.text('You'), findsWidgets);
  });

  testWidgets('tapping Timeline tab shows timeline header', (tester) async {
    await tester.pumpWidget(buildShell());
    await tester.pump(const Duration(milliseconds: 50));

    // Tap the Timeline tab label in the bottom bar
    await tester.tap(find.text('Timeline').first);
    await tester.pump();

    // Pump enough to let the stub data settle (stub sets AsyncData immediately,
    // but superclass _load() may run first)
    await tester.pump(const Duration(milliseconds: 100));

    // TimelineScreen renders its "Timeline" header
    expect(find.text('Timeline'), findsWidgets);
  });

  testWidgets('tapping You tab shows Appearance section', (tester) async {
    await tester.pumpWidget(buildShell());
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('You').first);
    await tester.pump(const Duration(milliseconds: 100));

    // ProfileScreenV2 renders the Appearance section header
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('tapping Alerts tab shows calm notifications header',
      (tester) async {
    await tester.pumpWidget(buildShell());
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Alerts').first);
    await tester.pump(const Duration(milliseconds: 100));

    // AlertsScreenV2 renders "Calm notifications" header
    expect(find.text('Calm notifications'), findsOneWidget);
  });
}

// ── Stub providers ────────────────────────────────────────────────────────────

class _StubAlerts extends AlertsNotifier {
  _StubAlerts(List<Alert> data) {
    state = AsyncData(data);
  }

  void forceData(List<Alert> data) => state = AsyncData(data);
}

class _StubSubscription extends SubscriptionNotifier {
  _StubSubscription(bool premium) {
    state = AsyncValue.data(premium);
  }
}
