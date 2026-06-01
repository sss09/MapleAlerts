# Reminders Domain Core — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the pure-Dart domain core of the new reminders architecture — schedule/recurrence logic, value objects, the category registry, the `Reminder` entity, and the repository interface — fully unit-tested, with no database or UI dependencies.

**Architecture:** Feature-first. Everything lives under `lib/features/reminders/domain/`. A unified `Reminder` entity carries a `ReminderSchedule` (sealed: one-time or recurring), a `categoryId` resolved against a central `ReminderCategory` registry, and a `NotificationConfig`. Presentation and data layers (later plans) depend only on these types and the `ReminderRepository` interface. This plan delivers a tested library unit; it does not yet wire into the running app.

**Tech Stack:** Dart/Flutter, `flutter_test`. Tests run on the Dart VM via `flutter test` (no device/emulator needed). The Flutter SDK is on PATH at `C:\src\flutter`.

**Follow-on plans (not in scope here):** Plan 2 — data layer (`ReminderDto`, `AppDatabase`, v1→v2 migration, `LocalReminderRepository`). Plan 3 — presentation + Riverpod DI swap. Plan 4 — `canadian_dates` rules + `tracked_items` derivation + `NotificationScheduler`.

**Conventions:**
- Test command (run from repo root): `flutter test <path> -r compact`
- Commit after every task. Use `feat:`/`test:` prefixes.
- The existing `lib/models/alert.dart` (with `AlertType`) stays untouched during this plan; we *seed* the category registry from its concepts but do not modify it yet.

---

### Task 1: `ReminderSource` enum

**Files:**
- Create: `lib/features/reminders/domain/reminder_source.dart`
- Test: `test/features/reminders/domain/reminder_source_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/reminders/domain/reminder_source_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/features/reminders/domain/reminder_source.dart';

void main() {
  group('ReminderSource', () {
    test('value returns the enum name', () {
      expect(ReminderSource.system.value, 'system');
      expect(ReminderSource.user.value, 'user');
      expect(ReminderSource.derived.value, 'derived');
    });

    test('fromValue parses known values', () {
      expect(ReminderSourceX.fromValue('system'), ReminderSource.system);
      expect(ReminderSourceX.fromValue('derived'), ReminderSource.derived);
    });

    test('fromValue falls back to user for unknown values', () {
      expect(ReminderSourceX.fromValue('garbage'), ReminderSource.user);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/reminders/domain/reminder_source_test.dart -r compact`
Expected: FAIL — `Target of URI doesn't exist` (file not created yet).

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/reminders/domain/reminder_source.dart

/// Where a reminder originated.
enum ReminderSource { system, user, derived }

extension ReminderSourceX on ReminderSource {
  /// Stable string used for persistence.
  String get value => name;

  /// Parses a persisted value; unknown values default to [ReminderSource.user].
  static ReminderSource fromValue(String v) =>
      ReminderSource.values.firstWhere((e) => e.name == v,
          orElse: () => ReminderSource.user);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/reminders/domain/reminder_source_test.dart -r compact`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/reminders/domain/reminder_source.dart test/features/reminders/domain/reminder_source_test.dart
git commit -m "feat: add ReminderSource enum with stable serialization"
```

---

### Task 2: `Recurrence` value object

**Files:**
- Create: `lib/features/reminders/domain/recurrence.dart`
- Test: `test/features/reminders/domain/recurrence_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/reminders/domain/recurrence_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/features/reminders/domain/recurrence.dart';

void main() {
  group('Recurrence', () {
    test('defaults interval to 1', () {
      const r = Recurrence(frequency: RecurrenceFrequency.annual);
      expect(r.interval, 1);
    });

    test('round-trips through json', () {
      const r = Recurrence(frequency: RecurrenceFrequency.monthly, interval: 2);
      final json = r.toJson();
      expect(json, {'frequency': 'monthly', 'interval': 2});
      final back = Recurrence.fromJson(json);
      expect(back.frequency, RecurrenceFrequency.monthly);
      expect(back.interval, 2);
    });

    test('fromJson defaults missing interval to 1', () {
      final back = Recurrence.fromJson({'frequency': 'annual'});
      expect(back.interval, 1);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/reminders/domain/recurrence_test.dart -r compact`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/reminders/domain/recurrence.dart

enum RecurrenceFrequency { annual, monthly }

/// How often a [RecurringSchedule] repeats.
class Recurrence {
  final RecurrenceFrequency frequency;
  final int interval; // every N units (years for annual, months for monthly)

