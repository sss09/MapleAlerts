import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/providers/subscription_provider.dart';
import 'package:maple_alerts/features/reminders/presentation/screens/profile_screen_v2.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('You screen shows premium CTA + appearance tweaks', (t) async {
    // subscriptionProvider starts as AsyncLoading and calls RevenueCat which
    // fails in tests — override directly to AsyncData(false) so we see
    // the free-user CTA path immediately.
    final container = ProviderContainer(overrides: [
      subscriptionProvider.overrideWith(
        (ref) => _StubSubscription(false),
      ),
    ]);
    addTearDown(container.dispose);

    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: mapleThemeData(DesignTheme.fog),
        home: const Scaffold(body: ProfileScreenV2()),
      ),
    ));
    await t.pump(const Duration(milliseconds: 50));

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.textContaining('Teal Frost'), findsOneWidget); // aurora label
    expect(find.textContaining('14 days'), findsOneWidget);    // premium CTA (free state)
  });

  testWidgets('You screen shows Notifications section with toggle', (t) async {
    final container = ProviderContainer(overrides: [
      subscriptionProvider.overrideWith(
        (ref) => _StubSubscription(false),
      ),
    ]);
    addTearDown(container.dispose);

    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: mapleThemeData(DesignTheme.fog),
        home: const Scaffold(body: ProfileScreenV2()),
      ),
    ));
    await t.pump(const Duration(milliseconds: 50));

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Reminder notifications'), findsOneWidget);
  });
}

class _StubSubscription extends SubscriptionNotifier {
  _StubSubscription(bool premium) {
    state = AsyncValue.data(premium);
  }
}
