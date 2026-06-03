import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/providers/subscription_provider.dart';
import 'package:maple_alerts/screens/paywall/paywall_screen.dart';
import '../../helpers/analytics_spy.dart';

void main() {
  testWidgets('PaywallScreen renders Aurora layout with key elements',
      (tester) async {
    final spy = AnalyticsSpy();

    // Override subscriptionProvider so it emits AsyncData(false) immediately,
    // bypassing RevenueCat which is unavailable in tests.
    final container = ProviderContainer(overrides: [
      subscriptionProvider.overrideWith(
        (ref) => _StubSubscription(false),
      ),
      spy.override,
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: mapleThemeData(DesignTheme.fog),
          home: const PaywallScreen(),
        ),
      ),
    );

    // AuroraBackground runs an infinite animation — use a single pump instead
    // of pumpAndSettle to avoid a test hang.
    await tester.pump(const Duration(milliseconds: 50));

    // Pricing is visible
    expect(find.textContaining('4.99'), findsWidgets);

    // Restore purchases button is present
    expect(find.text('Restore purchases'), findsOneWidget);

    // Primary trial CTA is rendered
    expect(find.text('Start 14-day free trial'), findsOneWidget);

    // MAPLEALERTS+ badge is visible
    expect(find.text('MAPLEALERTS+'), findsOneWidget);

    // Analytics: paywall_viewed fired with source=profile
    expect(spy.propsOf('paywall_viewed'), {'source': 'profile'});
  });
}

/// Stub that immediately sets state to [AsyncValue.data(premium)] so tests
/// never reach RevenueCat.  Mirrors the pattern in profile_screen_v2_test.dart.
class _StubSubscription extends SubscriptionNotifier {
  _StubSubscription(bool premium) {
    state = AsyncValue.data(premium);
  }
}