  const Recurrence({required this.frequency, this.interval = 1});

  Map<String, dynamic> toJson() => {
        'frequency': frequency.name,
        'interval': interval,
      };

  factory Recurrence.fromJson(Map<String, dynamic> json) => Recurrence(
        frequency: RecurrenceFrequency.values
            .firstWhere((e) => e.name == json['frequency']),
        interval: (json['interval'] as int?) ?? 1,
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/reminders/domain/recurrence_test.dart -r compact`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/reminders/domain/recurrence.dart test/features/reminders/domain/recurrence_test.dart
git commit -m "feat: add Recurrence value object"
```

---

### Task 3: `ReminderSchedule` (sealed) — the core scheduling logic

This is the most bug-prone unit. Tests cover one-time, annual rollover, monthly rollover, month-end clamping, and `until` bounds.

**Files:**
- Create: `lib/features/reminders/domain/reminder_schedule.dart`
- Test: `test/features/reminders/domain/reminder_schedule_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/reminders/domain/reminder_schedule_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/features/reminders/domain/recurrence.dart';
import 'package:maple_alerts/features/reminders/domain/reminder_schedule.dart';

void main() {
  group('OneTimeSchedule', () {
    test('returns the date when it is in the future', () {
      final s = OneTimeSchedule(DateTime(2026, 3, 1));
      expect(s.nextOccurrenceAfter(DateTime(2026, 1, 1)), DateTime(2026, 3, 1));
    });

    test('returns null when the date is in the past', () {
      final s = OneTimeSchedule(DateTime(2026, 3, 1));
      expect(s.nextOccurrenceAfter(DateTime(2026, 4, 1)), isNull);
    });

    test('round-trips through json', () {
      final s = OneTimeSchedule(DateTime(2026, 3, 1));
      final back = ReminderSchedule.fromJson(s.toJson());
      expect(back, isA<OneTimeSchedule>());
      expect((back as OneTimeSchedule).date, DateTime(2026, 3, 1));
    });
  });

  group('RecurringSchedule (annual)', () {
    final annual = RecurringSchedule(
      rule: const Recurrence(frequency: RecurrenceFrequency.annual),
      anchor: DateTime(2020, 3, 1), // RRSP-like: March 1 each year
    );

    test('returns this year occurrence when still upcoming', () {
      expect(annual.nextOccurrenceAfter(DateTime(2026, 1, 15)),
          DateTime(2026, 3, 1));
    });

    test('rolls to next year when this year has passed', () {
      expect(annual.nextOccurrenceAfter(DateTime(2026, 6, 1)),
          DateTime(2027, 3, 1));
    });

    test('respects until bound', () {
      final bounded = RecurringSchedule(
        rule: const Recurrence(frequency: RecurrenceFrequency.annual),
        anchor: DateTime(2020, 3, 1),
        until: DateTime(2026, 12, 31),
      );
      expect(bounded.nextOccurrenceAfter(DateTime(2027, 1, 1)), isNull);
    });
  });

  group('RecurringSchedule (monthly)', () {
    final monthly = RecurringSchedule(
      rule: const Recurrence(frequency: RecurrenceFrequency.monthly),
      anchor: DateTime(2024, 1, 20), // CCB-like: 20th each month
    );

    test('returns this month occurrence when still upcoming', () {
      expect(monthly.nextOccurrenceAfter(DateTime(2026, 5, 1)),
          DateTime(2026, 5, 20));
    });

    test('rolls to next month when this month has passed', () {
      expect(monthly.nextOccurrenceAfter(DateTime(2026, 5, 25)),
          DateTime(2026, 6, 20));
    });

    test('rolls across year boundary from December', () {
      expect(monthly.nextOccurrenceAfter(DateTime(2026, 12, 25)),
          DateTime(2027, 1, 20));
    });

    test('clamps day to last day of short months', () {
      final endOfMonth = RecurringSchedule(
        rule: const Recurrence(frequency: RecurrenceFrequency.monthly),
        anchor: DateTime(2024, 1, 31),
      );
      // From mid-Feb 2026, next "31st" clamps to Feb 28, 2026.
      expect(endOfMonth.nextOccurrenceAfter(DateTime(2026, 2, 1)),
          DateTime(2026, 2, 28));
    });

    test('round-trips through json', () {
      final back = ReminderSchedule.fromJson(monthly.toJson());
      expect(back, isA<RecurringSchedule>());
      final r = back as RecurringSchedule;
      expect(r.rule.frequency, RecurrenceFrequency.monthly);
      expect(r.anchor, DateTime(2024, 1, 20));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/reminders/domain/reminder_schedule_test.dart -r compact`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/reminders/domain/reminder_schedule.dart
import 'recurrence.dart';

/// When a reminder fires. Either a single date or a repeating rule.
sealed class ReminderSchedule {
  const ReminderSchedule();

  /// The first occurrence strictly after [from], or null if none remains.
  DateTime? nextOccurrenceAfter(DateTime from);

  Map<String, dynamic> toJson();

  factory ReminderSchedule.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'oneTime':
        return OneTimeSchedule.fromJson(json);
      case 'recurring':
        return RecurringSchedule.fromJson(json);
      default:
        throw ArgumentError('Unknown schedule type: ${json['type']}');
    }
  }
}

class OneTimeSchedule extends ReminderSchedule {
  final DateTime date;
  const OneTimeSchedule(this.date);

