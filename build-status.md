# MapleAlerts — Build Status

> **Living document.** Auto-loaded at the start of every Claude Code session via a SessionStart hook, and updated before each session ends. It is the single source of truth for *where the build is* and *what happened across sessions*.

---

## Product

**MapleAlerts** — reminders for all Canadian financial deadlines (RRSP, TFSA, GIC, mortgage, BoC rate decisions, CCB, OSAP…).

**North-star goal:** best-in-class UX and a seamless experience.

**Vision:** a **deadline & reminder hub** — broaden across reminder categories (taxes, benefits, bills, subscriptions, renewals). May grow into a wider finance ecosystem later, but reminders are the core.

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

### Environment notes
- Web (Chrome/Edge): ✅ ready — primary dev/run target for now
- Windows desktop: needs VS "Desktop development with C++" workload (not installed)
- Android: needs Android Studio + SDK (not installed)
- Flutter SDK location: `C:\src\flutter`

### Next up
- [ ] Implementation plan (writing-plans skill) from the architecture build sequence
- [ ] Re-architecture implementation (feature-first + repository + unified Reminder)
- [ ] Run app on web to baseline current UX before refactor

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
- **Next session:** Flutter PATH + `flutter doctor`; user review of docs; then writing-plans → implementation.
