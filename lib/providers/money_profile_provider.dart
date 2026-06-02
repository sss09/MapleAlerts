import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/canadian_data_engine/canadian_data_engine.dart';
import '../services/money_profile_store.dart';

/// Holds the user's [MoneyProfile] (the financial inputs the engine reads).
/// Loads from [MoneyProfileStore] on creation and persists on every change.
final moneyProfileProvider =
    StateNotifierProvider<MoneyProfileNotifier, MoneyProfile>((ref) {
  return MoneyProfileNotifier();
});

class MoneyProfileNotifier extends StateNotifier<MoneyProfile> {
  MoneyProfileNotifier({MoneyProfileStore store = const MoneyProfileStore()})
      : _store = store,
        super(MoneyProfile.empty) {
    _load();
  }

  final MoneyProfileStore _store;

  Future<void> _load() async {
    state = await _store.load();
  }

  Future<void> _update(MoneyProfile next) async {
    state = next;
    await _store.save(next);
  }

  Future<void> setBirthYear(int? year) =>
      _update(state.copyWith(birthYear: year, clearBirthYear: year == null));

  Future<void> setTfsaContributed(double? amount) => _update(state.copyWith(
        tfsaContributed: amount,
        clearTfsaContributed: amount == null,
      ));
}
