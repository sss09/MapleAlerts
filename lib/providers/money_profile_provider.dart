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

  Future<void> setProvince(Province? province) => _update(state.copyWith(
        province: province,
        clearProvince: province == null,
      ));

  Future<void> setAnnualIncome(double? amount) => _update(state.copyWith(
        annualIncome: amount,
        clearAnnualIncome: amount == null,
      ));

  Future<void> setRrspDeductionLimit(double? amount) => _update(state.copyWith(
        rrspDeductionLimit: amount,
        clearRrspDeductionLimit: amount == null,
      ));

  Future<void> setRrspContributed(double? amount) => _update(state.copyWith(
        rrspContributed: amount,
        clearRrspContributed: amount == null,
      ));

  Future<void> setFhsaContributed(double? amount) => _update(state.copyWith(
        fhsaContributed: amount,
        clearFhsaContributed: amount == null,
      ));

  Future<void> setSavingsBalance(double? amount) => _update(state.copyWith(
        savingsBalance: amount,
        clearSavingsBalance: amount == null,
      ));

  /// Sets the mortgage renewal date (used by the mortgage setup sheet).
  Future<void> setMortgageRenewalDate(DateTime date) =>
      _update(state.copyWith(mortgageRenewalDate: date));

  /// Clears the mortgage renewal date.
  Future<void> clearMortgageRenewalDate() =>
      _update(state.copyWith(clearMortgageRenewalDate: true));

  /// Sets the tracked GIC (used by the GIC setup sheet).
  Future<void> setGic({
    required double amount,
    required DateTime maturityDate,
  }) =>
      _update(state.copyWith(gicAmount: amount, gicMaturityDate: maturityDate));

  /// Clears the tracked GIC.
  Future<void> clearGic() => _update(
        state.copyWith(clearGicAmount: true, clearGicMaturityDate: true),
      );

  /// Sets the CCB inputs at once (used by the CCB setup sheet).
  Future<void> setCcbInputs({
    required int kidsUnder6,
    required int kids6to17,
    required double familyNetIncome,
  }) =>
      _update(state.copyWith(
        kidsUnder6: kidsUnder6,
        kids6to17: kids6to17,
        familyNetIncome: familyNetIncome,
      ));

  /// Sets all four RRSP-related inputs at once (used by the RRSP setup sheet).
  Future<void> setRrspInputs({
    required Province province,
    required double annualIncome,
    required double deductionLimit,
    required double contributed,
  }) =>
      _update(state.copyWith(
        province: province,
        annualIncome: annualIncome,
        rrspDeductionLimit: deductionLimit,
        rrspContributed: contributed,
      ));
}
