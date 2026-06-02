import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/services/money_profile_store.dart';
import 'package:maple_alerts/utils/constants.dart';

void main() {
  const store = MoneyProfileStore();

  test('loads an empty profile when nothing is stored', () async {
    SharedPreferences.setMockInitialValues({});
    final profile = await store.load();
    expect(profile, MoneyProfile.empty);
  });

  test('round-trips a saved profile through JSON', () async {
    SharedPreferences.setMockInitialValues({});
    await store.save(const MoneyProfile(birthYear: 1990, tfsaContributed: 12000));
    final loaded = await store.load();
    expect(loaded.birthYear, 1990);
    expect(loaded.tfsaContributed, 12000);
  });

  test('migrates a legacy birth-year key into the profile blob', () async {
    SharedPreferences.setMockInitialValues({kTfsaBirthYearKey: 1985});
    final loaded = await store.load();
    expect(loaded.birthYear, 1985);

    // The migration should have persisted the blob so it is stable next load.
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kMoneyProfileKey);
    expect(raw, isNotNull);
    expect(jsonDecode(raw!)['birthYear'], 1985);
  });

  test('prefers the blob over a legacy key when both exist', () async {
    SharedPreferences.setMockInitialValues({
      kTfsaBirthYearKey: 1985,
      kMoneyProfileKey: jsonEncode(const MoneyProfile(birthYear: 2000).toJson()),
    });
    final loaded = await store.load();
    expect(loaded.birthYear, 2000);
  });
}
