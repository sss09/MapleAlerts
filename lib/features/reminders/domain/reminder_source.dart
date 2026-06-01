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
