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
      final saved = await db.getAlerts();
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

  Future<void> refresh() => _load();
}
