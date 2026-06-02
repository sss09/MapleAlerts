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

### Canadian Data Engine — Slice 1 (TFSA room + guardrail) — DONE (133 tests, on main pending)
- [x] **Pure-Dart engine module** `lib/engine/canadian_data_engine/` (no Flutter imports, single barrel). One rule = one pure fn returning a typed result carrying its own `sources` + `isEstimate`. `DataPack` override seam (`EmbeddedDataPack` now → hosted JSON later). TFSA limit table 2009–2026 embedded with `packVersion`.
- [x] **TFSA rule (TDD, 11 tests):** `room = Σ annual limits[max(2009, turned-18) .. asOf] − contributed`; statuses `notYetEligible / overContributed / nearLimit (≤$1k) / healthy`. Over-contribution preserves the true (negative) overage.
- [x] **Structured `MoneyProfile` store** (one JSON blob, `kMoneyProfileKey`) replacing scattered settings scalars; read-through migration of legacy `tfsa_birth_year`. Tested (4). `moneyProfileProvider` StateNotifier.
- [x] **Thin shared `MoneyInsight` view-model** + pure mapper (tested, 5) so Home renders a `List<MoneyInsight>` and a future "best move" surface has a uniform shape. `tfsaInsightsProvider` ties profile→engine→insights.
- [x] **UI:** generic `InsightCard` (eyebrow, headline, "How we got this" with sources, Estimate pill, "not financial advice", CTA) + `FoundMoneySection` + `TfsaSetupSheet` (the one number) wired into `HomeScreenV2` under the hero. Widget tests (3).
- [x] Spec: `docs/superpowers/specs/2026-06-01-canadian-data-engine-tfsa-slice-design.md`. Analyzer clean for all new code.
- Deferred (later slices): hosted JSON pack loader, BoC Valet client, RRSP/CCB/carbon/OAS rules, "best move" ranking engine, province/life-stage onboarding. **Verify-on-device + commit/push still pending.**

### Canadian Data Engine — Slice 2 (RRSP) — DONE (154 tests, on main pending)
- [x] **First province- + income-aware rule.** `MoneyProfile` grew by 4 fields (province, annualIncome, rrspDeductionLimit, rrspContributed) — no new prefs keys, store unchanged (validates the structured-profile claim).
- [x] **Tax engine:** federal + all 13 provincial/territorial 2025 marginal-bracket tables (`tax_brackets.dart`, version-stamped); `tax_rule.marginalTaxRate(year, province, income)` = federal + provincial (reusable by future rules). **Verified vs source: federal, ON, BC, AB, QC; VERIFY flag on the rest.** QC excludes the federal abatement (slightly conservative).
- [x] **RRSP rule (TDD):** room = NOA deduction limit − contributed; **estimated tax savings = room × combined marginal rate** (the headline differentiator); next ~Mar-1 deadline + days-to; statuses `noLongerEligible (age>71, reuses birthYear) / overContributed (past $2,000 buffer) / withinBuffer / nearLimit / healthy`. 8 tests.
- [x] **Mapper (TDD, 6):** RRSP → `MoneyInsight`; healthy near deadline (≤60d) escalates to caution. **MoneyInsight generality test PASSED — zero new fields across two rules** (only a new `InsightAction.editRrspProfile`); tax-savings + deadline ride in subline/severity.
- [x] **Combined `moneyInsightsProvider` = TFSA + RRSP** — `FoundMoneySection` now renders the unified list (the "Home renders a list" payoff; step toward the future best-move ranking). `RrspSetupSheet` (province picker + income + limit + contributed) + action routing. Combined widget test.
- [x] Spec: `docs/superpowers/specs/2026-06-01-rrsp-slice-design.md`. Analyzer clean for new code.
- Pending (with TFSA): on-device visual check; push. Bracket-table verification pass for the 9 unverified jurisdictions before launch.

### Canadian Data Engine — Slice 3 (CCB) — DONE (163 tests, on main pending)
- [x] **Pivot from Carbon Rebate (accuracy catch):** verified the **Canada Carbon Rebate for individuals is CLOSED** (final payment Apr 15 2025; fuel charge ended Apr 1 2025). A carbon found-money card would have shown money that no longer exists — built CCB instead. (Moat = accuracy; this is why we verify.)
- [x] **CCB rule (TDD, 5):** base by age band (under-6 $7,997 / 6–17 $6,748, Jul 2025–Jun 2026), two-step phase-out by child count (Step-1 7/13.5/19/23%, Step-2 3.2/5.7/8/9.5% + computed base over thresholds $37,487 / $81,222); monthly + annual; statuses `notEligible / zeroByIncome / receiving`. Verified vs CRA calc sheet.
- [x] **Profile +3 fields** (kidsUnder6, kids6to17, familyNetIncome=AFNI, distinct from RRSP individual income) — still no store changes.
- [x] **Mapper (TDD, 4)** + `ccbInsightsProvider`; `moneyInsightsProvider` now = TFSA + RRSP + CCB. `CcbSetupSheet` (kid-count steppers + family net income) + `editCcbProfile` routing. **MoneyInsight unchanged across THREE rules.**
- [x] Spec: `docs/superpowers/specs/2026-06-01-ccb-slice-design.md`. Analyzer clean for new code.
- **⚠️ UX debt (documented):** new users now see **3 setup prompts** (TFSA/RRSP/CCB), and CCB is irrelevant to non-parents. Next: an onboarding **"which apply to you"** gate and/or consolidating setup prompts into one — its own slice.

