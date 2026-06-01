# MapleAlerts — Architecture Design

**Date:** 2026-05-31
**Status:** Approved (sections 1–3 confirmed; section 4 presented)
**Related:** [Product docs](../../product/README.md) · [MVP](../../product/01-mvp.md) · [Alert Catalog](../../product/02-alert-catalog.md)

## Context & goals
MapleAlerts starts as a Canadian financial **deadline & reminder hub** and must grow across many reminder categories (taxes, benefits, bills, renewals) without rewrites. North star: **best UX / seamless experience.**

**Decisions locked in brainstorming:**
| Decision | Choice |
|----------|--------|
| Vision/scope | Deadline & reminder hub (grow categories; not net-worth/advisory) |
| Data & sync | **Local-first** now; clean repository layer so cloud sync drops in later |
| Refactor appetite | **Re-architect now** while the app is small (~10 screens) |
| Project structure | **Feature-first + repository layer** |
| Reminder model | **Unified `Reminder` entity + category registry** (recurrence-aware) |

## Current state (as-is)
- Layer-based folders (`models/services/providers/screens/widgets`).
- `DatabaseService` singleton = a growing "god object"; 3 hand-coded tables (`alerts`, `gics`, `mortgages`); **local-only**.
- Riverpod `StateNotifier`s talk **directly** to the DB singleton (no abstraction).
- `CanadianDatesService` regenerates built-in alerts per-year.
- Firebase deps present (auth/firestore/messaging) but **not wired** into the data layer.

**Scaling smells:** god-object DB, no repository abstraction, layer folders that crowd as categories multiply, no sync story.

---

## Section 1 — Project structure
Feature-first vertical slices + `core/` for cross-cutting infra.

```
lib/
  main.dart · app.dart
  core/            di, database (app_database + migrations), notifications,
                   result, router, theme, utils, constants
  features/
    reminders/
      domain/      reminder.dart, reminder_schedule.dart,
                   reminder_category.dart, reminder_repository.dart (interface)
      data/        reminder_local_datasource.dart, reminder_dto.dart,
                   local_reminder_repository.dart
      presentation/ providers/, screens/, widgets/
    tracked_items/ GIC + mortgage (sources that DERIVE reminders)
    canadian_dates/ rules that GENERATE system reminders
    subscription/  RevenueCat + paywall
    onboarding/
  shared/widgets/  generic UI (section_header, affiliate_card)
```

**Boundary rules**
- Presentation imports only the repository **interface** from `domain/` — never `data/` or SQLite. → sync becomes a one-line DI swap.
- `canadian_dates` and `tracked_items` are **reminder sources**: they produce `Reminder`s that flow through the same repository + notification pipeline. No parallel plumbing.
- `core/database` owns versioned migrations.

## Section 2 — Reminder domain model

```dart
class Reminder {
  final String id;
  final String title;
  final String description;
  final String categoryId;          // registry key (string, not sealed enum)
  final ReminderSchedule schedule;  // one-time or recurring
  final ReminderSource source;      // system | user | derived
  final String? sourceItemId;       // links to GIC/mortgage if derived
  final NotificationConfig notify;
  final bool isPremium;
  final bool isDismissed;
  final Map<String, dynamic> metadata;
}
enum ReminderSource { system, user, derived }

sealed class ReminderSchedule { DateTime? nextOccurrenceAfter(DateTime from); }
class OneTimeSchedule  extends ReminderSchedule { final DateTime date; }
class RecurringSchedule extends ReminderSchedule {
  final Recurrence rule;   // annual | monthly | custom
  final DateTime anchor;
  final DateTime? until;
}

class ReminderCategory {           // the registry — single source of truth
  final String id;                 // 'rrsp','tfsa','bill','subscription'...
  final String label;
  final IconData icon; final Color color;
  final List<Duration> defaultLeadTimes;  // [30d, 7d, 1d]
  final bool premiumByDefault;
  final String? learnMoreUrl;
  // (content-as-data) audience/province predicates for onboarding filters
}

class NotificationConfig {
  final bool enabled;
  final List<Duration> leadTimes;  // category defaults, user-overridable
  final TimeOfDay timeOfDay;       // default ~9:00 local
}
```

