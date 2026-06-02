# Anonymous Analytics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Anonymous, aggregate-only product analytics via Aptabase — 14 events, on-by-default with a Privacy toggle, zero PII, engine untouched.

**Architecture:** One thin `AnalyticsService` choke point (injectable sink for tests, kill-switch checked per call, session de-dupe for view events, denylist assert). Riverpod providers wire it; presentation-layer call sites emit events. Spec: `docs/superpowers/specs/2026-06-02-anonymous-analytics-design.md`.

**Tech Stack:** Flutter, Riverpod 2.x, `aptabase_flutter`, shared_preferences. App key: `A-US-2496453611` (public identifier, not a secret — fine in source).

**Conventions for this codebase:** run `flutter test <path>` and `flutter analyze`; tests never touch the network; prefs-backed providers follow `enabledTopicsProvider`'s pattern; widget tests follow `onboarding_screen_test.dart`'s stub-and-pump pattern; commit after every task.

---

### Task 1: Add the `aptabase_flutter` dependency

**Files:**
- Modify: `pubspec.yaml` (via pub)

- [ ] **Step 1: Add the package**

Run: `flutter pub add aptabase_flutter`
Expected: resolves and adds `aptabase_flutter: ^<latest>` to pubspec.

- [ ] **Step 2: Verify the SDK API surface**

Open the package README that pub prints (or `%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\aptabase_flutter-<ver>\README.md`). Confirm the two calls this plan assumes:
- `await Aptabase.init("A-US-2496453611");`
- `Aptabase.instance.trackEvent("event_name", {"key": "value"});`

If the signatures differ (e.g. an `InitOptions` argument), adapt Task 2's production sink and Task 4 accordingly — those are the only two places the SDK is touched.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add aptabase_flutter dependency"
```

---

### Task 2: `AnalyticsService` core (TDD)

**Files:**
- Create: `lib/core/analytics/analytics_service.dart`
- Test: `test/core/analytics/analytics_service_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/analytics/analytics_service.dart';

