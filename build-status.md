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

### Canadian Data Engine — Slice 1 (TFSA room + guardrail) — DONE (133 tests, pushed)
- [x] **Pure-Dart engine module** `lib/engine/canadian_data_engine/` (no Flutter imports, single barrel). One rule = one pure fn returning a typed result carrying its own `sources` + `isEstimate`. `DataPack` override seam (`EmbeddedDataPack` now → hosted JSON later). TFSA limit table 2009–2026 embedded with `packVersion`.
- [x] **TFSA rule (TDD, 11 tests):** `room = Σ annual limits[max(2009, turned-18) .. asOf] − contributed`; statuses `notYetEligible / overContributed / nearLimit (≤$1k) / healthy`. Over-contribution preserves the true (negative) overage.
- [x] **Structured `MoneyProfile` store** (one JSON blob, `kMoneyProfileKey`) replacing scattered settings scalars; read-through migration of legacy `tfsa_birth_year`. Tested (4). `moneyProfileProvider` StateNotifier.
- [x] **Thin shared `MoneyInsight` view-model** + pure mapper (tested, 5) so Home renders a `List<MoneyInsight>` and a future "best move" surface has a uniform shape. `tfsaInsightsProvider` ties profile→engine→insights.
- [x] **UI:** generic `InsightCard` (eyebrow, headline, "How we got this" with sources, Estimate pill, "not financial advice", CTA) + `FoundMoneySection` + `TfsaSetupSheet` (the one number) wired into `HomeScreenV2` under the hero. Widget tests (3).
- [x] Spec: `docs/superpowers/specs/2026-06-01-canadian-data-engine-tfsa-slice-design.md`. Analyzer clean for all new code.
- Deferred (later slices): hosted JSON pack loader, BoC Valet client, RRSP/CCB/carbon/OAS rules, "best move" ranking engine, province/life-stage onboarding. **Verify-on-device + commit/push still pending.**

### Canadian Data Engine — Slice 2 (RRSP) — DONE (154 tests, pushed)
- [x] **First province- + income-aware rule.** `MoneyProfile` grew by 4 fields (province, annualIncome, rrspDeductionLimit, rrspContributed) — no new prefs keys, store unchanged (validates the structured-profile claim).
- [x] **Tax engine:** federal + all 13 provincial/territorial 2025 marginal-bracket tables (`tax_brackets.dart`, version-stamped); `tax_rule.marginalTaxRate(year, province, income)` = federal + provincial (reusable by future rules). **Verified vs source: federal, ON, BC, AB, QC; VERIFY flag on the rest.** QC excludes the federal abatement (slightly conservative).
- [x] **RRSP rule (TDD):** room = NOA deduction limit − contributed; **estimated tax savings = room × combined marginal rate** (the headline differentiator); next ~Mar-1 deadline + days-to; statuses `noLongerEligible (age>71, reuses birthYear) / overContributed (past $2,000 buffer) / withinBuffer / nearLimit / healthy`. 8 tests.
- [x] **Mapper (TDD, 6):** RRSP → `MoneyInsight`; healthy near deadline (≤60d) escalates to caution. **MoneyInsight generality test PASSED — zero new fields across two rules** (only a new `InsightAction.editRrspProfile`); tax-savings + deadline ride in subline/severity.
- [x] **Combined `moneyInsightsProvider` = TFSA + RRSP** — `FoundMoneySection` now renders the unified list (the "Home renders a list" payoff; step toward the future best-move ranking). `RrspSetupSheet` (province picker + income + limit + contributed) + action routing. Combined widget test.
- [x] Spec: `docs/superpowers/specs/2026-06-01-rrsp-slice-design.md`. Analyzer clean for new code.
- Pending (with TFSA): on-device visual check; push. Bracket-table verification pass for the 9 unverified jurisdictions before launch.

### Canadian Data Engine — Slice 3 (CCB) — DONE (163 tests, pushed)
- [x] **Pivot from Carbon Rebate (accuracy catch):** verified the **Canada Carbon Rebate for individuals is CLOSED** (final payment Apr 15 2025; fuel charge ended Apr 1 2025). A carbon found-money card would have shown money that no longer exists — built CCB instead. (Moat = accuracy; this is why we verify.)
- [x] **CCB rule (TDD, 5):** base by age band (under-6 $7,997 / 6–17 $6,748, Jul 2025–Jun 2026), two-step phase-out by child count (Step-1 7/13.5/19/23%, Step-2 3.2/5.7/8/9.5% + computed base over thresholds $37,487 / $81,222); monthly + annual; statuses `notEligible / zeroByIncome / receiving`. Verified vs CRA calc sheet.
- [x] **Profile +3 fields** (kidsUnder6, kids6to17, familyNetIncome=AFNI, distinct from RRSP individual income) — still no store changes.
- [x] **Mapper (TDD, 4)** + `ccbInsightsProvider`; `moneyInsightsProvider` now = TFSA + RRSP + CCB. `CcbSetupSheet` (kid-count steppers + family net income) + `editCcbProfile` routing. **MoneyInsight unchanged across THREE rules.**
- [x] Spec: `docs/superpowers/specs/2026-06-01-ccb-slice-design.md`. Analyzer clean for new code.
- **⚠️ UX debt (documented):** new users now see **3 setup prompts** (TFSA/RRSP/CCB), and CCB is irrelevant to non-parents. Next: an onboarding **"which apply to you"** gate and/or consolidating setup prompts into one — its own slice.

