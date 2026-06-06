import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/canadian_data_engine/canadian_data_engine.dart';
import '../features/money/presentation/money_insight.dart';
import 'data_pack_provider.dart';
import 'money_profile_provider.dart';
import 'tfsa_insight_provider.dart';

/// RRSP room + tax-savings + deadline insights from the current profile.
final rrspInsightsProvider = Provider<List<MoneyInsight>>((ref) {
  final profile = ref.watch(moneyProfileProvider);

  final result = rrspRule(
    profile: profile,
    asOf: DateTime.now(),
    dataPack: ref.watch(dataPackProvider),
  );

  final hasRequiredInput = profile.province != null &&
      profile.annualIncome != null &&
      profile.rrspDeductionLimit != null &&
      profile.rrspContributed != null;

  return rrspInsights(result, hasRequiredInput: hasRequiredInput);
});

/// Canada Child Benefit monthly-estimate insight from the current profile.
final ccbInsightsProvider = Provider<List<MoneyInsight>>((ref) {
  final profile = ref.watch(moneyProfileProvider);

  final result = ccbRule(
    profile: profile,
    asOf: DateTime.now(),
    dataPack: ref.watch(dataPackProvider),
  );

  final hasRequiredInput = profile.familyNetIncome != null &&
      profile.kidsUnder6 != null &&
      profile.kids6to17 != null;

  return ccbInsights(result, hasRequiredInput: hasRequiredInput);
});

/// OAS recovery-tax (clawback) insight from the current profile.
final oasInsightsProvider = Provider<List<MoneyInsight>>((ref) {
  final profile = ref.watch(moneyProfileProvider);

  final result = oasRule(
    profile: profile,
    asOf: DateTime.now(),
    dataPack: ref.watch(dataPackProvider),
  );

  final hasRequiredInput =
      profile.birthYear != null && profile.annualIncome != null;

  return oasInsights(result, hasRequiredInput: hasRequiredInput);
});

/// Tracked-GIC maturity insight from the current profile.
final gicInsightsProvider = Provider<List<MoneyInsight>>((ref) {
  final profile = ref.watch(moneyProfileProvider);

  final result = gicRule(profile: profile, asOf: DateTime.now());

  final hasRequiredInput = profile.gicAmount != null &&
      profile.gicAmount! > 0 &&
      profile.gicMaturityDate != null;

  return gicInsights(
    result,
    hasRequiredInput: hasRequiredInput,
    rates: ref.watch(dataPackProvider).rates,
  );
});

/// FHSA room + deduction-savings insight from the current profile.
final fhsaInsightsProvider = Provider<List<MoneyInsight>>((ref) {
  final profile = ref.watch(moneyProfileProvider);
  final result =
      fhsaRule(profile: profile, asOf: DateTime.now(), dataPack: ref.watch(dataPackProvider));
  return fhsaInsights(result, hasRequiredInput: profile.fhsaContributed != null);
});

/// The single list of money insights the Home "Found money" surface renders —
/// TFSA + RRSP + FHSA + CCB + OAS + GIC. The "best move" card ranks over this.
final moneyInsightsProvider = Provider<List<MoneyInsight>>((ref) {
  return [
    ...ref.watch(tfsaInsightsProvider),
    ...ref.watch(rrspInsightsProvider),
    ...ref.watch(fhsaInsightsProvider),
    ...ref.watch(ccbInsightsProvider),
    ...ref.watch(oasInsightsProvider),
    ...ref.watch(gicInsightsProvider),
  ];
});