void main() {
  late List<(String, Map<String, Object>)> recorded;
  AnalyticsService make({bool enabled = true}) => AnalyticsService(
        sink: (e, p) => recorded.add((e, p)),
        isEnabled: () => enabled,
      );

  setUp(() => recorded = []);

  group('AnalyticsService.track', () {
    test('forwards event name and props to the sink', () {
      make().track('topic_enabled', {'topic': 'tfsa'});
      expect(recorded, [('topic_enabled', {'topic': 'tfsa'})]);
    });

    test('drops events when disabled', () {
      make(enabled: false).track('topic_enabled', {'topic': 'tfsa'});
      expect(recorded, isEmpty);
    });

    test('swallows sink exceptions (fire-and-forget)', () {
      final svc = AnalyticsService(
        sink: (_, __) => throw StateError('network down'),
        isEnabled: () => true,
      );
      expect(() => svc.track('paywall_viewed'), returnsNormally);
    });

    test('de-dupes insight_card_viewed per id per session', () {
      final svc = make();
      svc.track('insight_card_viewed', {'id': 'tfsa_room'});
      svc.track('insight_card_viewed', {'id': 'tfsa_room'});
      svc.track('insight_card_viewed', {'id': 'rrsp_room'});
      expect(recorded.length, 2);
    });

    test('de-dupes best_move_shown per kind+target per session', () {
      final svc = make();
      svc.track('best_move_shown', {'kind': 'opportunity', 'target': 'rrsp_room'});
      svc.track('best_move_shown', {'kind': 'opportunity', 'target': 'rrsp_room'});
      expect(recorded.length, 1);
    });

    test('does not de-dupe other events', () {
      final svc = make();
      svc.track('reminder_added', {'category': 'finance'});
      svc.track('reminder_added', {'category': 'finance'});
      expect(recorded.length, 2);
    });

    test('asserts on denylisted property names (debug-mode PII guard)', () {
      expect(() => make().track('bad_event', {'income': '90000'}),
          throwsAssertionError);
      expect(() => make().track('bad_event', {'amount': '5'}),
          throwsAssertionError);
    });
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/core/analytics/analytics_service_test.dart`
Expected: FAIL — `analytics_service.dart` does not exist.

- [ ] **Step 3: Implement the service**

```dart
import 'package:flutter/foundation.dart';

/// Where events go in production (Aptabase) or tests (a spy).
typedef AnalyticsSink = void Function(String event, Map<String, Object> props);

/// The single choke point for anonymous product analytics.
///
/// - Fire-and-forget: [track] never throws and never awaits — an analytics
///   failure must never affect the UX.
/// - Kill switch: [isEnabled] is read per call, so flipping the Privacy
///   toggle takes effect immediately without rebuilding the service.
/// - Session de-dupe: view-type events fire once per subject per app session
///   (widget rebuilds would otherwise swamp the signal).
/// - PII guard: property names are asserted against [kDeniedPropKeys] in
///   debug builds — the hard "never sent" contract from the spec.
class AnalyticsService {
  AnalyticsService({required AnalyticsSink sink, required this.isEnabled})
      : _sink = sink;

  final AnalyticsSink _sink;
  final bool Function() isEnabled;
  final Set<String> _seenViews = {};

  /// Property names that must never appear on any event — the spec's
  /// "never sent" denylist. Topic names and card ids only; never numbers,
  /// never identity, never location.
  @visibleForTesting
  static const Set<String> kDeniedPropKeys = {
    'amount', 'income', 'value', 'title', 'birthyear', 'birth_year',
    'province', 'kids', 'contributed', 'email', 'name',
  };

  /// Events de-duped once per subject per session, keyed by these props.
  static const Map<String, List<String>> _dedupeKeys = {
    'insight_card_viewed': ['id'],
    'best_move_shown': ['kind', 'target'],
  };

  void track(String event, [Map<String, Object> props = const {}]) {
    assert(
      props.keys.every((k) => !kDeniedPropKeys.contains(k.toLowerCase())),
      'Denylisted analytics property on "$event": ${props.keys}',
    );
    if (!isEnabled()) return;
    final dedupeBy = _dedupeKeys[event];
    if (dedupeBy != null) {
      final key = '$event|${dedupeBy.map((k) => props[k]).join('|')}';
      if (!_seenViews.add(key)) return;
    }
    try {
      _sink(event, props);
    } catch (_) {
      // Fire-and-forget: analytics must never break the app.
    }
  }
}
```

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/core/analytics/analytics_service_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/core/analytics/analytics_service.dart test/core/analytics/analytics_service_test.dart
git commit -m "feat: AnalyticsService — choke point with kill switch, de-dupe, PII guard"
```

---

### Task 3: Providers — kill switch + service wiring (TDD)

**Files:**
- Modify: `lib/utils/constants.dart` (add one key)
- Create: `lib/providers/analytics_provider.dart`
- Test: `test/providers/analytics_provider_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
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
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/providers/analytics_provider_test.dart`
Expected: FAIL — `analytics_provider.dart` does not exist.

- [ ] **Step 3: Implement**

In `lib/utils/constants.dart`, next to `kEnabledTopicsKey`, add:

```dart
/// Prefs key: anonymous analytics opt-out (bool, default true = sharing on).
const String kAnalyticsEnabledKey = 'analytics_enabled_v1';
```

Create `lib/providers/analytics_provider.dart`:

```dart
import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/analytics/analytics_service.dart';
import '../utils/constants.dart';

export '../utils/constants.dart' show kAnalyticsEnabledKey;

/// The "Share anonymous usage stats" Privacy toggle. Default ON; persisted.
/// Same prefs-backed StateNotifier pattern as [enabledTopicsProvider].
final analyticsEnabledProvider =
    StateNotifierProvider<AnalyticsEnabledNotifier, bool>(
        (ref) => AnalyticsEnabledNotifier());

class AnalyticsEnabledNotifier extends StateNotifier<bool> {
  AnalyticsEnabledNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(kAnalyticsEnabledKey) ?? true;
    } catch (_) {
      // Prefs unavailable (tests/web edge) — keep the default.
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kAnalyticsEnabledKey, enabled);
    } catch (_) {
      // Non-fatal; default applies next launch.
    }
  }
}

/// The app-wide [AnalyticsService]. One instance per container (session
/// de-dupe lives in it); the kill switch is read fresh on every track call.
final analyticsProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(
    sink: (event, props) => Aptabase.instance.trackEvent(event, props),
    isEnabled: () => ref.read(analyticsEnabledProvider),
  );
});
```

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/providers/analytics_provider_test.dart`
Expected: PASS, 3 tests. (The Aptabase sink is never invoked in tests — nothing calls `track` here, and later widget tests override `analyticsProvider` with a spy.)

- [ ] **Step 5: Commit**

```bash
git add lib/utils/constants.dart lib/providers/analytics_provider.dart test/providers/analytics_provider_test.dart
git commit -m "feat: analytics kill-switch provider + service wiring"
```

---

### Task 4: Init Aptabase in `main()`

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Add the init call**

In `lib/main.dart`, inside `main()` before `runApp`, add (adjusting to the verified SDK signature from Task 1):

```dart
// Anonymous analytics (Aptabase). The key is a public app identifier.
// Failure must never block boot — offline/blocked is fine.
try {
  await Aptabase.init('A-US-2496453611');
} catch (_) {
  // App works fully without analytics.
}
```

with import `package:aptabase_flutter/aptabase_flutter.dart`. Ensure `WidgetsFlutterBinding.ensureInitialized()` is called before it (add if `main` doesn't already).

- [ ] **Step 2: Verify boot on web**

Run: `flutter run -d chrome --web-port 8088`
Expected: app boots to onboarding/home with no exception in console. (No events sent yet — call sites come next.)

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: init Aptabase analytics at boot (fail-soft)"
```

---

### Task 5: Onboarding funnel events (TDD)

**Files:**
- Modify: `lib/screens/onboarding/onboarding_screen.dart`
- Create: `test/helpers/analytics_spy.dart`
- Test: `test/screens/onboarding/onboarding_screen_test.dart` (extend)

- [ ] **Step 1: Create the shared spy helper**

`test/helpers/analytics_spy.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maple_alerts/core/analytics/analytics_service.dart';
import 'package:maple_alerts/providers/analytics_provider.dart';

/// Spy used by widget tests: records every event, never touches the network.
class AnalyticsSpy {
  final List<(String, Map<String, Object>)> events = [];

  late final AnalyticsService service = AnalyticsService(
    sink: (e, p) => events.add((e, p)),
    isEnabled: () => true,
  );

  Override get override => analyticsProvider.overrideWithValue(service);

  bool fired(String event) => events.any((r) => r.$1 == event);
  Map<String, Object>? propsOf(String event) =>
      events.where((r) => r.$1 == event).map((r) => r.$2).firstOrNull;
}
```

- [ ] **Step 2: Write the failing widget test**

Append to `test/screens/onboarding/onboarding_screen_test.dart` (reuse the existing `_StubSettings` and pump pattern; add `import '../../helpers/analytics_spy.dart';`):

```dart
testWidgets('emits funnel events: page views, then complete with topics',
    (tester) async {
  final spy = AnalyticsSpy();
  final container = ProviderContainer(overrides: [
    settingsProvider.overrideWith((ref) => _StubSettings()),
    spy.override,
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

  // 3 info pages -> 3 taps lands on the topics page.
  for (var i = 0; i < 3; i++) {
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }
  await tester.tap(find.text('Get Started'));
  await tester.pump();

  expect(spy.fired('onboarding_page_view'), isTrue);
  final complete = spy.propsOf('onboarding_complete');
  expect(complete, isNotNull);
  // Defaults: TFSA + RRSP enabled.
  expect(complete!['topics_enabled'], contains('tfsa'));
  expect(spy.fired('onboarding_skip'), isFalse);
});

testWidgets('skip emits onboarding_skip with the page index', (tester) async {
  final spy = AnalyticsSpy();
  final container = ProviderContainer(overrides: [
    settingsProvider.overrideWith((ref) => _StubSettings()),
    spy.override,
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

  await tester.tap(find.text('Skip'));
  await tester.pump();

  expect(spy.propsOf('onboarding_skip'), {'at_page': '0'});
});
```

- [ ] **Step 3: Run to verify failure**

Run: `flutter test test/screens/onboarding/onboarding_screen_test.dart`
Expected: FAIL — no events emitted.

- [ ] **Step 4: Instrument the screen**

In `lib/screens/onboarding/onboarding_screen.dart` (a `ConsumerStatefulWidget` — `ref` is available):

Add imports:

```dart
import '../../providers/analytics_provider.dart';
import '../../providers/enabled_topics_provider.dart';   // already imported
```

In `_OnboardingScreenState`:

```dart
Future<void> _complete() async {
  await ref.read(settingsProvider.notifier).completeOnboarding();
  if (mounted) context.go('/');
}

void _skip() {
  ref.read(analyticsProvider).track('onboarding_skip', {'at_page': '$_currentPage'});
  _complete();
}

void _finish() {
  final topics = ref.read(enabledTopicsProvider).map((t) => t.name).toList()..sort();
  ref.read(analyticsProvider)
      .track('onboarding_complete', {'topics_enabled': topics.join(',')});
  _complete();
}

void _nextPage() {
  if (_currentPage < _pageCount - 1) {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  } else {
    _finish();
  }
}
```

Change the Skip button's `onPressed: _complete` to `onPressed: _skip`.

In `onPageChanged`:

```dart
onPageChanged: (i) {
  ref.read(analyticsProvider).track('onboarding_page_view', {'index': '$i'});
  setState(() => _currentPage = i);
},
```

- [ ] **Step 5: Run to verify pass**

Run: `flutter test test/screens/onboarding/onboarding_screen_test.dart`
Expected: PASS (all onboarding tests, old + new).

- [ ] **Step 6: Commit**

```bash
git add lib/screens/onboarding/onboarding_screen.dart test/helpers/analytics_spy.dart test/screens/onboarding/onboarding_screen_test.dart
git commit -m "feat: onboarding funnel analytics (page view, skip, complete)"
```

---

### Task 6: Topic events (TDD)

**Files:**
- Modify: `lib/providers/enabled_topics_provider.dart`
- Modify: `lib/features/money/presentation/widgets/found_money_section.dart` (sheet-opened at its 2 call sites)
- Test: `test/providers/enabled_topics_analytics_test.dart` (create)

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/analytics/analytics_service.dart';
import 'package:maple_alerts/features/money/presentation/money_topic.dart';
import 'package:maple_alerts/providers/enabled_topics_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('toggle emits topic_enabled / topic_disabled', () async {
    SharedPreferences.setMockInitialValues({});
    final recorded = <(String, Map<String, Object>)>[];
    final notifier = EnabledTopicsNotifier(
      analytics: AnalyticsService(
        sink: (e, p) => recorded.add((e, p)),
        isEnabled: () => true,
      ),
    );

    await notifier.setEnabled(MoneyTopic.ccb, true);
    await notifier.setEnabled(MoneyTopic.ccb, false);

    expect(recorded, [
      ('topic_enabled', {'topic': 'ccb'}),
      ('topic_disabled', {'topic': 'ccb'}),
    ]);
  });

  test('constructor without analytics stays silent (back-compat)', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = EnabledTopicsNotifier();
    await expectLater(notifier.setEnabled(MoneyTopic.ccb, true), completes);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/providers/enabled_topics_analytics_test.dart`
Expected: FAIL — no `analytics` constructor parameter.

- [ ] **Step 3: Implement**

In `lib/providers/enabled_topics_provider.dart`:

```dart
import '../core/analytics/analytics_service.dart';
import 'analytics_provider.dart';

final enabledTopicsProvider =
    StateNotifierProvider<EnabledTopicsNotifier, Set<MoneyTopic>>((ref) {
  return EnabledTopicsNotifier(analytics: ref.read(analyticsProvider));
});

class EnabledTopicsNotifier extends StateNotifier<Set<MoneyTopic>> {
  EnabledTopicsNotifier({AnalyticsService? analytics})
      : _analytics = analytics,
        super(kDefaultEnabledTopics) {
    _load();
  }

  final AnalyticsService? _analytics;
  // ... _load/_persist/isEnabled unchanged ...

  Future<void> setEnabled(MoneyTopic topic, bool enabled) {
    _analytics?.track(
        enabled ? 'topic_enabled' : 'topic_disabled', {'topic': topic.name});
    final next = {...state};
    if (enabled) {
      next.add(topic);
    } else {
      next.remove(topic);
    }
    return _persist(next);
  }
  // toggle unchanged.
}
```

In `lib/features/money/presentation/widgets/found_money_section.dart` (a `ConsumerWidget`), wrap the two `showMoneyTopicsSheet` call sites (lines ~64 and ~66) — these are the only call sites in the app:

```dart
void openTopics() {
  ref.read(analyticsProvider).track('topics_sheet_opened');
  showMoneyTopicsSheet(context);
}
// _TrackPrompt(colors: colors, onTap: openTopics)
// _TrackMoreButton(colors: colors, onTap: openTopics)
```

with import `package:maple_alerts/providers/analytics_provider.dart`.

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/providers/enabled_topics_analytics_test.dart && flutter test test/features/money`
Expected: PASS (new tests + existing money widget tests unaffected).

- [ ] **Step 5: Commit**

```bash
git add lib/providers/enabled_topics_provider.dart lib/features/money/presentation/widgets/found_money_section.dart test/providers/enabled_topics_analytics_test.dart
git commit -m "feat: topic analytics (enable/disable, sheet opened)"
```

---

### Task 7: Money surface events (TDD)

**Files:**
- Modify: `lib/features/money/presentation/widgets/found_money_section.dart`
- Modify: `lib/features/money/presentation/widgets/best_move_card.dart`
- Modify: `lib/features/money/presentation/widgets/learn_section.dart`
- Test: extend the existing FoundMoneySection / BestMoveCard widget test files under `test/features/money/` (locate with `dir /s /b test\features\money`), using `AnalyticsSpy` in the `ProviderScope` overrides.

- [ ] **Step 1: Write failing widget assertions**

In the existing FoundMoneySection widget test (configured-card scenario), add the spy override and after pumping assert:

```dart
expect(spy.fired('insight_card_viewed'), isTrue);
expect(spy.propsOf('insight_card_viewed')!['id'], isNotEmpty);
```

In the BestMoveCard widget test (move-present scenario), assert:

```dart
final shown = spy.propsOf('best_move_shown');
expect(shown, isNotNull);
expect(shown!.keys, containsAll(['kind', 'target']));
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/money`
Expected: new assertions FAIL.

- [ ] **Step 3: Instrument**

`found_money_section.dart` — in the `for (final card in view.cards)` loop:

```dart
for (final card in view.cards) {
  ref.read(analyticsProvider).track('insight_card_viewed', {'id': card.id});
  final explainer = explainerForInsightId(card.id);
  children.add(InsightCard(
    insight: card,
    onAction: (a) {
      ref.read(analyticsProvider).track('insight_cta_tapped', {'id': card.id});
      _handleAction(context, a);
    },
    onLearnMore: explainer == null
        ? null
        : () {
            ref.read(analyticsProvider)
                .track('explainer_opened', {'id': card.id});
            showExplainerSheet(context, explainer);
          },
  ));
  children.add(const SizedBox(height: 10));
}
```

(The service de-dupes `insight_card_viewed` per id per session, so emitting in `build` is safe.) Pass `ref` (or a `void Function(String, Map<String, Object>)` callback) down to `_GetStartedCard`'s `onTap` wrapper the same way for setup rows: track `insight_cta_tapped` with `{'id': insight.id}` before invoking the action.

`best_move_card.dart` — `_BestMoveCardState.build`, where the move is non-null:

```dart
ref.read(analyticsProvider).track('best_move_shown', {
  'kind': move.kind.name,
  'target': move.targetInsightId ?? '',
});
```

(de-duped per kind+target per session by the service).

`learn_section.dart` — convert `StatelessWidget` → `ConsumerWidget` (build gains `WidgetRef ref`), and wrap the chip tap:

```dart
onTap: () {
  ref.read(analyticsProvider).track('explainer_opened', {'id': e.id});
  showExplainerSheet(context, e);
},
```

(Confirm the `Explainer` model's id field name in `lib/engine/canadian_data_engine/content/explainers.dart` — use the actual field.)

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/features/money`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/money test/features/money
git commit -m "feat: money surface analytics (card views, CTAs, best move, explainers)"
```

---

### Task 8: Reminder + paywall events

**Files:**
- Modify: `lib/features/reminders/presentation/widgets/add_reminder_sheet.dart:128` (reminder_added)
- Modify: `lib/features/reminders/presentation/screens/home_screen_v2.dart:251` (reminder_done)
- Modify: `lib/screens/paywall/paywall_screen.dart` (paywall_viewed, purchase_started)
- Test: extend existing `add_reminder_sheet_test.dart` and `paywall_screen_test.dart` with `AnalyticsSpy` overrides.

- [ ] **Step 1: Write failing assertions**

`add_reminder_sheet_test.dart` (existing save-flow test + spy override):

```dart
expect(spy.propsOf('reminder_added')!['category'], isNotEmpty);
```

`paywall_screen_test.dart` (existing render test + spy override):

```dart
expect(spy.propsOf('paywall_viewed'), {'source': 'profile'});
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/reminders/presentation/widgets/add_reminder_sheet_test.dart test/screens/paywall/paywall_screen_test.dart`
Expected: new assertions FAIL.

- [ ] **Step 3: Instrument**

`add_reminder_sheet.dart`, immediately before the `addCustom` call at line ~128 (the sheet already holds `widget.ref`):

```dart
widget.ref
    .read(analyticsProvider)
    .track('reminder_added', {'category': alert.type.name});
await widget.ref.read(alertsProvider.notifier).addCustom(alert);
```

`home_screen_v2.dart` line ~251 — the screen is a Consumer-based widget with `ref` in scope; `item` is a `ReminderView` (`categoryId` is its category):

```dart
onDone: () {
  ref.read(analyticsProvider)
      .track('reminder_done', {'category': item.categoryId});
  notifier.markDone(item.id);
},
```

`paywall_screen.dart` — `_PaywallScreenState`:

```dart
@override
void initState() {
  super.initState();
  // '/paywall' is only pushed from the profile premium card today.
  ref.read(analyticsProvider).track('paywall_viewed', {'source': 'profile'});
}
```

and at the top of `_purchase()`:

```dart
ref.read(analyticsProvider)
    .track('purchase_started', {'package': _selected.name});
```

Add `import 'package:maple_alerts/providers/analytics_provider.dart';` (or relative `../../providers/analytics_provider.dart`) in each file.

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/features/reminders test/screens/paywall`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/reminders lib/screens/paywall test/features/reminders test/screens/paywall
git commit -m "feat: reminder + paywall analytics"
```

---

### Task 9: Privacy toggle in the You tab (TDD)

**Files:**
- Modify: `lib/features/reminders/presentation/screens/profile_screen_v2.dart`
- Test: extend the existing profile screen widget test (locate under `test/features/reminders/presentation/screens/`).

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('Privacy toggle flips analyticsEnabledProvider', (tester) async {
  // Pump ProfileScreenV2 with the existing test scaffolding + mock prefs.
  // ...existing setup...
  await tester.scrollUntilVisible(
      find.text('Share anonymous usage stats'), 200);
  expect(find.text('Share anonymous usage stats'), findsOneWidget);

  await tester.tap(find.text('Share anonymous usage stats'));
  await tester.pump();
  expect(container.read(analyticsEnabledProvider), isFalse);
});
```

- [ ] **Step 2: Run to verify failure**

Expected: FAIL — text not found.

- [ ] **Step 3: Implement**

In `profile_screen_v2.dart`, after the Notifications section (same `MapleSurface` + `Material` + `_TweakToggle` pattern used at lines 108–120), add:

```dart
const SizedBox(height: 28),

// ── 5. Privacy section ───────────────────────────────────────────
const MapleSectionHeader(label: 'Privacy'),
const SizedBox(height: 12),
MapleSurface(
  level: MapleSurfaceLevel.minimal,
  radius: 18,
  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
  child: Material(
    type: MaterialType.transparency,
    child: _TweakToggle(
      label: 'Share anonymous usage stats',
      value: ref.watch(analyticsEnabledProvider),
      colors: colors,
      onChanged: (v) =>
          ref.read(analyticsEnabledProvider.notifier).setEnabled(v),
    ),
  ),
),
Padding(
  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
  child: Text(
    'Helps us decide what to build next. Never your numbers, never your identity.',
    style: TextStyle(fontSize: 12, color: colors.muted),
  ),
),
```

with import `package:maple_alerts/providers/analytics_provider.dart`. If `_TweakToggle` doesn't support a subtitle, the separate caption `Text` above is the implementation — don't extend `_TweakToggle`.

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/features/reminders/presentation/screens`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/reminders/presentation/screens/profile_screen_v2.dart test/features/reminders
git commit -m "feat: Privacy section — anonymous usage stats toggle"
```

---

### Task 10: Full verification + live smoke test + docs

**Files:**
- Modify: `build-status.md`

- [ ] **Step 1: Full suite + analyzer**

Run: `flutter test` → Expected: all tests pass (~265+).
Run: `flutter analyze` → Expected: no new issues (14 pre-existing infos in old V1 screens/tests are known).

- [ ] **Step 2: Live smoke test — first event in the dashboard**

Run: `flutter run -d chrome --web-port 8088`, click through onboarding, then check https://app.aptabase.com — the Maple-Alerts app should show its first events (`onboarding_page_view`, `onboarding_complete`). If web is CORS-blocked, verify on the Android device instead. Report what the dashboard shows either way.

- [ ] **Step 3: Update build-status.md**

Add a "Anonymous analytics — DONE" section under Build Progress (test count, 14 events, toggle, key wired) and a session-history line.

- [ ] **Step 4: Commit + push**

```bash
git add build-status.md
git commit -m "docs: build-status — anonymous analytics slice"
git push
```

---

## Self-review notes

- **Spec coverage:** 14 events — onboarding 3 (Task 5), topics 3 (Task 6), money 4 (Task 7), reminders 2 + paywall 2 (Task 8); kill switch (Task 3), toggle UI (Task 9), fire-and-forget + de-dupe + PII guard (Task 2), init (Task 4), Play Data Safety note is launch-day paperwork (tracked in build-status, not code).
- **De-dupe addendum:** `best_move_shown` is session-de-duped alongside `insight_card_viewed` (it also fires from `build`) — spec updated to match.
- **PII guard:** implemented as a debug-mode assert inside `track` — stronger than a separate guard test because every widget test exercises it on every event; the explicit denylist unit test in Task 2 pins the behaviour.
- **Type consistency:** `AnalyticsService(sink:, isEnabled:)` and `track(String, [Map<String, Object>])` are used identically in Tasks 2, 3, 5–9; spy helper defined once in Task 5 and reused.
