import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/analytics/analytics_service.dart';
import '../utils/constants.dart';

export '../utils/constants.dart' show kAnalyticsEnabledKey;

/// The "Share anonymous usage stats" Privacy toggle. Default ON; persisted.
/// Same prefs-backed StateNotifier pattern as enabledTopicsProvider.
final analyticsEnabledProvider =
    StateNotifierProvider<AnalyticsEnabledNotifier, bool>(
        (ref) => AnalyticsEnabledNotifier());

class AnalyticsEnabledNotifier extends StateNotifier<bool> {
  AnalyticsEnabledNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(kAnalyticsEnabledKey) ?? true;
    } catch (_) {
      // Prefs unavailable (tests/web edge) — keep the default.
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kAnalyticsEnabledKey, enabled);
    } catch (_) {
      // Non-fatal; default applies next launch.
    }
  }
}

/// The app-wide [AnalyticsService]. One instance per container (session
/// de-dupe lives in it); the kill switch is read fresh on every track call.
final analyticsProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(
    sink: (event, props) => Aptabase.instance.trackEvent(event, props),
    isEnabled: () => ref.read(analyticsEnabledProvider),
  );
});
