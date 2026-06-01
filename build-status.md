# MapleAlerts — Build Status

> **Living document.** Auto-loaded at the start of every Claude Code session via a SessionStart hook, and updated before each session ends. It is the single source of truth for *where the build is* and *what happened across sessions*.

---

## Product

**MapleAlerts** — reminders for all Canadian financial deadlines (RRSP, TFSA, GIC, mortgage, BoC rate decisions, CCB, OSAP…).

**North-star goal:** best-in-class UX and a seamless experience.

**⚑ Vision (REFRAMED 2026-06-01):** MapleAlerts is a **Canadian money co-pilot** and the **foundation of a chain** of Canadian apps — not just a reminder app. Differentiators (all free/deterministic, no AI): **penalty guardrails** (prevent TFSA/RRSP over-contribution penalties), **"best move right now"** (cross-account rule-based recommendations), **found money** (TFSA/RRSP room, CCB, carbon rebate). Reminders are one pillar. AI is premium-only. Powered by a reusable **Canadian Data Engine** (on-device rules+math + one hosted JSON data pack + free BoC Valet API). Full strategy: `docs/superpowers/specs/2026-06-01-money-copilot-strategy-design.md`.
*(Prior framing — still the base: a deadline & reminder hub across categories.)*

---

## Tech Stack

- **Framework:** Flutter (Dart) — SDK 3.44.0 / Dart 3.12.0
- **State:** Riverpod · **Routing:** go_router
- **Local storage:** SQLite (sqflite) · shared_preferences
- **Notifications:** flutter_local_notifications (+ timezone) · firebase_messaging (present, not yet core)
- **Monetization:** RevenueCat (purchases_flutter)
- **Firebase:** auth/firestore/messaging present as deps but **not yet wired** into the data layer (reserved for future sync)

---

## Architecture Decisions (locked this session — 2026-05-31)

| Decision | Choice |
|----------|--------|
| **Vision/scope** | Deadline & reminder hub (grow categories, not net-worth/advisory) |
| **Data & sync** | Local-first now; clean repository layer so cloud sync drops in later |
| **Refactor appetite** | Re-architect now while the app is small (~10 screens) |
| **Project structure** | **Feature-first + repository layer** (vertical slices + `core/`) |
| **Reminder model** | **Unified `Reminder` entity + category registry** (recurrence-aware) |

### Target structure
```
lib/
  core/        di, database (+migrations), notifications, router, theme, result
  features/
    reminders/      domain (entity, schedule, category registry, repo interface)
                    data (local datasource, dto, local repo impl)
                    presentation (providers, screens, widgets)
    tracked_items/  GIC + mortgage — sources that DERIVE reminders
    canadian_dates/ rules that GENERATE system reminders
    subscription/   RevenueCat + paywall
    onboarding/
  shared/widgets/   generic UI
```

### Core model (decided)
- `Reminder { id, title, description, categoryId, schedule, source, sourceItemId, notify, isPremium, isDismissed, metadata }`
- `ReminderSchedule` sealed → `OneTimeSchedule | RecurringSchedule` (replaces per-year regeneration)
- `ReminderCategory` registry → icon/color/default lead-times/premium per category; **add category = one registry entry**
- `NotificationConfig { enabled, leadTimes[], timeOfDay }` → tunable multi-lead-time reminders
- `ReminderSource { system, user, derived }`
- Repository interface in `domain/`; `LocalReminderRepository` (SQLite) now, `SyncedReminderRepository` later — presentation depends only on the interface.

