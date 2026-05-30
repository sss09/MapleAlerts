import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SettingsState {
  final bool notificationsEnabled;
  final int? tfsaBirthYear;
  final double rrspContribution;
  final bool onboardingDone;

  const SettingsState({
    this.notificationsEnabled = true,
    this.tfsaBirthYear,
    this.rrspContribution = 0.0,
    this.onboardingDone = false,
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    int? tfsaBirthYear,
    double? rrspContribution,
    bool? onboardingDone,
    bool clearTfsaBirthYear = false,
  }) {
    return SettingsState(
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      tfsaBirthYear:
          clearTfsaBirthYear ? null : (tfsaBirthYear ?? this.tfsaBirthYear),
      rrspContribution: rrspContribution ?? this.rrspContribution,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled =
        prefs.getBool(kNotificationsEnabledKey) ?? true;
    final tfsaBirthYear = prefs.getInt(kTfsaBirthYearKey);
    final rrspContribution =
        prefs.getDouble(kRrspContributionKey) ?? 0.0;
    final onboardingDone = prefs.getBool(kOnboardingDoneKey) ?? false;

    state = SettingsState(
      notificationsEnabled: notificationsEnabled,
      tfsaBirthYear: tfsaBirthYear,
      rrspContribution: rrspContribution,
      onboardingDone: onboardingDone,
    );
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kNotificationsEnabledKey, value);
    state = state.copyWith(notificationsEnabled: value);
  }

  Future<void> setTfsaBirthYear(int? year) async {
    final prefs = await SharedPreferences.getInstance();
    if (year == null) {
      await prefs.remove(kTfsaBirthYearKey);
      state = state.copyWith(clearTfsaBirthYear: true);
    } else {
      await prefs.setInt(kTfsaBirthYearKey, year);
      state = state.copyWith(tfsaBirthYear: year);
    }
  }

  Future<void> setRrspContribution(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(kRrspContributionKey, value);
    state = state.copyWith(rrspContribution: value);
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingDoneKey, true);
    state = state.copyWith(onboardingDone: true);
  }
}