**Why `categoryId` is a string + registry:** adding "property tax" or "Netflix renewal" must not require editing a sealed enum and every switch. Categories (and their provincial/annual rule data) are **data, not code** — see [content-as-data](../../product/02-alert-catalog.md#content-as-data-principle-important).

**Flow:** `canadian_dates` rules → `system` recurring reminders. User adds → `user`. GIC/mortgage → `derived` reminder linked by `sourceItemId`. All land in one `reminders` table and one notification pipeline.

## Section 3 — Data layer, schema & migration

```dart
abstract class ReminderRepository {
  Future<List<Reminder>> getAll();
  Stream<List<Reminder>> watchAll();        // reactive home
  Future<void> upsert(Reminder r);
  Future<void> delete(String id);
  Future<void> setDismissed(String id, bool dismissed);
}
```
`LocalReminderRepository` (SQLite) now; `SyncedReminderRepository` (wraps local + Firestore) later. DI in `core/di` selects the impl — presentation untouched.

**Schema v2**
```sql
CREATE TABLE reminders (
  id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT,
  category_id TEXT NOT NULL, source TEXT NOT NULL, source_item_id TEXT,
  schedule_json TEXT NOT NULL, notify_json TEXT NOT NULL,
  is_premium INTEGER NOT NULL DEFAULT 0, is_dismissed INTEGER NOT NULL DEFAULT 0,
  metadata_json TEXT
);
CREATE INDEX idx_reminders_category ON reminders(category_id);
-- gics / mortgages tables kept as-is (they are sources)
```
`schedule_json`/`notify_json` keep rows flexible while Dart keeps strong types via the DTO.

**Migration v1 → v2** (ordered, in `core/database/migrations.dart`): create `reminders` (+index) → backfill from old `alerts` (type→category_id; built-in ids→`system`, else `user`; `deadline`→`OneTimeSchedule`; `reminderEnabled`→`notify.enabled`) → drop `alerts`. `gics`/`mortgages` untouched. **No user data loss.**

**Error handling:** repository failures → `RepositoryException` → provider sets `AsyncValue.error` → friendly retry UI. DB-init failure → in-memory fallback so the app still opens.

## Section 4 — Notifications, UX & testing

**Notification pipeline (single, fed by repository):**
`Reminder + NotificationConfig` → `NotificationScheduler` computes fire times = `nextOccurrence − leadTime` at `timeOfDay` (local tz) → `flutter_local_notifications` schedules → tap → `go_router` deep-link to detail. Reschedule on add/edit/delete **and** on app launch (recurring rolls forward). Phase 2: notification actions (Mark done / Snooze / Learn more).

**UX flows unlocked:** glanceable home via `watchAll()` stream with live countdowns; add-reminder-in-seconds via registry category picker with smart default lead-times; premium gating via `isPremium` + category `premiumByDefault` checked against `subscriptionProvider` (paywall nudge, not dead end).

**Testing split (highest leverage first):**
- **Domain (pure, fast):** `ReminderSchedule.nextOccurrenceAfter` (annual/monthly, Feb 29, year rollover), registry integrity, Canadian-date rules — plain `dart test`.
- **Data:** `LocalReminderRepository` on in-memory SQLite; migration test preserves user data.
- **Presentation:** Riverpod providers with a **fake** `ReminderRepository`.
- **Notifications:** scheduler fire-time math with a mock plugin.

---

## Consequences
- **Positive:** categories grow by one registry entry + data; sync is a DI swap; date logic is purely testable; B2B/white-label friendly (clean engine boundary).
- **Costs:** upfront file reorganization; need a clean recurrence model; JSON columns trade some queryability for flexibility (mitigated by the category index).

## Build sequence (implementation plan input)
1. Scaffold `core/` + `features/` skeleton; move `app.dart`.
2. Domain: `Reminder`, `ReminderSchedule`, `ReminderCategory` registry (seed from current `AlertType`), `NotificationConfig`, repository interface.
3. Data: local datasource + DTO + `LocalReminderRepository`; `app_database` + v1→v2 migration.
4. Presentation: `RemindersNotifier` on the interface; port home/alerts/add-edit screens.
5. Sources: port `canadian_dates` rules to emit reminders; `tracked_items` (GIC/mortgage) derive reminders.
6. Notifications: single `NotificationScheduler` with multi-lead-time.
7. Tests across the split above.

→ Next: **writing-plans** skill to turn the build sequence into a detailed implementation plan.