  @override
  DateTime? nextOccurrenceAfter(DateTime from) =>
      date.isAfter(from) ? date : null;

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'oneTime', 'date': date.toIso8601String()};

  factory OneTimeSchedule.fromJson(Map<String, dynamic> json) =>
      OneTimeSchedule(DateTime.parse(json['date'] as String));
}

class RecurringSchedule extends ReminderSchedule {
  final Recurrence rule;
  final DateTime anchor;
  final DateTime? until;

  const RecurringSchedule({
    required this.rule,
    required this.anchor,
    this.until,
  });

  @override
  DateTime? nextOccurrenceAfter(DateTime from) {
    DateTime candidate;
    switch (rule.frequency) {
      case RecurrenceFrequency.annual:
        candidate = _clamp(from.year, anchor.month, anchor.day);
        if (!candidate.isAfter(from)) {
          candidate = _clamp(from.year + rule.interval, anchor.month, anchor.day);
        }
        break;
      case RecurrenceFrequency.monthly:
        candidate = _clamp(from.year, from.month, anchor.day);
        if (!candidate.isAfter(from)) {
          final m = from.month + rule.interval; // 1-based month, may exceed 12
          final year = from.year + ((m - 1) ~/ 12);
          final month = ((m - 1) % 12) + 1;
          candidate = _clamp(year, month, anchor.day);
        }
        break;
    }
    if (until != null && candidate.isAfter(until!)) return null;
    return candidate;
  }

  /// Builds a date, clamping [day] to the last valid day of the month.
  static DateTime _clamp(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day; // day 0 = last of prev month
    return DateTime(year, month, day > lastDay ? lastDay : day);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'recurring',
        'rule': rule.toJson(),
        'anchor': anchor.toIso8601String(),
        'until': until?.toIso8601String(),
      };

