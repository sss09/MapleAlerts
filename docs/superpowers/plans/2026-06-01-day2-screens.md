# Day 2 — Remaining Aurora Screens + Add Sheet

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Steps use `- [ ]`.

**Goal:** Build the Aurora **Timeline**, **Alerts**, and **You/Profile** tab screens + the **Add-reminder sheet**, and wire them into `MapleHomeShell` (replacing the placeholders + the no-op FAB) — so the whole app navigates as Aurora.

**Reuse-first:** all use existing tokens/widgets (MapleSurface, ProgressRing, StrokeIcon, MapleSectionHeader, MapleColors/Semantics) + `AlertPresentation.map` + existing providers (`alertsProvider`, `subscriptionProvider`, `tweaksProvider`). No domain changes.

**Tech/env:** Flutter at `/c/src/flutter/bin/flutter`; package `maple_alerts`; branch `main`; commit each task (no push); trailer `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. Test: `flutter test <path> -r compact`; analyze: `flutter analyze <path>`.

**Design source (read for exact values):** `docs/design/ux-design-1/sheets.jsx` (AddSheet, AlertsScreen, TimelineScreen, ProfileScreen), `app.jsx` (AuroraSwatches, tweak toggles), `ui.jsx` (tokens), `data.js` (categories).

**Smoke test pattern:** pump inside `MaterialApp(theme: mapleThemeData(DesignTheme.fog), home: Scaffold(body: <screen>))` (wrap in `ProviderScope` + override providers where the screen reads them), `await tester.pump(const Duration(milliseconds: 50))`, assert finders.

---

### Task D2-1: TimelineScreen
**Files:** Create `lib/features/reminders/presentation/screens/timeline_screen.dart` + test.
A `ConsumerWidget` reading `alertsProvider`. On data: filter to today/future (same as Home: `!deadlineDate.isBefore(today)`), map via `AlertPresentation.map`, sort by progress descending (nearest first — higher progress = sooner). Header: small accent label "Your life, on a line" + `Text('Timeline', 27/700)`. Then a vertical timeline (port `TimelineScreen` in sheets.jsx): a left gradient rail + per-item a dot (status color) + a `MapleSurface(level: minimal, status: item.status, radius: 18)` row with `StrokeIcon`/category `Icon(cat.icon)` + title + `whenLabel` (status color). Use `categoryFor(item.categoryId)` for icon+tint. Handle loading (spinner) / error (friendly text) / empty ("Nothing on the horizon").
Smoke test: override `alertsProvider` with 2 future alerts → builds + `find.text('Timeline')` + a sample title. Commit `feat: add Aurora Timeline screen`.

### Task D2-2: AlertsScreen
**Files:** Create `lib/features/reminders/presentation/screens/alerts_screen_v2.dart` + test.
A `ConsumerWidget`. Header: accent label "The way alerts should feel" + `Text('Calm notifications', 27/700)` + a muted subtitle (port copy from sheets.jsx). Body: render the user's upcoming reminders (from `alertsProvider`, filtered today/future, mapped, take ~6 nearest) as **calm notification cards** — `MapleSurface(level: solid, status: item.status, active: true, radius: 22)`: a header row [leaf icon chip, "MapleAlerts", "· <title>", a right-aligned status badge (dot + status.label on status.soft)], then a human body line (use `item.description`), then a footer "<whenLabel> · <category label>". If no reminders, show the designed sample copy as a graceful empty/preview state (port the 4 NOTES from sheets.jsx as illustrative cards). Commit `feat: add Aurora Alerts screen`.

### Task D2-3: ProfileScreen ("You") + Appearance tweaks
**Files:** Create `lib/features/reminders/presentation/screens/profile_screen_v2.dart` + test.
A `ConsumerWidget` reading `subscriptionProvider` (premium bool) + `tweaksProvider`/`tweaksProvider.notifier`.
- Profile header: circular avatar (initial 'M' or generic), name placeholder ("Welcome" / "Your profile"), subtitle "<plan> plan" from subscription (Free/Premium). (No real auth — keep static-friendly.)
- **MapleAlerts+ premium card** (port ProfileScreen gradient card from sheets.jsx): perks list + "Try free for 14 days" button → on tap call `context.push('/paywall')` (route exists) or `subscriptionProvider` upgrade if available; "Then $4.99/mo · cancel anytime". Hide/replace with a "You're a member ✨" state if already premium.
- **Appearance section** (`MapleSectionHeader('Appearance')`): aurora swatch picker (2-col grid of the 4 `kAuroras`, selected ring on active) → `ref.read(tweaksProvider.notifier).set(tweaks.copyWith(auroraId: k))`; toggles for "Warm urgency accents" (warmAccents), "Status colour legend" (legend), "Ambient motion" (motion) → each updates tweaks. (Port AuroraSwatches + toggles from app.jsx.) This makes the swappable design user-facing.
Smoke test: override `subscriptionProvider`→false + `tweaksProvider` default; builds + `find.text('Appearance')` + finds an aurora label (e.g. 'Teal Frost') + the premium CTA. Commit `feat: add Aurora You/Profile screen with appearance tweaks`.

### Task D2-4: AddReminderSheet
**Files:** Create `lib/features/reminders/presentation/widgets/add_reminder_sheet.dart` + test.
A modal bottom sheet (`showModalBottomSheet` helper `Future<void> showAddReminderSheet(BuildContext, WidgetRef)`), Aurora-styled (port AddSheet from sheets.jsx): drag handle, sparkle + "Add anything — we'll sort it out", a multiline `TextField` ("Renew my passport in September…"), **smart categorization preview** using a ported `RULES`/`detect(text)` (from sheets.jsx) showing "Filed under <Category> · I'll remind you <when>", suggestion chips (port SUGGEST), three method buttons (Voice/Scan/Forward email) rendered as visual-only "coming soon" (no-op + a subtle SnackBar "Coming soon"), and a primary "Add reminder" button (disabled until text entered).
**Working save (minimal):** on "Add reminder", create an `Alert` (id via `CanadianDatesService.newId()` or `DateTime.now().millisecondsSinceEpoch.toString()`, title = entered text, type from detected category mapped back to an AlertType — or `AlertType.custom`, deadline = now + 30 days as a sane default, description = ''), persist via the existing path: read `lib/providers/alerts_provider.dart` to find the add method (e.g. a notifier method or `DatabaseService.instance.insertAlert` + `ref.refresh`). If no clean add method exists, add a minimal `addCustom(Alert)` to `AlertsNotifier` that inserts + reloads. Close the sheet after adding.
Smoke test: pump a button that opens the sheet (or test the inner widget directly) → enter text → categorization preview appears; tapping Add invokes the save callback. Keep it robust. Commit `feat: add Aurora add-reminder sheet with smart categorization`.

### Task D2-5: Wire screens + sheet into MapleHomeShell + verify
**Files:** Modify `lib/features/reminders/presentation/screens/maple_home_shell.dart`; test update.
Replace the placeholder bodies: index 1 → `TimelineScreen`, 2 → `AlertsScreenV2`, 3 → `ProfileScreenV2`. Wire `onAdd: () => showAddReminderSheet(context, ref)`.
- [ ] Update/My smoke test: pump `MapleHomeShell` (with provider overrides) → tap the Timeline/Alerts/You tabs → each shows its header text.
- [ ] `flutter analyze lib test` clean; `flutter test -r compact` all green.
- [ ] Commit `feat: wire Timeline/Alerts/You tabs + add sheet into shell`.
- [ ] (Controller verifies on web after.)

---
## Self-Review
- Covers Day 2 of the shipment plan (restyle remaining screens + add flow). Onboarding restyle deferred to Day 3 (first item).
- No placeholders: each task references the in-repo design source for exact values + has a smoke test + commit.
- Reuse: existing tokens/widgets/providers + AlertPresentation; only `maple_home_shell.dart` edited for wiring; possibly a small `addCustom` on AlertsNotifier.
