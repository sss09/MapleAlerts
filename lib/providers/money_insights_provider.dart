import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/canadian_data_engine/canadian_data_engine.dart';
import '../features/money/presentation/money_insight.dart';
import 'money_profile_provider.dart';
import 'tfsa_insight_provider.dart';

/// RRSP room + tax-savings + deadline insights from the current profile.
final rrspInsightsProvider = Provider<List<MoneyInsight>>((ref) {
  final profile = ref.watch(moneyProfileProvider);

  final result = rrspRule(
    profile: profile,
    asOf: DateTime.now(),
    dataPack: const EmbeddedDataPack(),
  );

  final hasRequiredInput = profile.province != null &&
      profile.annualIncome != null &&
      profile.rrspDeductionLimit != null &&
      profile.rrspContributed != null;

  return rrspInsights(result, hasRequiredInput: hasRequiredInput);
});

/// The single list of money insights the Home "Found money" surface renders —
/// today TFSA + RRSP. A future "best move" surface ranks over this same list.
final moneyInsightsProvider = Provider<List<MoneyInsight>>((ref) {
  return [
    ...ref.watch(tfsaInsightsProvider),
    ...ref.watch(rrspInsightsProvider),
  ];
});