  factory RecurringSchedule.fromJson(Map<String, dynamic> json) =>
      RecurringSchedule(
        rule: Recurrence.fromJson(json['rule'] as Map<String, dynamic>),
        anchor: DateTime.parse(json['anchor'] as String),
        until: json['until'] == null
            ? null
            : DateTime.parse(json['until'] as String),
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/reminders/domain/reminder_schedule_test.dart -r compact`
Expected: PASS (all groups).

- [ ] **Step 5: Commit**

```bash
git add lib/features/reminders/domain/reminder_schedule.dart test/features/reminders/domain/reminder_schedule_test.dart
git commit -m "feat: add ReminderSchedule with one-time and recurring logic"
```

---

### Task 4: `NotificationConfig` value object

**Files:**
- Create: `lib/features/reminders/domain/notification_config.dart`
- Test: `test/features/reminders/domain/notification_config_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/reminders/domain/notification_config_test.dart
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/features/reminders/domain/notification_config.dart';

void main() {
  group('NotificationConfig', () {
    test('has sensible defaults', () {
      const c = NotificationConfig();
      expect(c.enabled, isTrue);
      expect(c.leadTimes, const [Duration(days: 7), Duration(days: 1)]);
      expect(c.timeOfDay, const TimeOfDay(hour: 9, minute: 0));
    });

    test('round-trips through json', () {
      const c = NotificationConfig(
        enabled: false,
        leadTimes: [Duration(days: 30), Duration(days: 1)],
        timeOfDay: TimeOfDay(hour: 8, minute: 30),
      );
      final back = NotificationConfig.fromJson(c.toJson());
      expect(back.enabled, isFalse);
      expect(back.leadTimes, const [Duration(days: 30), Duration(days: 1)]);
      expect(back.timeOfDay, const TimeOfDay(hour: 8, minute: 30));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/reminders/domain/notification_config_test.dart -r compact`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/reminders/domain/notification_config.dart
import 'package:flutter/material.dart' show TimeOfDay;

/// Per-reminder notification settings. Lead-times default from the category
/// but are user-overridable.
class NotificationConfig {
  final bool enabled;
  final List<Duration> leadTimes;
  final TimeOfDay timeOfDay;

  const NotificationConfig({
    this.enabled = true,
    this.leadTimes = const [Duration(days: 7), Duration(days: 1)],
    this.timeOfDay = const TimeOfDay(hour: 9, minute: 0),
  });

  NotificationConfig copyWith({
    bool? enabled,
    List<Duration>? leadTimes,
    TimeOfDay? timeOfDay,
  }) =>
      NotificationConfig(
        enabled: enabled ?? this.enabled,
        leadTimes: leadTimes ?? this.leadTimes,
        timeOfDay: timeOfDay ?? this.timeOfDay,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'leadTimeMinutes': leadTimes.map((d) => d.inMinutes).toList(),
        'hour': timeOfDay.hour,
        'minute': timeOfDay.minute,
      };

  factory NotificationConfig.fromJson(Map<String, dynamic> json) =>
      NotificationConfig(
        enabled: json['enabled'] as bool? ?? true,
        leadTimes: ((json['leadTimeMinutes'] as List?) ?? const [])
            .map((m) => Duration(minutes: m as int))
            .toList(),
        timeOfDay: TimeOfDay(
          hour: json['hour'] as int? ?? 9,
          minute: json['minute'] as int? ?? 0,
        ),
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/reminders/domain/notification_config_test.dart -r compact`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/reminders/domain/notification_config.dart test/features/reminders/domain/notification_config_test.dart
git commit -m "feat: add NotificationConfig with multi-lead-time support"
```

---

### Task 5: `ReminderCategory` + registry

Seeds the registry from the existing `AlertType` concepts (rrsp, tfsa, gic, mortgage, boc, ccb, osap, custom) **plus `tax`** (the new MVP alert). Free/premium flags follow the locked product decision: free = rrsp, tfsa, tax, boc, ccb, custom; premium = gic, mortgage, osap.

**Files:**
- Create: `lib/features/reminders/domain/reminder_category.dart`
- Test: `test/features/reminders/domain/reminder_category_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/reminders/domain/reminder_category_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/features/reminders/domain/reminder_category.dart';

void main() {
  group('ReminderCategory registry', () {
    test('contains the 8 MVP categories plus custom', () {
      for (final id in ['rrsp', 'tfsa', 'tax', 'boc', 'ccb', 'gic', 'mortgage', 'osap', 'custom']) {
        expect(kReminderCategories.containsKey(id), isTrue, reason: 'missing $id');
      }
    });

    test('free categories are not premium by default', () {
      for (final id in ['rrsp', 'tfsa', 'tax', 'boc', 'ccb', 'custom']) {
        expect(kReminderCategories[id]!.premiumByDefault, isFalse, reason: '$id should be free');
      }
    });

    test('tracker categories are premium by default', () {
      for (final id in ['gic', 'mortgage', 'osap']) {
        expect(kReminderCategories[id]!.premiumByDefault, isTrue, reason: '$id should be premium');
      }
    });

    test('categoryFor returns the category for a known id', () {
      expect(categoryFor('rrsp').id, 'rrsp');
    });

    test('categoryFor falls back to custom for unknown id', () {
      expect(categoryFor('does-not-exist').id, 'custom');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/reminders/domain/reminder_category_test.dart -r compact`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/reminders/domain/reminder_category.dart
import 'package:flutter/material.dart';

/// Metadata describing a reminder category. The registry ([kReminderCategories])
/// is the single source of truth — adding a category is one entry here.
class ReminderCategory {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final List<Duration> defaultLeadTimes;
  final bool premiumByDefault;
  final String? learnMoreUrl;

  const ReminderCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    this.defaultLeadTimes = const [Duration(days: 7), Duration(days: 1)],
    this.premiumByDefault = false,
    this.learnMoreUrl,
  });
}

const Map<String, ReminderCategory> kReminderCategories = {
  'rrsp': ReminderCategory(
    id: 'rrsp',
    label: 'RRSP',
    icon: Icons.savings,
    color: Color(0xFFD32F2F),
    defaultLeadTimes: [Duration(days: 60), Duration(days: 30), Duration(days: 7), Duration(days: 1)],
  ),
  'tfsa': ReminderCategory(
    id: 'tfsa',
    label: 'TFSA',
    icon: Icons.account_balance_wallet,
    color: Color(0xFF388E3C),
  ),
  'tax': ReminderCategory(
    id: 'tax',
    label: 'Tax Filing',
    icon: Icons.receipt_long,
    color: Color(0xFF1976D2),
    defaultLeadTimes: [Duration(days: 60), Duration(days: 30), Duration(days: 7), Duration(days: 1)],
  ),
  'boc': ReminderCategory(
    id: 'boc',
    label: 'Bank of Canada',
    icon: Icons.account_balance,
    color: Color(0xFF512DA8),
    defaultLeadTimes: [Duration(days: 1)],
  ),
  'ccb': ReminderCategory(
    id: 'ccb',
    label: 'Canada Child Benefit',
    icon: Icons.child_care,
    color: Color(0xFFF57C00),
    defaultLeadTimes: [Duration(days: 1)],
  ),
  'gic': ReminderCategory(
    id: 'gic',
    label: 'GIC Maturity',
    icon: Icons.lock_clock,
    color: Color(0xFF00796B),
    defaultLeadTimes: [Duration(days: 60), Duration(days: 30), Duration(days: 7)],
    premiumByDefault: true,
  ),
  'mortgage': ReminderCategory(
    id: 'mortgage',
    label: 'Mortgage Renewal',
    icon: Icons.home,
    color: Color(0xFF5D4037),
    defaultLeadTimes: [Duration(days: 120), Duration(days: 90), Duration(days: 30)],
    premiumByDefault: true,
  ),
  'osap': ReminderCategory(
    id: 'osap',
    label: 'OSAP',
    icon: Icons.school,
    color: Color(0xFFC2185B),
    defaultLeadTimes: [Duration(days: 30), Duration(days: 7)],
    premiumByDefault: true,
  ),
  'custom': ReminderCategory(
    id: 'custom',
    label: 'Custom',
    icon: Icons.notifications,
    color: Color(0xFF455A64),
  ),
};

/// Resolves a category by id, falling back to `custom` for unknown ids.
ReminderCategory categoryFor(String id) =>
    kReminderCategories[id] ?? kReminderCategories['custom']!;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/reminders/domain/reminder_category_test.dart -r compact`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/reminders/domain/reminder_category.dart test/features/reminders/domain/reminder_category_test.dart
git commit -m "feat: add ReminderCategory registry seeded with 8 MVP categories"
```

---

### Task 6: `Reminder` entity

**Files:**
- Create: `lib/features/reminders/domain/reminder.dart`
- Test: `test/features/reminders/domain/reminder_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/reminders/domain/reminder_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/features/reminders/domain/notification_config.dart';
import 'package:maple_alerts/features/reminders/domain/reminder.dart';
import 'package:maple_alerts/features/reminders/domain/reminder_schedule.dart';
import 'package:maple_alerts/features/reminders/domain/reminder_source.dart';

Reminder _sample() => Reminder(
      id: 'r1',
      title: 'RRSP deadline',
      description: 'Contribute before March 1',
      categoryId: 'rrsp',
      schedule: OneTimeSchedule(DateTime(2026, 3, 1)),
      source: ReminderSource.system,
    );

void main() {
  group('Reminder', () {
    test('applies defaults for optional fields', () {
      final r = _sample();
      expect(r.sourceItemId, isNull);
      expect(r.isPremium, isFalse);
      expect(r.isDismissed, isFalse);
      expect(r.metadata, isEmpty);
      expect(r.notify.enabled, isTrue);
    });

    test('copyWith overrides only the given fields', () {
      final r = _sample();
      final updated = r.copyWith(isDismissed: true, title: 'Changed');
      expect(updated.isDismissed, isTrue);
      expect(updated.title, 'Changed');
      // unchanged fields preserved
      expect(updated.id, 'r1');
      expect(updated.categoryId, 'rrsp');
      expect(updated.source, ReminderSource.system);
    });

    test('nextOccurrence delegates to the schedule', () {
      final r = _sample();
      expect(r.nextOccurrenceAfter(DateTime(2026, 1, 1)), DateTime(2026, 3, 1));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/reminders/domain/reminder_test.dart -r compact`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/reminders/domain/reminder.dart
import 'notification_config.dart';
import 'reminder_schedule.dart';
import 'reminder_source.dart';

/// The unified reminder entity. Every alert — built-in Canadian dates, user
/// customs, and reminders derived from tracked items — is a [Reminder].
class Reminder {
  final String id;
  final String title;
  final String description;
  final String categoryId; // resolves against kReminderCategories
  final ReminderSchedule schedule;
  final ReminderSource source;
  final String? sourceItemId; // links to a tracked item if source == derived
  final NotificationConfig notify;
  final bool isPremium;
  final bool isDismissed;
  final Map<String, dynamic> metadata;

  const Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.schedule,
    required this.source,
    this.sourceItemId,
    this.notify = const NotificationConfig(),
    this.isPremium = false,
    this.isDismissed = false,
    this.metadata = const {},
  });

  /// The next time this reminder is due after [from] (delegates to schedule).
  DateTime? nextOccurrenceAfter(DateTime from) =>
      schedule.nextOccurrenceAfter(from);

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    ReminderSchedule? schedule,
    ReminderSource? source,
    String? sourceItemId,
    NotificationConfig? notify,
    bool? isPremium,
    bool? isDismissed,
    Map<String, dynamic>? metadata,
  }) =>
      Reminder(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        categoryId: categoryId ?? this.categoryId,
        schedule: schedule ?? this.schedule,
        source: source ?? this.source,
        sourceItemId: sourceItemId ?? this.sourceItemId,
        notify: notify ?? this.notify,
        isPremium: isPremium ?? this.isPremium,
        isDismissed: isDismissed ?? this.isDismissed,
        metadata: metadata ?? this.metadata,
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/reminders/domain/reminder_test.dart -r compact`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/reminders/domain/reminder.dart test/features/reminders/domain/reminder_test.dart
git commit -m "feat: add unified Reminder entity"
```

---

### Task 7: `ReminderRepository` interface + in-memory fake

The interface is what presentation depends on. The in-memory fake lives under `test/` so later plans (presentation) can test providers without a database.

**Files:**
- Create: `lib/features/reminders/domain/reminder_repository.dart`
- Create: `test/support/fake_reminder_repository.dart`
- Test: `test/support/fake_reminder_repository_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/support/fake_reminder_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/features/reminders/domain/reminder.dart';
import 'package:maple_alerts/features/reminders/domain/reminder_schedule.dart';
import 'package:maple_alerts/features/reminders/domain/reminder_source.dart';
import 'fake_reminder_repository.dart';

Reminder _r(String id) => Reminder(
      id: id,
      title: 'T-$id',
      description: '',
      categoryId: 'custom',
      schedule: OneTimeSchedule(DateTime(2026, 3, 1)),
      source: ReminderSource.user,
    );

void main() {
  group('FakeReminderRepository', () {
    test('upsert then getAll returns the reminder', () async {
      final repo = FakeReminderRepository();
      await repo.upsert(_r('a'));
      final all = await repo.getAll();
      expect(all.map((r) => r.id), ['a']);
    });

    test('upsert with existing id replaces', () async {
      final repo = FakeReminderRepository();
      await repo.upsert(_r('a'));
      await repo.upsert(_r('a').copyWith(title: 'updated'));
      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.single.title, 'updated');
    });

    test('delete removes the reminder', () async {
      final repo = FakeReminderRepository();
      await repo.upsert(_r('a'));
      await repo.delete('a');
      expect(await repo.getAll(), isEmpty);
    });

    test('setDismissed flips the flag', () async {
      final repo = FakeReminderRepository();
      await repo.upsert(_r('a'));
      await repo.setDismissed('a', true);
      expect((await repo.getAll()).single.isDismissed, isTrue);
    });

    test('watchAll emits on change', () async {
      final repo = FakeReminderRepository();
      final future = repo.watchAll().firstWhere((list) => list.isNotEmpty);
      await repo.upsert(_r('a'));
      final emitted = await future;
      expect(emitted.single.id, 'a');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/support/fake_reminder_repository_test.dart -r compact`
Expected: FAIL — URIs don't exist.

- [ ] **Step 3: Write the interface**

```dart
// lib/features/reminders/domain/reminder_repository.dart
import 'reminder.dart';

/// Persistence boundary for reminders. Presentation depends on this interface
/// only — never on a concrete data source — so the storage backend (local
/// SQLite now, synced later) can change without touching the UI.
abstract class ReminderRepository {
  Future<List<Reminder>> getAll();
  Stream<List<Reminder>> watchAll();
  Future<void> upsert(Reminder reminder);
  Future<void> delete(String id);
  Future<void> setDismissed(String id, bool dismissed);
}
```

- [ ] **Step 4: Write the in-memory fake**

```dart
// test/support/fake_reminder_repository.dart
import 'dart:async';
import 'package:maple_alerts/features/reminders/domain/reminder.dart';
import 'package:maple_alerts/features/reminders/domain/reminder_repository.dart';

/// In-memory [ReminderRepository] for tests. Not used in production.
class FakeReminderRepository implements ReminderRepository {
  final Map<String, Reminder> _store = {};
  final StreamController<List<Reminder>> _controller =
      StreamController<List<Reminder>>.broadcast();

  List<Reminder> get _snapshot => _store.values.toList();

  void _emit() => _controller.add(_snapshot);

  @override
  Future<List<Reminder>> getAll() async => _snapshot;

  @override
  Stream<List<Reminder>> watchAll() => _controller.stream;

  @override
  Future<void> upsert(Reminder reminder) async {
    _store[reminder.id] = reminder;
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
    _emit();
  }

  @override
  Future<void> setDismissed(String id, bool dismissed) async {
    final existing = _store[id];
    if (existing != null) {
      _store[id] = existing.copyWith(isDismissed: dismissed);
      _emit();
    }
  }

  void dispose() => _controller.close();
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/support/fake_reminder_repository_test.dart -r compact`
Expected: PASS (5 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/features/reminders/domain/reminder_repository.dart test/support/fake_reminder_repository.dart test/support/fake_reminder_repository_test.dart
git commit -m "feat: add ReminderRepository interface with in-memory fake for tests"
```

---

### Task 8: Full domain suite green + barrel export

**Files:**
- Create: `lib/features/reminders/domain/domain.dart` (barrel)

- [ ] **Step 1: Create the barrel export**

```dart
// lib/features/reminders/domain/domain.dart
export 'notification_config.dart';
export 'recurrence.dart';
export 'reminder.dart';
export 'reminder_category.dart';
export 'reminder_repository.dart';
export 'reminder_schedule.dart';
export 'reminder_source.dart';
```

- [ ] **Step 2: Run the full domain test suite**

Run: `flutter test test/features/reminders -r compact`
Expected: PASS — all tests from Tasks 1–6 green.

- [ ] **Step 3: Run the analyzer**

Run: `flutter analyze lib/features/reminders test/features/reminders test/support`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/reminders/domain/domain.dart
git commit -m "feat: add reminders domain barrel export"
```

---

## Self-Review

**Spec coverage (against architecture spec Section 2):**
- `Reminder` entity with all fields → Task 6 ✓
- `ReminderSource` (system/user/derived) → Task 1 ✓
- `ReminderSchedule` sealed (OneTime/Recurring) + `nextOccurrenceAfter` → Task 3 ✓
- `Recurrence` (annual/monthly) → Task 2 ✓
- `ReminderCategory` registry, seeded from `AlertType` + `tax`, free/premium flags → Task 5 ✓
- `NotificationConfig` (enabled/leadTimes/timeOfDay) → Task 4 ✓
- `ReminderRepository` interface → Task 7 ✓
- Schedule edge cases (annual rollover, monthly rollover, year boundary, month-end clamp, `until`) → Task 3 tests ✓
- **Deferred to later plans (correctly out of scope):** DTO/JSON row mapping, `AppDatabase`, v1→v2 migration, `LocalReminderRepository`, providers, screens, notification scheduler, canadian_dates rules. Listed in the header.

**Placeholder scan:** No TBD/TODO; every code step contains complete, runnable code. ✓

**Type consistency:** `ReminderSchedule.nextOccurrenceAfter(DateTime)` used identically in Tasks 3 & 6; `Reminder.copyWith` field names match the constructor; `categoryFor`/`kReminderCategories` names consistent between Task 5 definition and its tests; `NotificationConfig` default `[7d, 1d]` consistent between Tasks 4 and the `Reminder` default. ✓

**Product-decision alignment:** `tax` category added; free vs premium split (free: rrsp/tfsa/tax/boc/ccb/custom; premium: gic/mortgage/osap) matches the locked MVP decision. ✓
