import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/providers/settings_provider.dart';
import 'package:maple_alerts/screens/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('OnboardingScreen renders first page title and controls',
      (tester) async {
    // Stub the settings notifier so it never calls SharedPreferences.
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith((ref) => _StubSettings()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: mapleThemeData(DesignTheme.fog),
          home: const OnboardingScreen(),
        ),
      ),
    );

    // Pump once to let AnimationController tick (AuroraBackground uses
    // an infinite controller — do NOT call pumpAndSettle).
    await tester.pump(const Duration(milliseconds: 16));

    // First-page title is visible.
    expect(find.text('Welcome to MapleAlerts'), findsOneWidget);

    // 'Skip' TextButton is visible on page 0 (not the last page).
    expect(find.text('Skip'), findsOneWidget);

    // Primary CTA reads 'Next' on the first page.
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('topics page fits a short viewport without overflow (scrolls)',
      (tester) async {
    // Short phone-landscape-ish viewport — 6 topic cards cannot all fit, so
    // the page must scroll rather than overflow.
    tester.view.physicalSize = const Size(1320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith((ref) => _StubSettings()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: mapleThemeData(DesignTheme.fog),
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));

    // Advance to the last (topics) page. 3 info pages -> 3 taps on 'Next'.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'), warnIfMissed: true);
      await tester.pump(); // start the page animation
      await tester.pump(const Duration(milliseconds: 400)); // finish it
      await tester.pump(); // settle onPageChanged setState
    }

    expect(find.text('What should we track?'), findsOneWidget);
    // An overflowed RenderFlex reports through FlutterError.onError and the
    // test framework rethrows it at teardown — reaching here cleanly plus a
    // scrollable present is the regression guard.
    expect(
      find.descendant(
        of: find.byType(PageView),
        matching: find.byType(Scrollable),
      ),
      findsWidgets,
    );
  });
}

/// Stub [SettingsNotifier] that starts with a known [SettingsState] without
/// hitting [SharedPreferences] — mirrors the pattern used in home_screen_v2_test.
class _StubSettings extends SettingsNotifier {
  _StubSettings() : super() {
    // Override state immediately so the async _load() result is irrelevant.
    state = const SettingsState(onboardingDone: false);
  }

  @override
  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingDone: true);
  }
}
