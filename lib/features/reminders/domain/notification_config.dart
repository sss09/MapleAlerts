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
        // Absent key → constructor default; present (even empty) → respected.
        leadTimes: (json['leadTimeMinutes'] as List?)
                ?.map((m) => Duration(minutes: m as int))
                .toList() ??
            const [Duration(days: 7), Duration(days: 1)],
        timeOfDay: TimeOfDay(
          hour: json['hour'] as int? ?? 9,
          minute: json['minute'] as int? ?? 0,
        ),
      );
}