### Canadian Data Engine — Slice 4 (Topics gate) — DONE (170 tests, on main pending)
- [x] **Resolves the 3-setup-prompt clutter** flagged in Slice 3. `MoneyTopic` enum (tfsa/rrsp/ccb) + `enabledTopicsProvider` (prefs-backed; defaults TFSA+RRSP on, CCB opt-in). Pure `partitionFoundMoney` helper + codec (TDD, 7).
- [x] **`FoundMoneySection` refactor:** filters insights to enabled topics; **collapses all unconfigured-but-enabled topics into ONE "Set up your money profile" card** (tappable row per topic) instead of N prompts; real cards for configured topics; **"Track more"** → `MoneyTopicsSheet` (enable/disable topics anytime). Empty-state prompt when nothing tracked.
- [x] **Onboarding step:** new final "What should we track?" page with topic toggles writing `enabledTopicsProvider` (the strategy's "onboarding profile decides which cards appear").
- [x] Spec/UX debt from Slice 3 **closed.** Widget tests updated for the persistent section. Analyzer clean.

### Canadian Data Engine — Slice 5 (Best move right now) — DONE (179 tests, on main pending)
- [x] **The flagship differentiator.** Engine-level `bestMove(profile, asOf, dataPack) → BestMove?` reasons across the typed TFSA + RRSP results (NOT the lossy MoneyInsights — so **MoneyInsight stayed unchanged a 5th time**).
- [x] **Deterministic priority cascade:** RRSP over-contribution → TFSA over-contribution → RRSP deadline ≤60d (w/ room+savings) → opportunity tie-break (RRSP if marginal rate ≥30%, else TFSA, else RRSP). CCB excluded (automatic, not an action). Returns null when nothing actionable. TDD, 7 tests covering ordering + RRSP-vs-TFSA threshold + null cases.
- [x] `BestMove` carries `targetInsightId` ('rrsp_room'/'tfsa_room') so the app maps to a setup action via `MoneyTopic` — engine stays free of presentation enums.
- [x] **`BestMoveCard`** — prominent accent-gradient card pinned at the TOP of Home (above Found money), with the dollar value, a **"How we decided"** expansion (sources), "guidance, not advice" framing, and a kind-aware CTA that routes to the relevant sheet. Hidden when null. Widget tests (2).
- [x] Spec: `docs/superpowers/specs/2026-06-01-best-move-slice-design.md`. Analyzer clean.
- Deferred: GIC-maturity / cross-product moves (need GIC wired into the engine/profile); multi-move lists. `kRrspPreferredMarginalRate` (0.30) is a documented, tunable heuristic.

### Canadian Data Engine — Slice 6 (BoC live rate) — DONE (188 tests, on main pending)
- [x] **First network dependency** + first card needing no user input. Added `http` package.
- [x] `BocRateService` fetches the **BoC policy rate** from the free **Valet API** (series V39079, no auth), with an **injectable fetcher** (tests never hit the network), **prefs caching + offline fallback** ("as of" date), graceful degradation on failure. `parseValetPolicyRate` + cache/fallback TDD'd (6 tests).
- [x] **Typical prime = policy + 2.20%**, clearly labelled "typical" (banks set prime; not claimed live). A later enhancement can fetch a verified prime series.
- [x] `bocRateProvider` (FutureProvider, refresh→cache→null) + always-shown `BocRateCard` ("Rates" section below Found money; offline hint; tap to refresh). Widget tests (3). Hidden until a rate is available.
- [x] Spec: `docs/superpowers/specs/2026-06-01-boc-rate-slice-design.md`. Analyzer clean.
- **⚠️ Web caveat:** Valet may not send CORS headers → live fetch can fail on Flutter **web** (works on Android/native); the offline-fallback path covers it (card hidden until first successful fetch). Verify on-device.

### Canadian Data Engine — Slice 7 (OAS clawback) — DONE (199 tests, on main pending)
- [x] Completes the strategy's named found-money/guardrail set. **Reuses existing profile fields** (birthYear + annualIncome) — zero new MoneyProfile fields.
- [x] `oas_rule` (TDD, 6): age-65 gate, 15% recovery tax on net income over $93,454 (2025), capped at max OAS by age band (65–74 / 75+). Statuses `notYetEligible / safe / approaching / clawback`. Verified vs Service Canada.
- [x] `oasInsights` mapper (TDD, 5) → reuses the generic `InsightCard` (no new card type); `oasInsightsProvider` into `moneyInsightsProvider` (now TFSA+RRSP+CCB+OAS). `MoneyTopic.oas` (opt-in) + `OasSetupSheet`. **MoneyInsight unchanged a 6th time.**
- [x] Spec-less (template-following, captured here). Analyzer clean.

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
- **Canadian Data Engine — Slice 7 done (OAS clawback):** completes the named found-money/guardrail set. `oas_rule` (15% recovery tax over $93,454, capped at max OAS by age band; verified vs Service Canada) reusing existing birthYear+income — zero new profile fields. Reuses the generic InsightCard; `MoneyTopic.oas` opt-in + `OasSetupSheet`. MoneyInsight unchanged a 6th time. 199 tests green, analyzer clean.
- **Canadian Data Engine — Slice 6 done (BoC live rate):** first network slice. `BocRateService` fetches the BoC policy rate from the free Valet API (V39079) with an injectable fetcher, prefs caching, and offline fallback; typical prime = policy+2.20% (labelled). `BocRateCard` in a "Rates" section. Added `http` dep. 188 tests green, analyzer clean. Web CORS caveat noted. Spec: `…/2026-06-01-boc-rate-slice-design.md`.
- **Canadian Data Engine — Slice 5 done (Best move right now):** the flagship. Engine-level `bestMove` reasons across typed TFSA/RRSP results via a deterministic cascade (fix penalty → deadline → RRSP-vs-TFSA by marginal-rate threshold). Prominent top-of-Home `BestMoveCard` with "how we decided" + CTA routing. MoneyInsight unchanged a 5th time. 179 tests green, analyzer clean. Spec: `…/2026-06-01-best-move-slice-design.md`.
- **Canadian Data Engine — Slice 4 done (Topics gate):** closed the 3-setup-prompt clutter from Slice 3. Added `MoneyTopic` + prefs-backed `enabledTopicsProvider` (TFSA+RRSP default on, CCB opt-in), a pure `partitionFoundMoney` helper, refactored `FoundMoneySection` to filter by enabled topics + collapse setup prompts into one "Set up your money profile" card + a "Track more" sheet, and added a "What should we track?" onboarding page. 170 tests green, analyzer clean.
- **Canadian Data Engine — Slice 3 done (CCB):** chose Carbon Rebate next, then web-verified it's **discontinued** (final individual payment Apr 2025) → pivoted to CCB to avoid shipping an inaccurate card. Built the CCB rule (age-band base + two-step income phase-out, verified vs CRA Jul 2025–Jun 2026 sheet), mapper, provider, and `CcbSetupSheet`. Profile +3 fields, no store changes; **MoneyInsight now unchanged across three rules.** 163 tests green, analyzer clean. Flagged UX debt: 3 setup prompts for new users → needs an onboarding "which apply to you" gate. Spec: `…/2026-06-01-ccb-slice-design.md`.
- **Canadian Data Engine — Slice 2 done (RRSP):** brainstormed → spec → TDD end-to-end in auto-mode (dev day; on-device testing batched to the end). Added the tax engine (federal + 13 provincial 2025 bracket tables + `marginalTaxRate`), the RRSP rule (room from NOA limit, **tax-savings = room × marginal rate**, deadline, $2k-buffer + age-71 guardrails), the RRSP mapper, the combined `moneyInsightsProvider`, and `RrspSetupSheet`. Profile grew by 4 fields with zero store changes; **`MoneyInsight` held across two rules with no new fields** (generality test passed). Federal/ON/BC/AB/QC brackets web-verified; rest flagged. 154 tests green, analyzer clean. Spec: `…/2026-06-01-rrsp-slice-design.md`.
- **Canadian Data Engine — Slice 1 done (TFSA):** brainstormed → spec → TDD-implemented end-to-end. Built the pure-Dart engine skeleton (rule + `DataPack` seam + embedded 2009–2026 limit table), the structured `MoneyProfile` store (with legacy migration), the thin shared `MoneyInsight` view-model + mapper, and the Found-money UI (`InsightCard`/`FoundMoneySection`/`TfsaSetupSheet`) wired under the Home hero. 133 tests green, analyzer clean. Deliberately folded in two sustainability seams (structured profile + uniform insight) the user asked for. Spec: `…/2026-06-01-canadian-data-engine-tfsa-slice-design.md`. **Pending:** confirm 2026 CRA limit, on-device visual check, commit + push.
