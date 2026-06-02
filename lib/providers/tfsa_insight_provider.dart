import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/canadian_data_engine/canadian_data_engine.dart';
import '../features/money/presentation/money_insight.dart';
import 'money_profile_provider.dart';

/// Runs the TFSA room rule over the current [MoneyProfile] and the embedded
/// data pack, then projects the result onto presentation [MoneyInsight]s for
/// the "Found money" section to render.
final tfsaInsightsProvider = Provider<List<MoneyInsight>>((ref) {
  final profile = ref.watch(moneyProfileProvider);

  final result = tfsaRule(
    profile: profile,
    asOf: DateTime.now(),
    dataPack: const EmbeddedDataPack(),
  );

  final hasRequiredInput =
      profile.birthYear != null && profile.tfsaContributed != null;

  return tfsaInsights(result, hasRequiredInput: hasRequiredInput);
});
