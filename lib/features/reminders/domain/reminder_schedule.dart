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
  }) : assert(
          rule.interval == 1,
          'RecurringSchedule currently supports only interval == 1. '
          'Multi-unit intervals are not yet anchor-aligned, so they would '
          'produce dates relative to the query instead of the anchor epoch.',
        );

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
  ///
  /// Note: a Feb-29 anchor clamps to Feb 28 in non-leap years (by design).
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
