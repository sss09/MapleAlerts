# Phase 0 — Launch Blockers (reconciled from Agent Notes 2)

> REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Source: `MapleAlerts_AgentNotes_2.docx` (2026-06-05), reconciled against the **current Aurora codebase** (several notes referenced the retired pre-Aurora `home_screen.dart`).

**Goal:** Clear the genuine launch blockers, then go to release prep. Decisions: price **$2.99/mo · $19.99/yr**; **no free trial** → CTA "Go Pro — $2.99/mo".

**Env:** Flutter `/c/src/flutter/bin/flutter`; package `maple_alerts`; branch `main`; commit each task (no push until asked); trailer `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

**Reconciliation notes (verified 2026-06-05):**
- Live home is `MapleHomeShell → HomeScreenV2` (vertical Today/This-Week/Upcoming, no `take(5)`, past-due filtered) — Agent-Notes #5 (vertical list) is **already done**.
- `lib/screens/home/home_screen.dart` + `_TfsaRoomCard` are **not imported / not routed** = dead code. Agent-Notes #2 ("remove duplicate TFSA card") is **moot for users** → reframed as dead-code deletion.
- Paywall really is `$4.99/$34.99`; settings is `$2.99` → real inconsistency.
- `AlertType` has **no `tax`**; `getBuiltInAlerts()` has **none** of the tax/FHSA/HBP/GST deadlines → genuinely missing as *alerts*. (They exist only in the display-only seasonal rail → must de-dupe.)

---

### Task P0-1 — Price fix ($2.99/$19.99, no-trial CTA) + doc sync
**Files:** `lib/screens/paywall/paywall_screen.dart`; its test; docs.
- Monthly `$2.99` `/mo`; Yearly `$19.99` `/yr` tag `Save 44%`.
- CTA text → **"Go Pro — $2.99/mo"** (remove "14-day free trial" — no trial configured).
- Update the paywall widget test (`textContaining('4.99')` → `'2.99'`; trial-text finder → new CTA).
- Confirm `settings_screen.dart` already `$2.99` (leave).
- **Docs:** update `docs/superpowers/specs/2026-06-01-money-copilot-strategy-design.md`, `docs/product/03-monetization.md`, `docs/product/01-mvp.md`, `build-status.md` — change `$4.99` → `$2.99` (and `$34.99` → `$19.99`).
- Run full suite green; commit `fix: paywall price $2.99/$19.99 + no-trial CTA; sync docs`.

### Task P0-2 — Tax/FHSA/HBP/GST deadlines as built-in alerts (+ de-dupe seasonal rail)
**Files:** `lib/models/alert.dart` (enum + extension), `lib/services/canadian_dates_service.dart`, `lib/features/reminders/presentation/seasonal_events.dart`, tests.
- Add `tax` to `AlertType`; update `AlertTypeExtension.fromString()` + `name` getter.
- In `getBuiltInAlerts(year)` add (all `isPremium: false`), copy per the notes:
  - Personal tax filing — Apr 30 (`tax_filing_$year`)
  - Tax balance-owing payment — Apr 30 (`tax_payment_$year`)
  - Self-employed filing — Jun 15 (`tax_selfemployed_$year`)
  - FHSA contribution deadline — Dec 31 (`fhsa_deadline_$year`)
  - HBP repayment — Mar 1 (`hbp_repayment_$year`, "if applicable" in description)
  - GST/HST instalments ×4 — Mar 31 / Jun 15 / Sep 15 / Dec 15 (`gst_instalment_${year}_q$n`)
  - Map to `AlertType.tax` (HBP may use `rrsp`); category resolves to `finance` via existing `AlertPresentation`.
- **De-dupe the seasonal rail:** remove the now-duplicated entries from `seasonal_events.dart` that are becoming built-in alerts (self-employed filing, FHSA, RESP→keep if not an alert, charitable→keep, tax instalments→now alerts). Keep only items NOT represented as alerts (e.g., Daylight saving, RESP/CESG cutoff, charitable donation cutoff, new TFSA room, GST/HST credit payment — these aren't in the alert set). Update `seasonal_events_test.dart` expectations accordingly.
- **No notification spam:** the existing `collapseRecurringSeries` collapses repeating series on display — confirm GST instalments (4/yr) collapse to next; tax filing/payment same-day Apr 30 are distinct (acceptable). Keep within-7-days fire logic.
- TDD: extend `canadian_dates_service` tests (new ids present, correct dates, all free) + alert enum round-trip for `tax`. Full suite green. Commit `feat: add free tax/FHSA/HBP/GST built-in deadlines (AlertType.tax); de-dupe seasonal rail`.

### Task P0-3 — Dead-code cleanup (safe)
**Files:** delete only **verified-unimported** legacy files.
- Confirm via grep that `lib/screens/home/home_screen.dart` is imported nowhere (verified) → delete it (removes `_TfsaRoomCard`).
- Audit `lib/screens/main_screen.dart`, `lib/screens/tracker/tracker_screen.dart`, `lib/screens/alerts/alerts_screen.dart`, `lib/screens/settings/settings_screen.dart`, `lib/widgets/*`, `lib/utils/theme.dart` — for EACH, grep imports; delete only if zero references (keep `add_gic_screen`/`add_mortgage_screen` — routed; keep models used by engine; keep anything referenced).
- After deletions: `flutter analyze lib test` clean + `flutter test -r compact` green (proves nothing broke). Commit `chore: remove dead pre-Aurora screens/widgets`.

---
## Self-Review
- Only genuine blockers + the reframed dead-code item; #5 dropped (already done). No placeholders. De-dup of seasonal vs alerts is the one design call — resolved (alerts win; rail keeps only non-alert items).
