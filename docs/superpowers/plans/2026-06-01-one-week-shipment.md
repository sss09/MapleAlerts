# MapleAlerts — One-Week Shipment Plan

> **Goal:** Ship MapleAlerts with the new **Aurora** design to real users within ~7 days.
> **Strategy:** Reskin the *existing, working* app in Aurora and ship it. Do **not** block launch on the in-progress domain re-architecture (Plan 1/2/3) — that's a post-launch refactor. Minimize rework; maximize shippable surface.

---

## Hard constraints (read first)
- **iOS App Store is NOT feasible this week.** Building/submitting iOS requires macOS + Xcode + an Apple Developer account ($99/yr) + 1–3 day review. We're on Windows with no Mac. → **iOS is post-launch** (needs a Mac or a macOS CI runner).
- **Google Play** needs a Play Developer account ($25 one-time) + review (hours–2 days for the testing track).
- **Web** ships instantly via the existing GitHub Pages workflow (already live, already fixed).
- **Realistic week-1 launch = Web (public) + Android (Play closed/internal testing).** iOS follows.

## Scope decisions (locked defaults — minimize rework)
- **Reskin, don't re-architect.** Build the Aurora UI on top of the **existing** data layer (`alertsProvider`, `DatabaseService`, `canadian_dates_service`, `Alert` model). The unified-`Reminder` domain core we built (Plan 1) stays as the v2 foundation — not wired for launch.
- **Map at the view layer:** `Alert` → `ReminderView` (categories map `AlertType` → the 8 life-domains). One mapper; no data migration needed to ship.
- **Keep what works:** RevenueCat paywall, affiliate cards, notifications service (Android), TFSA/GIC/mortgage trackers — restyle, don't rewrite.
- **Web persistence:** ship web as a **full app on Android** (SQLite works) and a **demo build on web** (sqflite has no web impl → web uses seed/in-memory data for the marketing/demo site). Avoids spending the week on `sqflite_common_ffi_web`.
- **Categories:** 8 life-domains in UI; launch *content* = Canadian financial reminders mapped into Finance/Government/Family. Other domains empty-ready.

## 7-Day schedule

| Day | Focus | Output |
|-----|-------|--------|
| **1** | **Aurora design system** | Tokens (colors, 6-status semantics, 8 categories, 4 auroras) as ThemeExtensions; theme + `designThemeProvider` (+ persisted tweaks); core widgets: `AuroraBackground`, `ProgressRing`, `MapleSurface`, `StrokeIcon`, `MapleScaffold`. Runs on web. |
| **2** | **Home (Aurora)** | `Alert→ReminderView` mapper (TDD); `DayHandledHero`, `CategoryFilterChips`, `ReminderCard` (swipe+expand), `SeasonalRail`; `HomeScreen` wired to existing `alertsProvider`; replaces old home. Visible on web. |
| **3** | **Key flows restyled** | Onboarding, Add-reminder sheet, Reminder detail (with affiliate CTA), Settings/"You" (tweaks: aurora switch, calm mode, motion). Alerts + Timeline tabs (list views on existing data). |
| **4** | **Wire + harden** | Add/edit/delete + notification scheduling on Android; premium gating + paywall; empty/loading/error states; web guards; perf-tune aurora/blur. |
| **5** | **Device testing** | Run on the physical Android phone; fix nav/persistence/notification bugs; accessibility contrast pass; `flutter analyze` clean; full test suite green. |
| **6** | **Release prep** | App icon (dark maple), screenshots from Aurora UI, store listing copy (from vision/pitch docs), privacy policy page, Android release signing, build signed AAB; web build → GitHub Pages. |
| **7** | **Submit + launch** | Play Console closed/internal testing upload; web live; soft-announce (r/PersonalFinanceCanada per marketing doc); buffer for review feedback + hotfixes. |

## Build approach
- **Subagent-driven development** per the detailed build plan (next doc) — fresh implementer + spec/quality review per task, parallel-friendly.
- Pure logic (the `Alert→ReminderView` mapper) = strict TDD. Widgets = build + widget smoke test + `flutter analyze`; visual verification by running on web/device.
- Design source of truth for exact values: `docs/design/ux-design-1/` (ui.jsx tokens, home.jsx layout, app.jsx shell).

## Definition of "shipped" (week 1)
- [ ] Web build with Aurora UI live on GitHub Pages
- [ ] Signed Android AAB on Play closed/internal testing, installable on the user's phone
- [ ] Core loop works: see reminders → add/edit → get a notification (Android) → tap → detail → action
- [ ] Paywall + affiliate links functional
- [ ] No crash on launch; no blank screens; analyze clean; tests green

## Explicitly OUT (post-launch)
- iOS (needs Mac), cloud sync, the unified-Reminder migration (Plan 2/3), Timeline richness, life-events flow, rate scraping, web SQLite persistence, B2B.

## Risks & mitigations
- **Play review delay** → use internal-testing track (fast); submit by Day 6.
- **Aurora perf on mid Android** → cap blob blur, gate ambient motion behind tweak + reduced-motion.
- **Scope creep** → anything not in the Definition-of-shipped is post-launch. No exceptions this week.
- **Accounts not ready** → Play Developer account is the critical-path external dependency; start Day 1.
