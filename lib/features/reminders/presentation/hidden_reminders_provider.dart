import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:maple_alerts/services/notification_service.dart';

/// Persisted map of reminder id → DateTime until which the reminder is hidden.
///
/// - [markDone]  sets the hidden-until time to year 9999 (effectively forever)
///   and cancels the scheduled notification.
/// - [snooze]    sets the hidden-until time to `now + by` (default 7 days).
/// - [isHidden]  returns `true` when the current time is before the stored
///   hidden-until time.
///
/// State is persisted to [SharedPreferences] under [_kPrefsKey] as a JSON
/// object mapping id strings to ISO-8601 date-time strings.
class HiddenRemindersNotifier
    extends StateNotifier<Map<String, DateTime>> {
  HiddenRemindersNotifier() : super(const {}) {
    _load();
  }

  static const String _kPrefsKey = 'hidden_reminders_v1';

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Mark a reminder as done (hidden indefinitely) and cancel its notification.
  Future<void> markDone(String id) async {
    await _set(id, DateTime.utc(9999));
    try {
      await NotificationService.instance.cancelAlert(id);
    } catch (_) {
      // Notification plugin absent in test / web environments — ignore.
    }
  }

  /// Snooze a reminder for [by] (default 7 days).
  Future<void> snooze(String id, {Duration by = const Duration(days: 7)}) async {
    await _set(id, DateTime.now().add(by));
  }

  /// Returns `true` when [id] should be hidden at the given [now].
  bool isHidden(String id, DateTime now) {
    final until = state[id];
    return until != null && until.isAfter(now);
  }

  // ── Internals ───────────────────────────────────────────────────────────────

  /// Update state and persist to prefs.
  Future<void> _set(String id, DateTime dt) async {
    state = {...state, id: dt};
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(
        state.map((k, v) => MapEntry(k, v.toIso8601String())),
      );
      await prefs.setString(_kPrefsKey, encoded);
    } catch (_) {
      // Degrade gracefully when prefs are unavailable (test / web).
    }
  }

  /// Load persisted state from prefs.
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrefsKey);
      if (raw == null) return;
      final decoded = json.decode(raw) as Map<String, dynamic>;
      state = decoded.map(
        (k, v) => MapEntry(k, DateTime.parse(v as String)),
      );
    } catch (_) {
      // Ignore parse / prefs errors — start from empty state.
    }
  }
}

final hiddenRemindersProvider =
    StateNotifierProvider<HiddenRemindersNotifier, Map<String, DateTime>>(
  (ref) => HiddenRemindersNotifier(),
);