### Data layer
- New `reminders` table (v2) with `schedule_json` / `notify_json`; `gics` & `mortgages` kept as-is (they're sources).
- Versioned migration v1→v2: create `reminders`, backfill from old `alerts`, drop `alerts`. No data loss.

---

## Product Decisions (locked 2026-05-31)

| Decision | Choice |
|----------|--------|
| **MVP alerts** | 8 — original 7 (RRSP, TFSA room, GIC, OSAP, mortgage, BoC, CCB) **+ Tax filing deadline** (added: top seasonal keyword, hardcoded-simple) |
| **Free tier** | Broad date-based alerts everyone Googles (RRSP, TFSA, Tax, BoC, benefit dates) — drives SEO/retention flywheel |
| **Premium ($4.99/mo, $34.99/yr)** | Personalization + trackers + calculators (GIC/mortgage/OSAP, room math, HBP/FHSA, life events, export, widget, no ads) |
| **Family ($8.99/mo)** | Later — shared RESP, spousal RRSP, joint mortgage |
| **Ads** | ❌ NOT at launch — trust is the moat; lead with affiliate + subscription |
| **Monetization priority** | Affiliate → subscription → B2B → courses → (ads optional/deferred) |
| **Content as data** | Canadian rules stored as versioned data keyed by year+province+audience, separate from code (the content moat) |

## Documentation Suite (created 2026-05-31)

- `docs/product/README.md` — index + guiding principles
- `docs/product/00-vision.md` — vision, problem, moat
- `docs/product/01-mvp.md` — 8 alerts, free/paid, 4-week plan, metrics
- `docs/product/02-alert-catalog.md` — full 11-category taxonomy (content backlog, phase-tagged)
- `docs/product/03-monetization.md` — 5 streams + recommended sequencing
- `docs/product/04-onboarding.md` — personalization flow
- `docs/product/05-notification-design.md` — "what should I DO?" principle
- `docs/product/06-roadmap.md` — V1→V3, year-1 timeline, marketing
- `docs/superpowers/specs/2026-05-31-maplealerts-architecture-design.md` — engineering spec

## Build Progress

### Done
- [x] Architecture brainstorm complete — all major decisions locked
- [x] Flutter SDK 3.44.0 downloaded + extracted to `C:\src\flutter`
- [x] Product doc suite created (vision, MVP, catalog, monetization, onboarding, notifications, roadmap)
- [x] Architecture design spec written (sections 1–4)

- [x] User reviewed + agreed with recommendations
- [x] Docs + spec + build-status + settings hook committed (`72afd85`)
- [x] Flutter 3.44.0 on persistent user PATH; `flutter doctor` run — **web dev ready now**
- [x] Wrote implementation Plan 1 — Reminders Domain Core (8 TDD tasks) → `docs/superpowers/plans/`
- [x] Executed Plan 1 Tasks 1–5 via subagent-driven dev (ReminderSource, Recurrence, ReminderSchedule, NotificationConfig, ReminderCategory) — all tests green; each passed spec + code-quality review
- [x] Fixed web boot crash: `NotificationService` guarded with `kIsWeb` (dart:io Platform crashed web build → blank screen, incl. GitHub Pages)
- [x] **Merged everything to `main` and pushed to GitHub** (fast-forward; live web build now boots)
- [x] App runs on web (Chrome, localhost:8088) — routes to onboarding screen

### Environment notes
- Web (Chrome/Edge): ✅ ready — primary dev/run target for now
- Windows desktop: needs VS "Desktop development with C++" workload (not installed)
- Android: needs Android Studio + SDK (not installed)
- Flutter SDK location: `C:\src\flutter`

### Aurora redesign — SHIPPED to main (Day 1 of 1-week shipment)
- [x] Phase A — design system: tokens (MapleColors/Semantics/Aurora ThemeExtensions), theme + `designThemeProvider` + persisted tweaks, core widgets (StrokeIcon, ProgressRing, MapleSurface, AuroraBackground, MapleScaffold). All tested.
- [x] Phase B — Home: `Alert→ReminderView` mapper (TDD), DayHandledHero, CategoryFilterChips/StatusLegend, ReminderCard (swipe+expand), SeasonalRail, `HomeScreenV2` + `MapleHomeShell` wired to existing `alertsProvider`. Old red theme/screens retired (not routed).
- [x] Category registry adapted to 8 life-domains (in place; finance built-ins map to Finance/Family).
- [x] Verified on web (Chrome) — Aurora Home renders: hero, chips, sections, cards, glass tab bar + FAB. Full suite green (~83 tests). Pushed to main (`d981e16`).
- 8 life-domain categories live; launch content = Canadian financial reminders mapped in.

### Day 2 — DONE (pushed to main, 94/94 tests)
- [x] Aurora **Timeline** screen (vertical timeline on real alerts)
- [x] Aurora **Alerts** screen ("Calm notifications")
- [x] Aurora **You/Profile** screen — premium card + **Appearance tweaks** (aurora swatches, calm mode, legend, motion) wired to tweaksProvider
- [x] **Add-reminder sheet** — natural-language entry + smart categorization; `AlertsNotifier.addCustom` persists (degrades on web)
- [x] Wired Timeline/Alerts/You tabs + FAB into MapleHomeShell — all 4 tabs are Aurora now

### Day 3 — DONE (pushed to main, 98/98 tests)
- [x] **Onboarding** restyled in Aurora (4 pages, aurora bg, accent CTAs, $4.99 copy) + fixed post-onboarding nav `/home`→`/` (was a latent blank-screen bug from the Day-1 route move)
- [x] **Affiliate CTA** in reminder detail — category-aware (finance→EQ Bank, home→Ratehub) with a transparent "Partner" tag; opens via url_launcher

### Day 4 — DONE (pushed to main, 102/102 tests)
- [x] **Done / Snooze** actions — persisted hide map (`hiddenRemindersProvider`, shared_prefs); filtered across Home/Timeline/Alerts; Done cancels its notification
- [x] **Notifications** scheduled on add (`addCustom`) + built-ins at launch (Android; web-guarded). Full device verification = Day 5.
- [x] **Aurora paywall** — restyled (last red screen gone) + wired to `subscriptionProvider` (purchase/restore, graceful when RevenueCat key is placeholder)

### Day 5 — DONE (on-device tested on Galaxy S25 FE, pushed to main)
- [x] Ran on real device (fixed Android build: core library desugaring for flutter_local_notifications)
- [x] Verified on-device: add → categorize → **date picker** → persist (SQLite) → display; Done/Snooze
- [x] On-device fixes: bottom dock lifted above system-nav inset (+ bottom fade); legend off by default; add-sheet keyboard overflow fixed; **date picker** (was hardcoded +30d); **collapse recurring CCB/BoC to next-only** (was flooding the list); removed dead Voice/Scan/Email buttons; hero pluralization (0/1/many)
- [x] Notifications toggle in You → Appearance
- Known/minor (test-data only, removable via swipe-Done): duplicate custom reminder + legacy items showing "In 30 days" (added before the date picker). Edit-reminder = post-launch.

### Next up (shipment Days 6–7)
- [ ] Day 6: app icon (dark maple), screenshots (from device), store listing copy, Android release signing, signed AAB/APK; web build
- [ ] Day 7: Play closed/internal testing upload; web live; soft-announce
- [ ] Optional polish: swipe-to-delete + edit for reminders (currently swipe = Done/hide)
- [ ] Day 4: wire add/edit/delete + notifications (Android); premium gating + paywall; empty/loading/error states
- [ ] Day 5: physical Android device testing + bug fixes + perf/contrast pass
- [ ] Day 6: app icon, screenshots, store listing, Android release signing, signed AAB; web build
- [ ] Day 7: Play closed/internal testing upload; web live; soft-announce
- [ ] **User action (critical path):** create Google Play Developer account ($25) — start now
- Post-launch: finish Plan 1 Tasks 6–8 + Plan 2 (data layer/migration) + wire UI to the unified Reminder repository; iOS (needs Mac); web SQLite persistence

---

## Open Questions / Parking Lot
- Platform priority (mobile-first assumed; web deploy exists via GitHub Pages) — confirm later.
- When does cloud sync become a priority? (architecture is ready for it; not built)
- Monetization evolution (affiliate_card widget exists — marketplace angle parked)

---

## Session History

### 2026-05-31 — Session 1
- Read through product docs; mapped current architecture (layer-based, SQLite god-object, Firebase present but unused).
- Established north-star: best UX / seamless experience.
- Ran full architecture brainstorm. Locked: deadline-hub vision, local-first + repository, re-architect-now, feature-first structure, unified Reminder + category registry.
- Downloaded & extracted Flutter 3.44.0 SDK (PATH setup pending).
- Established this build-status doc + hook-backed session memory rule (SessionStart hook in `.claude/settings.json`).
- Received full product thesis (monetization, onboarding, notifications, MVP, moat, marketing, full alert taxonomy). Categorized into a 7-file product doc suite + architecture spec.
- Made + documented key recommendations: add Tax-filing alert to MVP (→8); reshape free/paid to gate personalization not public info; **no ads at launch**; content-as-data for the moat.

### 2026-06-01 — Session 2
- Wrote Plan 1 (Reminders Domain Core) and executed Tasks 1–5 via subagent-driven development (fresh implementer + spec review + code-quality review per task). Reviewers caught real issues each round (graceful enum fallback, interval>1 guard via assert, fromJson default-leadTimes, registry key==id invariant) — all fixed.
- Per user request: merged the whole feature branch into `main` (fast-forward, 23 commits) and pushed to GitHub.
- Per user request: ran the app on web. Hit a blank screen — root-caused to `dart:io` `Platform.isAndroid` in NotificationService crashing the web build (also broke the GitHub Pages site). Guarded with `kIsWeb`; app now boots and routes to onboarding. Pushed fix to main.
- Installed Android toolchain the lean way (no Android Studio): Microsoft OpenJDK 17 + SDK command-line tools + platform-tools + android-36 + build-tools; `flutter doctor` Android toolchain green. Physical-phone path (USB debugging) chosen.
- User provided a finished Aurora design (`UX-design-1.zip`, Claude design) — dark aurora theme, "Your day, handled" hero, 8 life-domain categories, 6-status palette, 4 swappable auroras. Wrote design spec + preserved assets (`docs/design/ux-design-1/`).
- User set a **1-week shipment goal** → wrote shipment plan (reskin existing app in Aurora; ship Web + Android; iOS post-launch — no Mac). Launch target Web+Android; Play account being created ($25).
- Built the Aurora design system + Home in one session via subagent-driven dev (11 build tasks A1–A10, B1–B6). Reused all of Plan 1's domain core; only adapted the category registry. Verified on web; pushed to main (`d981e16`).
- **Day 2 done:** built the remaining Aurora screens (Timeline, Alerts, You/Profile + appearance tweaks) and the natural-language add-reminder sheet; wired all four tabs + FAB into the shell. 94/94 tests; pushed to main (`38933c8`). All tabs are Aurora now.
- **Next session (Day 3):** restyle **onboarding** (still old red — first impression for new users); reminder detail screen w/ affiliate CTA; then Day 4 functionality wiring, Day 5 device test, Day 6 release prep, Day 7 submit.
- Note: headless Playwright browser is flaky at painting the Flutter web canvas (GPU/DWDS) — verify visually in the `flutter run -d chrome` window; functional coverage is via the widget/unit tests.
- **Day 3 done:** restyled onboarding in Aurora + fixed the `/home`→`/` nav bug; added category-aware affiliate CTA (finance/home) to the reminder detail. 98/98 tests; pushed to main. All user-facing screens are now Aurora.
- **Day 4 done:** wired Done/Snooze (persisted hide map) + notification scheduling (add + launch, Android) + restyled the paywall in Aurora and wired purchase/restore. The last red screen is gone — entire app is Aurora. 102/102 tests; pushed to main.
- **Next session (Day 5):** verify on the physical Android phone (notifications fire, actions persist), add a notifications toggle in Settings, perf/contrast pass; then Day 6 release prep, Day 7 Play submit + web live.
- **Day 5 done:** on-device tested on Galaxy S25 FE (fixed Android build = core library desugaring). Fixed from real-device QA: dock above system-nav inset + bottom fade, legend off by default, add-sheet keyboard overflow, **date picker** (was hardcoded +30d), **collapsed recurring CCB/BoC**, removed dead Voice/Scan/Email buttons, hero pluralization, **date-aware seasonal rail** (no past events), footer not cropped, notifications toggle. ~110 tests; pushed to main (`6305a4f`).
- **Strategic reframe (2026-06-01):** user pushed back that a plain reminder app is too generic. Reframed to a **Canadian money co-pilot** (foundation of an app chain). Locked: hero = **found money**; differentiators = **penalty guardrails** + **"best move right now"** (NOT calculators — math is invisible); free = all deterministic, AI = premium-only; data = on-device rules+math + hosted JSON pack + free BoC Valet API. Wrote `docs/superpowers/specs/2026-06-01-money-copilot-strategy-design.md`; updated vision/README/monetization. **Standing rule:** keep project docs in sync with decisions.
- **Next:** plan + build the **Canadian Data Engine** + first **found-money + TFSA over-contribution guardrail** cards (writing-plans). Also pending: "be smart with notifications" (schedule only next occurrence per series, not every CCB/BoC) + finish the 1-week ship (Day 6 release prep, Day 7 submit).