### Canadian Data Engine — Slice 4 (Topics gate) — DONE (170 tests, pushed)
- [x] **Resolves the 3-setup-prompt clutter** flagged in Slice 3. `MoneyTopic` enum (tfsa/rrsp/ccb) + `enabledTopicsProvider` (prefs-backed; defaults TFSA+RRSP on, CCB opt-in). Pure `partitionFoundMoney` helper + codec (TDD, 7).
- [x] **`FoundMoneySection` refactor:** filters insights to enabled topics; **collapses all unconfigured-but-enabled topics into ONE "Set up your money profile" card** (tappable row per topic) instead of N prompts; real cards for configured topics; **"Track more"** → `MoneyTopicsSheet` (enable/disable topics anytime). Empty-state prompt when nothing tracked.
- [x] **Onboarding step:** new final "What should we track?" page with topic toggles writing `enabledTopicsProvider` (the strategy's "onboarding profile decides which cards appear").
- [x] Spec/UX debt from Slice 3 **closed.** Widget tests updated for the persistent section. Analyzer clean.

### Canadian Data Engine — Slice 5 (Best move right now) — DONE (179 tests, pushed)
- [x] **The flagship differentiator.** Engine-level `bestMove(profile, asOf, dataPack) → BestMove?` reasons across the typed TFSA + RRSP results (NOT the lossy MoneyInsights — so **MoneyInsight stayed unchanged a 5th time**).
- [x] **Deterministic priority cascade:** RRSP over-contribution → TFSA over-contribution → RRSP deadline ≤60d (w/ room+savings) → opportunity tie-break (RRSP if marginal rate ≥30%, else TFSA, else RRSP). CCB excluded (automatic, not an action). Returns null when nothing actionable. TDD, 7 tests covering ordering + RRSP-vs-TFSA threshold + null cases.
- [x] `BestMove` carries `targetInsightId` ('rrsp_room'/'tfsa_room') so the app maps to a setup action via `MoneyTopic` — engine stays free of presentation enums.
- [x] **`BestMoveCard`** — prominent accent-gradient card pinned at the TOP of Home (above Found money), with the dollar value, a **"How we decided"** expansion (sources), "guidance, not advice" framing, and a kind-aware CTA that routes to the relevant sheet. Hidden when null. Widget tests (2).
- [x] Spec: `docs/superpowers/specs/2026-06-01-best-move-slice-design.md`. Analyzer clean.
- Deferred: GIC-maturity / cross-product moves (need GIC wired into the engine/profile); multi-move lists. `kRrspPreferredMarginalRate` (0.30) is a documented, tunable heuristic.

### Canadian Data Engine — Slice 6 (BoC live rate) — DONE (188 tests, pushed)
- [x] **First network dependency** + first card needing no user input. Added `http` package.
- [x] `BocRateService` fetches the **BoC policy rate** from the free **Valet API** (series V39079, no auth), with an **injectable fetcher** (tests never hit the network), **prefs caching + offline fallback** ("as of" date), graceful degradation on failure. `parseValetPolicyRate` + cache/fallback TDD'd (6 tests).
- [x] **Typical prime = policy + 2.20%**, clearly labelled "typical" (banks set prime; not claimed live). A later enhancement can fetch a verified prime series.
- [x] `bocRateProvider` (FutureProvider, refresh→cache→null) + always-shown `BocRateCard` ("Rates" section below Found money; offline hint; tap to refresh). Widget tests (3). Hidden until a rate is available.
- [x] Spec: `docs/superpowers/specs/2026-06-01-boc-rate-slice-design.md`. Analyzer clean.
- **⚠️ Web caveat:** Valet may not send CORS headers → live fetch can fail on Flutter **web** (works on Android/native); the offline-fallback path covers it (card hidden until first successful fetch). Verify on-device.

### Canadian Data Engine — Slice 7 (OAS clawback) — DONE (199 tests, pushed)
- [x] Completes the strategy's named found-money/guardrail set. **Reuses existing profile fields** (birthYear + annualIncome) — zero new MoneyProfile fields.
- [x] `oas_rule` (TDD, 6): age-65 gate, 15% recovery tax on net income over $93,454 (2025), capped at max OAS by age band (65–74 / 75+). Statuses `notYetEligible / safe / approaching / clawback`. Verified vs Service Canada.
- [x] `oasInsights` mapper (TDD, 5) → reuses the generic `InsightCard` (no new card type); `oasInsightsProvider` into `moneyInsightsProvider` (now TFSA+RRSP+CCB+OAS). `MoneyTopic.oas` (opt-in) + `OasSetupSheet`. **MoneyInsight unchanged a 6th time.**
- [x] Spec-less (template-following, captured here). Analyzer clean.

### Canadian Data Engine — Slice 8 (GIC → best move) — DONE (213 tests, pushed)
- [x] Realizes the strategy's **flagship cross-product move**: a maturing GIC + available room → "shelter it". On-device validation of slices 1–7 done first (S25, all rendered; BoC live fetch returned 2.25% as of May 29 2026).
- [x] **Single tracked GIC via profile** (gicAmount + gicMaturityDate; ISO in JSON) — not the orphaned V1 multi-GIC table. `gic_rule` (TDD, 5): status none/later/maturingSoon(≤60d)/matured + daysToMaturity.
- [x] **best_move new rung** (after over-contribution guardrails, before RRSP deadline): maturing GIC ≤60d + TFSA room (else RRSP) → `BestMoveKind.deadline`, value = min(GIC, room), target tfsa/rrsp. TDD (5): TFSA-first, room cap, RRSP fallback, guardrail-still-outranks, no-room→skip.
- [x] `gicInsights` mapper (TDD, 4) → generic InsightCard; `gicInsightsProvider` into combined list (now TFSA+RRSP+CCB+OAS+GIC). `MoneyTopic.gic` (opt-in) + `GicSetupSheet` (amount + native date picker). **MoneyInsight unchanged a 7th time.**
- [x] Spec: `docs/superpowers/specs/2026-06-02-gic-best-move-slice-design.md`. Analyzer clean.
- Deferred: multiple GICs (V1 SQLite table + list editor), GIC maturity-value math.

### Home reorder — alerts-first (committed)
- [x] Per user feedback ("show upcoming alerts to start off"): `HomeScreenV2` now leads with the hero → **category chips + Today/This Week/Upcoming reminders** → then best move → found money → rates → seasonal rail. The proven reminder feature is front-and-centre; the money co-pilot is the rich layer below.

### Canadian Data Engine — Slice 9 (FHSA) — DONE (223 tests, pushed)
- [x] First Home Savings Account found-money card (high relevance for the likely first-home-buyer audience). Reuses the tax engine for the deduction-savings line.
- [x] `fhsa_rule` (TDD, 6): single-number v1 — lifetime room = $40,000 − contributed; annual contributable = min($8,000, room); deduction tax savings = contributable × marginal rate; statuses healthy/nearLimit/overContributed. Verified vs CRA ($8k/yr, $40k lifetime, 1%/mo penalty).
- [x] `fhsaInsights` mapper (TDD, 4) → generic InsightCard; `fhsaInsightsProvider` into combined list (TFSA+RRSP+**FHSA**+CCB+OAS+GIC). `MoneyTopic.fhsa` (opt-in) + `FhsaSetupSheet`. **MoneyInsight unchanged an 8th time.** Profile +1 field (fhsaContributed).
- [x] Analyzer clean. Deferred: $8k annual carry-forward modelling (single-number lifetime v1), FHSA→best-move integration.

### FHSA → best move — DONE (227 tests, pushed)
- [x] Folded FHSA into the cross-account best-move cascade. New rungs: **FHSA over-contribution guardrail** (with the other guardrails), and an **FHSA opportunity that ranks ABOVE the RRSP/TFSA tie-break** — for first-home savers the FHSA is hard to beat (deductible like RRSP + tax-free on withdrawal), and opting into the topic signals the intent. Still ranks below time-bound moves (over-contributions, maturing GIC). TDD (4): FHSA beats RRSP/TFSA opportunity, FHSA over→guardrail, GIC still outranks, over-contribution still outranks.
- [x] Cascade now: RRSP-over → TFSA-over → FHSA-over → GIC-maturing → RRSP-deadline → **FHSA opportunity** → RRSP-vs-TFSA. 227 tests green, analyzer clean.

### Explainers layer — DONE (248 tests, pushed)
- [x] The strategy's "know-your-rights / jargon explainers" pillar. **Content-as-data in the engine** (`content/explainers.dart`, pure Dart, liftable): `Explainer` model + ~10 curated, source-cited entries — TFSA, RRSP, FHSA, CCB, OAS, GIC + jargon (marginal rate, contribution room, RRSP-vs-TFSA, AFNI). `explainerForInsightId` links each to its money card. TDD (4): every card topic has an explainer; jargon present; all have title/summary/points/source.
- [x] **`ExplainerSheet`** (plain-language detail: summary, key points, sources, "not advice" footer), **`LearnSection`** horizontal rail on Home (below Rates), and a **"Learn more" link on each money card** (`InsightCard.onLearnMore`, wired in `FoundMoneySection` via `explainerForInsightId`). Widget tests (2).
- [x] Accuracy: explainer figures match the embedded data packs, source/year stamped. Analyzer clean.

### Light theme + locale-aware money formatting — DONE (248 tests, pushed)
- [x] **Light/daylight theme:** `MapleColors.daylight` tokens (light canvas `#F4F7F6`, white surfaces, AA-deep accent `#0E7D52`) + `MapleSemantics.light` (deepened status hues) + `kDesignThemesLight` registry (all 4 auroras). `mapleThemeData` gained a `brightness` param (dark remains default — back-compat tested). Aurora/glass widgets render a light wash when ambient brightness is light.
- [x] **Theme-mode tweak:** `MapleTweaks.themeMode` ('system'|'light'|'dark', persisted; defaults dark) → `themeModeProvider` + `lightThemeDataProvider`/`darkThemeDataProvider` wired into `MaterialApp.router` (theme/darkTheme/themeMode). Tests (7).
- [x] **`MapleMoney`** (`lib/core/format/maple_money.dart`): locale-aware CAD formatting — `cad` (en_CA `$1,234.56` / fr_CA `1 234,56 $`), `cadAuto` (drops whole-dollar cents), `cadCompact` (`$1.2K`). App-level counterpart to the engine's dependency-free `formatDollars` (engine stays portable). Tests (9).
- [x] Also: `android/gradle.properties` Flutter-migrator flags (`builtInKotlin=false`, `newDsl=false`).

### Onboarding revamp — first-impression QA (249 tests, pushed)
- [x] **Fixed topics-page overflow** (user-reported, screenshot): six topic cards exceeded short viewports — "What should we track?" Column → ListView (scrolls under the bottom controls). Regression widget test reproduces the RenderFlex overflow at 1320×800 (red → green).
- [x] **Trimmed to 3 info pages + topics** (was 4+1): merged "Your day, handled" + "Calm nudges" into one; **dropped the $4.99 mention** from onboarding (user: premature for a first impression) — premium is discovered in-app/paywall instead.
- [x] **New page 3 = trust message:** "Free, private, yours — no account, no email, no sign-up. Your data stays on your phone." (the moat, stated up front). NOTE: this is now a product promise — any future email capture must be visibly optional (value-moment opt-in, never a gate).
- **Decision (2026-06-02): no email/sign-up at launch.** Distribution for the app chain via push + in-app cross-promo + post-launch opt-in lead magnet (deadline calendar email); accounts arrive naturally with premium sync. **Pre-launch candidate: anonymous aggregate analytics slice** (topic-enable rates, card engagement, retention) — product data needs no PII.

### Anonymous analytics — DONE (Aptabase, pre-launch slice)
- [x] **Why:** zero visibility into usage; post-launch decisions (next money topic: RESP/CESG vs mortgage renewal vs OSAP RAP; funnel health) should be data-driven. Spec `…/2026-06-02-anonymous-analytics-design.md`, plan `…plans/2026-06-02-anonymous-analytics.md`. Built subagent-driven (fresh implementer + spec review + quality review per task; reviews caught real bugs: page-0 funnel gap, explainer-id inconsistency, de-dupe null-key trap).
- [x] **Core:** `AnalyticsService` choke point (lib/core/analytics/) — injectable sink, per-call kill switch, session de-dupe (`insight_card_viewed`, `best_move_shown`), debug assert denylisting PII-adjacent prop names; fire-and-forget. `analyticsEnabledProvider` (prefs, default ON) + `analyticsProvider`; `Aptabase.init('A-US-2496453611')` fail-soft in main. aptabase_flutter 0.4.1.
- [x] **14 events live:** onboarding page_view(0–3 incl. initState page-0)/skip/complete(topics csv); topic_enabled/disabled; topics_sheet_opened; insight_card_viewed/cta_tapped; best_move_shown; explainer_opened (explainer id, both surfaces); reminder_added/done; paywall_viewed; purchase_started. **Never sent:** amounts, income, birth year, province, titles (assert-enforced).
- [x] **Privacy toggle** in You → Privacy ("Share anonymous usage stats" + caption), wired live. Spy-based widget tests across all surfaces (test/helpers/analytics_spy.dart).
- [ ] **Launch-day paperwork:** Play Data Safety form → declare anonymous "App interactions", not linked, not shared; privacy-policy line (in spec §Ops).

### User QA round 2 — chips, topics, explainers (276 tests, pushed)
- [x] **"Chips don't work" root-caused (user screenshot):** (1) built-ins only map to finance/family so 6 of 8 chips were always empty; (2) the add-sheet *detected* a category but **discarded it on save** (everything saved as bare `custom` — matched no chip); (3) empty category rendered literally nothing. Fixed: detected category persists in alert metadata + `AlertPresentation` reads it back; friendly per-category empty state ("No Vehicle reminders yet — tap + to add one").
- [x] **Topic discoverability (user couldn't find how to change topics):** "Choose what we track" row added to You tab (opens the topics sheet; the buried "Track more" link under Found money remains). `MoneyTopicsSheet` made scrollable (overflowed 64px on short viewports — same bug class as the onboarding topics page).
- [x] **Explainers → action (user suggestion):** account explainer sheets now show a **"Track \<topic\> on Home"** CTA when the topic isn't tracked — enables the topic + points to the setup card. Learn → act in one tap.
- [x] FHSA best-move copy fix (broken sentence when no income set). All TDD'd; 276 tests green.

### User QA round 3 — chip relevance + Household rename (pushed)
- [x] Money co-pilot layer shows only under **All** and **Finance** chips; seasonal rail under **All**/**Seasonal** — other chips show just their reminders (user: "don't bombard with not related details"). 'Home' category chip → **'Household'** (label only, id unchanged) — collided with the Home nav tab.

### Hosted data pack — DONE (297 tests; rules update OTA without app releases)
- [x] **The currency mechanism** from `…/2026-06-02-hosted-data-pack-design.md`: `RemoteDataPack.fromJson` (pure Dart, per-field fallback to embedded, schemaVersion gate) + `DataPackService` (injectable fetcher, prefs cache, 24h TTL, fail-soft) + `dataPackProvider` (newest-pack-wins: remote only when packVersion > `kEmbeddedPackVersion`) wired into all 6 rule call sites + fire-and-forget `initDataPack` at startup.
- [x] **Pack file** `web/datapack/pack.json` generated from the embedded tables by `tool/generate_data_pack.dart` (rerun after any embedded change); a sanity test reads the shipped file from disk and pins it equal to embedded. Served at `https://sss09.github.io/MapleAlerts/datapack/pack.json` (CORS-open; works Android + web).
- [x] **Trust line** in You → Privacy: "Canadian data: v2026-06-02 · built-in / · updated over the air".
- [x] **CI fix (found during verification):** `pages.yml` only deployed from a dead dev branch with Flutter 3.32 — the live site had been stale since the branch merge and the pack could never ship. Now deploys from `main` with Flutter 3.44.
- **Ops loop:** Nov–Dec (CRA 2027 limits — FIRST REAL UPDATE DUE), July (CCB year), budgets → edit pack.json, cite source in commit, bump packVersion, push. Each release: refresh embedded tables + `dart run tool/generate_data_pack.dart` + bump `kEmbeddedPackVersion`.

### Notifications — current behaviour + backlog
- [x] **Within-7-days gap FIXED:** `reminderFireDate()` (pure, TDD 6 tests) picks the earliest sensible lead still in the future — 7d→1d→same-day 9am→~5min from now→null only if the deadline passed. Previously anything <7d out scheduled nothing. Android fires app-closed; web no-ops (browser limitation); iOS unverified.
- [ ] **POST-LAUNCH: multi-lead-time series.** Each reminder fires ONE notification today. The category registry already defines escalating leads (finance 60/30/7/1, government 30/7/1) — the "calm escalating nudges" intent. Upgrade: `scheduleAlert` schedules one notification per `category.defaultLeadTimes` entry still in the future, unique IDs per lead. ~half-day slice. Not launch-blocking (one well-timed nudge delivers the core value).
- [ ] POST-LAUNCH: optional batched "morning digest" instead of per-reminder notifications.

### CRA data-source watcher — DONE (327 tests; scheduled Action live on main)

**Mechanism:** A `dart run tool/check_data_sources.dart` script fetches the 5 indexed CRA figures, applies per-source sanity bands (min/max/step), diffs against the current `web/datapack/pack.json`, and exits with a structured code:
- **exit 0** — all figures match; no action.
- **exit 10** — an in-band figure changed; rewrites `pack.json` + writes `.data-watch-summary.txt`.
- **exit 20** — a source could not be parsed (page moved, regex anchor gone); writes `.data-watch-summary.txt`.

The GitHub Action (`.github/workflows/data-watch.yml`) branches on that exit code:
- **code 10 → `peter-evans/create-pull-request@v6`** — opens a PR on branch `data-watch/update` with the summary as body and `web/datapack/pack.json` as the only changed file. Human merge gate is the PR review.
- **code 20 → `actions/github-script@v7`** — opens a GitHub issue titled "data-watch: could not parse a CRA source" with the parse-failure detail in the body.

**Schedule:** monthly on the 1st + weekly during indexation windows (Nov–Jan and Jun–Jul, when CRA publishes next-year limits).

**5 figures watched:**
1. TFSA annual limit (step-$500 band, $5k–$20k)
2. RRSP dollar maximum ($25k–$60k, step-$10)
3. OAS recovery threshold ($60k–$200k)
4. CCB max — children under 6 ($5k–$12k)
5. CCB max — children 6–17 ($4k–$11k) + CCB phase-out thresholds 1 & 2

Tax brackets are intentionally excluded — they are multi-row tables with many derived figures (not single indexable numbers) and require a manual review pass; they stay in `tax_brackets.dart` with a manual edit cycle.

**Human merge gate:** the PR step only stages `web/datapack/pack.json`; a human must review the diff and merge. The tool never auto-merges.

**Maintenance caveat:** if the "Check CRA sources" step exits 20 in CI, it means CRA moved or restructured a page. The fix is: capture the new HTML into the relevant `test/tool/fixtures/<id>_good.html`, update the parser regex in `tool/data_sources/parsers.dart` to match the new anchor, run `flutter test test/tool/parsers_test.dart` to verify, then push.

**Local dry-run caveat:** Dart VM outbound HTTP is blocked in the dev sandbox (Dart `http.get` to canada.ca times out; `curl` via bash works). All unit logic (parsers, sanity bands, decision/outcome, pack-merge) is fully tested offline via HTML fixtures (327 tests pass).

**CI network caveat (verified 2026-06-03):** canada.ca's CDN/WAF silently drops or blocks HTTP connections from GitHub Actions runner IPs — every `http.get` call hangs until the timeout fires (`TimeoutException after 0:00:30.000000: Future not completed`), which surfaces as exit code 20 (fetch failure) and correctly triggers the issue-open step. This is an infrastructure-level block, NOT a parser failure. The two-run live test confirmed the workflow branching logic is correct (exit-code capture, `continue-on-error`, the PR-skip/issue-open conditional all work). The issue-open step fired and created GitHub issue #1. The parsers themselves are verified correct via offline fixtures.

**Pending fix:** The fetch mechanism needs to be replaced or bypassed for the github.com runner environment. Options: (1) pre-fetch pages via a scheduled GitHub Pages or CF Worker proxy; (2) use a self-hosted runner on a non-blocked IP; (3) add a step-level `curl` pre-fetch that writes temp files, then have the Dart tool read local files instead of fetching. This is a deployment/ops concern — all application logic is correct and tested.

### Deadline-coverage audit + fixes (329 tests, pushed)
- [x] **Accuracy bug fixed:** removed the **Canada Carbon Rebate** from the seasonal rail (CCR for individuals ended Apr 2025) — it was surfacing money that no longer exists, the exact error the CCB pivot guarded against.
- [x] **Added 5 universal deadlines** to the seasonal rail: self-employed tax filing (Jun 15), RESP/CESG contribution cutoff (Dec 31), FHSA room opens (Jan 1), charitable donation cutoff (Dec 31), quarterly tax instalments (Mar/Jun/Sep/Dec 15).
- [x] Removed stale "max $31,560 for 2024" from the RRSP alert copy → generic (18% of prior-year income up to the CRA max, minus pension adjustment).
- [ ] **DEFERRED — OAS/CPP/GIS monthly payment dates:** NOT shipped. The "third-to-last business day" rule is **wrong for December** (paid ~Dec 22 pre-holidays, verified vs 2025 schedule); CRA publishes these per year like BoC dates. Needs the verified published schedule — natural fit for the data-pack/watcher. High value for seniors.
- [ ] **DEFERRED — situation/age-specific hard deadlines (money-engine, needs birthYear/profile):** RRSP→RRIF conversion by Dec 31 of the year you turn 71 (miss = whole RRSP deregistered/taxed — high stakes); HBP annual repayment (tied to RRSP deadline); RDSP contribution (Dec 31, disability grant/bond).
- [ ] **DEFERRED — province-specific benefit dates:** Ontario Trillium, BC/QC family benefits, Quebec's separate filing. Engine is province-aware for tax only; benefit dates are federal-only for now.

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

### 2026-06-03 — Session 4
- **CRA data-source watcher — DONE (Tasks 1–5 of `2026-06-02-data-source-watcher.md`):** `WatchedSource` + sanity-band evaluation, CRA HTML parsers (TFSA, RRSP, OAS, CCB×4) against captured fixtures, pack-merge helpers, runner with failure-precedence exit codes (0/10/20), I/O glue (`tool/check_data_sources.dart`), GitHub Action (`.github/workflows/data-watch.yml` — cron monthly+weekly indexation windows, PR-on-change, issue-on-failure, human merge gate). `.gitignore` updated (`.data-watch-summary.txt`). `build-status.md` updated with full mechanism + caveats. 327 tests green, analyzer clean (14 pre-existing infos unchanged).
- Live-fetch verification: two workflow runs triggered. Both exited code 20 (parse failure) because canada.ca's CDN/WAF blocks HTTP connections from GitHub Actions runner IPs — every source times out (`TimeoutException after 0:00:30.000000`). This is an infrastructure block, NOT a parser regression. Branching logic confirmed correct: "Open PR on change" was skipped on both runs; "Open issue on parse failure" fired and created GitHub issue #1. All parsers verified correct via offline HTML fixtures. Pending fix: replace Dart http.get with a runner-compatible fetch mechanism (curl pre-fetch or proxy).

### 2026-06-02 → 06-03 — Session 3 (wrap)
**Where we resume:** Day 6 **release prep** — app icon (dark maple), store screenshots (from device), listing copy, Android release signing (keystore), signed AAB; then Day 7 Play internal-testing upload + web live. **User critical-path: create the Google Play Developer account ($25)** — identity verification is the slow part, start it first. New-phone on-device test is still pending (phone wasn't exposing USB debugging; enable File-transfer + USB debugging, accept the prompt, then `adb` will see it and I can install).

**Session 3 arc (all pushed, ~329 tests green, analyzer clean):**
- Onboarding QA → analytics slice → 3 rounds of user QA fixes → hosted data pack → data-source watcher → deadline-coverage audit. ~30 commits.
- **Hosted data pack DONE** (rules update OTA, no app release) + **CI fix**: Pages deploy was dead on an old branch — now deploys from `main`; pack live at `…/datapack/pack.json`.
- **CRA data-source watcher built** (auto-detect CRA changes → draft PR). Logic fully verified; **fetch blocked** — canada.ca's CDN drops datacenter IPs (GH runner + local Dart VM). Cron disabled → manual `workflow_dispatch` only; unblock = curl-prefetch experiment or proxy (logged above).
- **Deadline audit**: removed discontinued Carbon Rebate (accuracy bug), added 5 universal deadlines; deferred OAS/CPP payment dates (need verified schedule), RRIF@71/HBP/RDSP (money-engine), province-specific (later).
- **Notification gap fixed**: reminders <7 days out now notify (`reminderFireDate`); multi-lead-time series logged post-launch.
- **Decisions locked**: no email/signups at launch; anonymous analytics only (Aptabase). Git author = sohail09.syed@gmail.com (repo-local).

**Detailed Session-3 notes below.**

### 2026-06-02 — Session 3
- **Onboarding first-impression QA (user walkthrough):** fixed the topics-page 122px overflow (ListView + regression test), trimmed onboarding to 3 info pages + topics, replaced the $4.99 pitch with the trust page ("no account, no email — data stays on your phone"). Pushed.
- **Decision — no email/sign-ups at launch:** distribution for the app chain = push + in-app cross-promo + post-launch opt-in lead magnet; accounts arrive with premium sync. Product data comes from anonymous analytics instead.
- **Anonymous analytics slice (brainstorm → spec → plan → subagent-driven build):** Aptabase (key `A-US-2496453611`, user's account created), on-by-default + You→Privacy toggle, 14 events, PII denylist assert, session de-dupe, fail-soft init. Two-stage reviews caught: onboarding page-0 never tracked (fixed via initState), explainer_opened id inconsistency between Home cards and Learn rail (fixed), de-dupe null-key trap (hardened). Full suite green; live first-event smoke vs the Aptabase dashboard pending user confirmation.
- **Git identity:** repo-local author set to Sohail Syed <sohail09.syed@gmail.com> (work email stays global for Contruent repos). Earlier commits keep the old author unless a history rewrite is requested.
- Reviewed the uncommitted WIP found at session start (light theme + money formatter — built at the tail of Session 2, not yet documented/committed).
- Verified the WIP: full suite **248 tests green** (light-theme tests + MapleMoney tests confirmed in the run), `flutter analyze` clean for all new/changed files (14 pre-existing info lints in old V1 screens/tests only).
- Committed in logical pieces (light theme; MapleMoney CAD formatter; gradle migrator flags; this doc update) and **pushed everything to GitHub** — including the previously unpushed explainers commit (`0de17dd`). origin/main is now fully up to date with all 9 engine slices + best-move cascade + explainers + light theme.
- Remaining before launch: Day 6 release prep (icon, screenshots, listing, signing, AAB, web build), Day 7 Play upload + web live; verify the 9 unverified provincial tax-bracket tables; Google Play account (user).

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
- **Explainers layer done:** the strategy's know-your-rights pillar. Content-as-data in the engine (`content/explainers.dart`, ~10 verified entries: accounts + jargon), `ExplainerSheet` detail, `LearnSection` rail on Home, and a "Learn more" link on each money card linking to its explainer. 248 tests green, analyzer clean.
- **Canadian Data Engine — Slice 9 done (FHSA):** First Home Savings Account found-money card (single-number v1: lifetime room $40k − contributed, annual contributable min($8k, room), deduction savings via the tax engine, over-contribution guardrail; verified vs CRA). MoneyTopic.fhsa + FhsaSetupSheet; MoneyInsight unchanged an 8th time. Also reordered Home to lead with upcoming alerts (per user feedback), money co-pilot below. 223 tests green, analyzer clean.
- **Canadian Data Engine — Slice 8 done (GIC → best move):** the flagship cross-product move. After on-device validation of slices 1–7 on the S25 (all rendered; BoC live rate fetched 2.25%), added a single tracked GIC via the profile + `gic_rule`, a new best-move rung (maturing GIC ≤60d + room → "shelter it", TFSA-first), the GIC mapper/topic/`GicSetupSheet` (with native date picker). MoneyInsight unchanged a 7th time. 213 tests green, analyzer clean. Spec: `…/2026-06-02-gic-best-move-slice-design.md`.
- **Canadian Data Engine — Slice 7 done (OAS clawback):** completes the named found-money/guardrail set. `oas_rule` (15% recovery tax over $93,454, capped at max OAS by age band; verified vs Service Canada) reusing existing birthYear+income — zero new profile fields. Reuses the generic InsightCard; `MoneyTopic.oas` opt-in + `OasSetupSheet`. MoneyInsight unchanged a 6th time. 199 tests green, analyzer clean.
- **Canadian Data Engine — Slice 6 done (BoC live rate):** first network slice. `BocRateService` fetches the BoC policy rate from the free Valet API (V39079) with an injectable fetcher, prefs caching, and offline fallback; typical prime = policy+2.20% (labelled). `BocRateCard` in a "Rates" section. Added `http` dep. 188 tests green, analyzer clean. Web CORS caveat noted. Spec: `…/2026-06-01-boc-rate-slice-design.md`.
- **Canadian Data Engine — Slice 5 done (Best move right now):** the flagship. Engine-level `bestMove` reasons across typed TFSA/RRSP results via a deterministic cascade (fix penalty → deadline → RRSP-vs-TFSA by marginal-rate threshold). Prominent top-of-Home `BestMoveCard` with "how we decided" + CTA routing. MoneyInsight unchanged a 5th time. 179 tests green, analyzer clean. Spec: `…/2026-06-01-best-move-slice-design.md`.
- **Canadian Data Engine — Slice 4 done (Topics gate):** closed the 3-setup-prompt clutter from Slice 3. Added `MoneyTopic` + prefs-backed `enabledTopicsProvider` (TFSA+RRSP default on, CCB opt-in), a pure `partitionFoundMoney` helper, refactored `FoundMoneySection` to filter by enabled topics + collapse setup prompts into one "Set up your money profile" card + a "Track more" sheet, and added a "What should we track?" onboarding page. 170 tests green, analyzer clean.
- **Canadian Data Engine — Slice 3 done (CCB):** chose Carbon Rebate next, then web-verified it's **discontinued** (final individual payment Apr 2025) → pivoted to CCB to avoid shipping an inaccurate card. Built the CCB rule (age-band base + two-step income phase-out, verified vs CRA Jul 2025–Jun 2026 sheet), mapper, provider, and `CcbSetupSheet`. Profile +3 fields, no store changes; **MoneyInsight now unchanged across three rules.** 163 tests green, analyzer clean. Flagged UX debt: 3 setup prompts for new users → needs an onboarding "which apply to you" gate. Spec: `…/2026-06-01-ccb-slice-design.md`.
- **Canadian Data Engine — Slice 2 done (RRSP):** brainstormed → spec → TDD end-to-end in auto-mode (dev day; on-device testing batched to the end). Added the tax engine (federal + 13 provincial 2025 bracket tables + `marginalTaxRate`), the RRSP rule (room from NOA limit, **tax-savings = room × marginal rate**, deadline, $2k-buffer + age-71 guardrails), the RRSP mapper, the combined `moneyInsightsProvider`, and `RrspSetupSheet`. Profile grew by 4 fields with zero store changes; **`MoneyInsight` held across two rules with no new fields** (generality test passed). Federal/ON/BC/AB/QC brackets web-verified; rest flagged. 154 tests green, analyzer clean. Spec: `…/2026-06-01-rrsp-slice-design.md`.
- **Canadian Data Engine — Slice 1 done (TFSA):** brainstormed → spec → TDD-implemented end-to-end. Built the pure-Dart engine skeleton (rule + `DataPack` seam + embedded 2009–2026 limit table), the structured `MoneyProfile` store (with legacy migration), the thin shared `MoneyInsight` view-model + mapper, and the Found-money UI (`InsightCard`/`FoundMoneySection`/`TfsaSetupSheet`) wired under the Home hero. 133 tests green, analyzer clean. Deliberately folded in two sustainability seams (structured profile + uniform insight) the user asked for. Spec: `…/2026-06-01-canadian-data-engine-tfsa-slice-design.md`. **Pending:** confirm 2026 CRA limit, on-device visual check, commit + push.
