import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert.dart';
import '../services/database_service.dart';
import '../services/canadian_dates_service.dart';
import '../services/notification_service.dart';

final alertsProvider =
    StateNotifierProvider<AlertsNotifier, AsyncValue<List<Alert>>>((ref) {
  return AlertsNotifier();
});

class AlertsNotifier extends StateNotifier<AsyncValue<List<Alert>>> {
  AlertsNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = await AsyncValue.guard(() async {
      final db = DatabaseService.instance;
      // SQLite has no web implementation; degrade gracefully so the built-in
      // Canadian reminders still load (web demo, or first launch).
      List<Alert> saved;
      try {
        saved = await db.getAlerts();
      } catch (_) {
        saved = <Alert>[];
      }
      final builtIn =
          CanadianDatesService.getBuiltInAlerts(DateTime.now().year);
      final savedIds = saved.map((a) => a.id).toSet();
      final merged = [...saved];
      for (final alert in builtIn) {
        if (!savedIds.contains(alert.id)) merged.add(alert);
      }
      merged.sort((a, b) => a.deadline.compareTo(b.deadline));
      return merged;
    });
  }

  Future<void> addAlert(Alert alert) async {
    await DatabaseService.instance.insertAlert(alert);
    if (alert.reminderEnabled) {
      await NotificationService.instance.scheduleAlert(alert);
    }
    await _load();
  }

  Future<void> updateAlert(Alert alert) async {
    await DatabaseService.instance.updateAlert(alert);
    await NotificationService.instance.cancelAlert(alert.id);
    if (alert.reminderEnabled) {
      await NotificationService.instance.scheduleAlert(alert);
    }
    await _load();
  }

  Future<void> deleteAlert(String id) async {
    await DatabaseService.instance.deleteAlert(id);
    await NotificationService.instance.cancelAlert(id);
    await _load();
  }

  Future<void> toggleReminder(Alert alert) async {
    await updateAlert(alert.copyWith(reminderEnabled: !alert.reminderEnabled));
  }

  /// Inserts a custom [alert], schedules a notification if the deadline is
  /// still in the future, then reloads.
  ///
  /// Used by [showAddReminderSheet] to persist a free-text reminder.
  /// Notification scheduling is wrapped in try/catch so it never blocks the
  /// insert on web or test environments where the plugin is absent.
  Future<void> addCustom(Alert alert) async {
    try {
      await DatabaseService.instance.insertAlert(alert);
    } catch (_) {
      // Gracefully degrade on web / test environments where SQLite is absent.
    }
    try {
      await NotificationService.instance.scheduleAlert(alert);
    } catch (_) {
      // kIsWeb-guarded inside scheduleAlert; also no-op when plugin absent.
    }
    await _load();
  }

  Future<void> refresh() => _load();
}
