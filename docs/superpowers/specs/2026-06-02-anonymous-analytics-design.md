# Anonymous Analytics — Design Spec

**Date:** 2026-06-02
**Status:** Approved
**Slice:** Pre-launch (before Day 6 store submission)

## Why

The app currently has zero visibility into how users move through it. Before the
store launch we add **anonymous, aggregate-only** product analytics so that
post-launch decisions (which money topic to build next — RESP/CESG vs mortgage
renewal vs OSAP RAP — onboarding funnel health, card engagement) are made from
data, not guesses. This is also the data foundation for the planned chain of
Canadian apps.

**Explicit non-goals:** no email capture, no accounts, no user identification,
no marketing attribution. The onboarding trust promise ("no account, no email,
no sign-up — your data stays on your phone") must remain true in spirit:
nothing identifying and none of the user's numbers ever leave the device.

## Decisions (locked with user, 2026-06-02)

| Decision | Choice | Why |
|---|---|---|
| Backend | **Aptabase** (`aptabase_flutter`) | Privacy-first by design: anonymous, no device IDs, no IP storage; no consent banner needed; tiny SDK; free tier (20k events/mo) is ample at launch. Best fit for the trust moat. |
| Consent model | **On by default + settings toggle** | Keeps the funnel complete; Aptabase's no-PII design keeps the promise honest; toggle in You → Privacy gives users real control. |
| Engine impact | **None** | The Canadian Data Engine stays pure Dart. Only presentation-layer code emits events. |

Rejected alternatives: Firebase Analytics (Google identifiers undermine the
trust story; requires wiring the whole Firebase config), PostHog (more power
than we need; heavier SDK, anonymous mode needs careful config), self-rolled
endpoint (no dashboards; too much pre-launch work).

## Architecture

```
lib/core/analytics/
  analytics_service.dart   AnalyticsService + analyticsProvider + spy seam
```

- **`AnalyticsService`** — thin wrapper, single API:
  `void track(String event, [Map<String, Object> props = const {}])`.
  All call sites go through this one choke point. Constructor takes an
  injectable `void Function(String, Map<String, Object>)` backend sink
  (mirrors `BocRateService`'s injectable fetcher) — production sink calls
  `Aptabase.instance.trackEvent`; tests inject a spy. **Fire-and-forget:**
  `track` never throws and never awaits — an analytics failure must never
  affect the UX.
- **Kill switch** — `analyticsEnabledProvider` (prefs-backed bool, default
  `true`, same persistence pattern as `MapleTweaks`). When off, `track()` is a
  no-op at the choke point (events are dropped before the sink, not after).
- **`analyticsProvider`** — Riverpod `Provider<AnalyticsService>` wired to the
  kill switch; widgets/notifiers call
  `ref.read(analyticsProvider).track(...)`.
- **Init** — `Aptabase.init(appKey)` in `main()` before `runApp`, web-safe.
  App key is a `const` in the service file (Aptabase app keys are public
  identifiers, not secrets). A placeholder key degrades silently (SDK no-ops),
  same graceful pattern as the RevenueCat placeholder.

## Event taxonomy (the contract)

~14 events. Property values are enum-like strings only.

| Area | Event | Props |
|---|---|---|
| Funnel | `onboarding_page_view` | `index` (0–3) |
| Funnel | `onboarding_skip` | `at_page` |
| Funnel | `onboarding_complete` | `topics_enabled` (csv, e.g. `"tfsa,rrsp"`) |
| Topics | `topic_enabled` / `topic_disabled` | `topic` |
| Topics | `topics_sheet_opened` | — |
| Money | `insight_card_viewed` | `id` (e.g. `rrsp_room`) |
| Money | `insight_cta_tapped` | `id` |
| Money | `best_move_shown` | `kind`, `target` |
| Money | `explainer_opened` | `id` |
| Reminders | `reminder_added` | `category` |
| Reminders | `reminder_done` | `category` |
| Paywall | `paywall_viewed` | `source` |
| Paywall | `purchase_started` | `package` |

**Never sent — hard contract, enforced by test:** income, birth year, ages,
contribution/room/benefit dollar amounts, GIC amounts or dates, reminder
titles or free text, province, kid counts. Topic names and card ids only:
*which* features people use, never *what is in them*. No event property may be
named `amount`, `income`, `value`, `title`, `birthYear`, `province` (guard
test asserts against a denylist at every call site via the spy).

`insight_card_viewed` fires once per card id per app session (in-memory
de-dupe in the service), not per rebuild — widget rebuild noise would swamp
the signal and burn the free tier.

## Settings UI

You tab → new **Privacy** row: switch labelled **"Share anonymous usage
stats"**, subtitle: *"Helps us decide what to build next. Never your numbers,
never your identity."* Default on. Flipping it writes the pref and takes
effect immediately (no restart).

## Testing

- Unit: kill switch on/off; session de-dupe of `insight_card_viewed`; sink
  never called when disabled; `track` swallows sink exceptions.
- Widget: onboarding complete emits `onboarding_complete` with the enabled
  topics; topic toggle emits enable/disable; settings switch flips the pref.
- Guard: spy collects every event emitted across the widget tests and asserts
  no denylisted property names appear.
- No test ever performs network I/O (spy sink everywhere; `Aptabase.init` not
  called in tests).

## Ops / user actions

1. User creates a free Aptabase account (aptabase.com, ~2 min) and an app
   entry → gets the `A-…` app key. Until then the placeholder no-ops.
2. Google Play **Data Safety** form: declare "App interactions" analytics
   data, not linked to identity, not shared. (Aptabase stores no identifiers,
   so this is the lightest possible declaration.)
3. Privacy policy line for the store listing: "MapleAlerts collects anonymous
   usage statistics (e.g. which features are opened). These are never linked
   to you and contain none of your financial information. You can turn this
   off in Settings → Privacy."

## Deferred

- Retention cohort dashboards beyond what Aptabase provides out of the box.
- Event versioning / schema registry (revisit if the event count grows past ~25).
- A/B testing of onboarding copy.
