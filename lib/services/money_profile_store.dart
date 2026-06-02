import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../engine/canadian_data_engine/canadian_data_engine.dart';
import '../utils/constants.dart';

/// Persists the user's [MoneyProfile] as a single JSON blob in
/// SharedPreferences. One key for all financial inputs — adding a new input is
/// a new field on [MoneyProfile], not new plumbing here.
///
/// On first load it performs a read-through migration of the legacy
/// per-scalar keys (only ever written by the now-dead V1 screens) so existing
/// installs keep their birth year.
class MoneyProfileStore {
  const MoneyProfileStore();

  Future<MoneyProfile> load() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(kMoneyProfileKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return MoneyProfile.fromJson(decoded);
        }
      } catch (_) {
        // Corrupt blob — fall through to a fresh/migrated profile.
      }
    }

    // No (valid) blob yet: migrate legacy keys, then persist so it's stable.
    final legacyBirthYear = prefs.getInt(kTfsaBirthYearKey);
    final migrated = MoneyProfile(birthYear: legacyBirthYear);
    if (legacyBirthYear != null) {
      await prefs.setString(kMoneyProfileKey, jsonEncode(migrated.toJson()));
    }
    return migrated;
  }

  Future<void> save(MoneyProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kMoneyProfileKey, jsonEncode(profile.toJson()));
  }
}
