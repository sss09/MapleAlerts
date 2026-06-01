# Day 4 — Functionality Wiring (actions, notifications, paywall)

> REQUIRED SUB-SKILL: superpowers:subagent-driven-development.

**Goal:** Make the app *do things* — reminder Done/Snooze actually work + persist, adding a reminder schedules a notification (Android), and the paywall is Aurora + wired. Reuse-first.

**Env:** Flutter at `/c/src/flutter/bin/flutter`; package `maple_alerts`; branch `main`; commit each task (no push); trailer `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Test `flutter test <path> -r compact`; analyze `flutter analyze <path>`. Web no-ops for notifications are already handled via `kIsWeb` guards in NotificationService.

---

### Task D4-1: Done / Snooze actions (persisted hide/snooze)
Built-in Canadian alerts aren't in the DB, so "done/snooze" is a **local hide map** keyed by reminder id (works for built-in + custom).
**Files:** Create `lib/features/reminders/presentation/hidden_reminders_provider.dart`; modify `home_screen_v2.dart`, `timeline_screen.dart`, `alerts_screen_v2.dart` to filter hidden + pass real callbacks; test `test/features/reminders/presentation/hidden_reminders_test.dart`.
- `HiddenRemindersNotifier extends StateNotifier<Map<String, DateTime>>` (id → hiddenUntil), persisted in shared_preferences as JSON (`{id: iso8601}`), key `'hidden_reminders_v1'`. Methods:
  - `Future<void> markDone(String id)` → set `id → DateTime(9999)` (effectively forever); also `NotificationService.instance.cancelAlert(id)` (web-guarded already).
  - `Future<void> snooze(String id, {Duration by = const Duration(days: 7)})` → set `id → <now>+by` (compute now at call; do NOT use a const now). 
  - `bool isHidden(String id, DateTime now)` → `state[id]?.isAfter(now) ?? false`.
  - load/save guarded in try/catch (web/test safe).
  - `final hiddenRemindersProvider = StateNotifierProvider<HiddenRemindersNotifier, Map<String,DateTime>>((ref)=>HiddenRemindersNotifier());`
- In `home_screen_v2.dart` / `timeline_screen.dart` / `alerts_screen_v2.dart`: `final hidden = ref.watch(hiddenRemindersProvider);` and filter the mapped views with `where((v)=> !ref.read(hiddenRemindersProvider.notifier).isHidden(v.id, now))` (or compute via the watched map directly). Pass real callbacks to `ReminderCard`: `onDone: () => ref.read(hiddenRemindersProvider.notifier).markDone(item.id)`, `onSnooze: () => ref.read(hiddenRemindersProvider.notifier).snooze(item.id)`. (Timeline/Alerts may not use ReminderCard — at minimum Home wires the card actions; Timeline/Alerts just filter hidden.)
- Test (pure logic, inject now): `markDone` then `isHidden(id, now)` true; `snooze` then hidden now but not after `now+8d`; unknown id not hidden. (Use the notifier directly; shared_preferences calls are guarded so they won't throw in tests, but you can also `SharedPreferences.setMockInitialValues({})` in setUp.)
- Run→PASS→analyze→`flutter test -r compact` green→commit `feat: wire Done/Snooze with persisted hide/snooze`.

### Task D4-2: Notification scheduling on add + launch
**Files:** modify `lib/providers/alerts_provider.dart` (addCustom schedules), `lib/main.dart` (launch scheduling); maybe `lib/services/notification_service.dart` (a helper). Test: a light unit test if feasible (scheduling is plugin-bound; keep tests minimal — mainly ensure no crash on web path).
- `addCustom`: after a successful insert, call `await NotificationService.instance.scheduleAlert(alert);` (already `kIsWeb`-guarded → no-op on web). Wrap in try/catch.
- `main.dart`: after `await NotificationService.instance.initialize();`, fire-and-forget schedule built-in upcoming reminders: `NotificationService.instance.scheduleAnnualReminders();` (it exists, web-guarded). Do it once at launch (not per-frame).
- Respect `settingsProvider.notificationsEnabled`: simplest — in `scheduleAlert`/`scheduleAnnualReminders` callers, only schedule if enabled. Since providers aren't easily reachable in main, gate at minimum in `addCustom` is optional; acceptable to always schedule for v1 (default enabled). Note this in the report.
- Ensure the full suite still passes (these are mostly no-ops in tests). analyze clean. Commit `feat: schedule notifications on add + at launch (Android)`.

### Task D4-3: Aurora paywall + wire purchase/restore + premium gating
**Files:** Rewrite `lib/screens/paywall/paywall_screen.dart` in Aurora (keep the route `/paywall`); wire `subscriptionProvider`. Test: smoke test.
- READ the current `paywall_screen.dart` first. Restyle in Aurora: `AuroraBackground`, `MapleSurface`, the MapleAlerts+ gradient card style (match `ProfileScreenV2`'s premium card), perks list, price **$4.99/mo or $34.99/yr** (locked), "Start free trial" + "Restore purchases" buttons.
- Wire: "Start free trial"/purchase → `await ref.read(subscriptionProvider.notifier).purchase()` (shows result; RevenueCat key is a placeholder so it may return false — handle gracefully with a SnackBar "Purchases not available yet"); "Restore" → `.restore()`. Close/pop on success.
- Premium gating (light for v1): in `ProfileScreenV2`, the premium card already routes to `/paywall`. Optionally add a subtle lock chip on premium-flagged reminders — SKIP if time-consuming; the free tier is generous. Focus on a polished, reachable Aurora paywall.
- Smoke test: pump `PaywallScreen` in `ProviderScope`(+subscription stub)/themed `MaterialApp` → builds + finds a price/"Restore" control. analyze clean; full suite green. Commit `feat: Aurora paywall wired to subscription provider`.

---
## Self-Review
- Day 4 = interactivity (actions), the core notification promise (Android), and conversion (paywall). 
- No placeholders; reuses NotificationService (web-guarded), subscriptionProvider, shared_preferences pattern, Aurora widgets.
- Notifications can only be fully verified on the physical device (Day 5) — code paths are web-safe and unit-green here.
