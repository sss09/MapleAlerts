import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/canadian_data_engine/canadian_data_engine.dart';
import 'data_pack_provider.dart';
import 'money_profile_provider.dart';

/// The single highest-value recommended action right now, or null if there's
/// nothing actionable. Reasons across the configured accounts via the engine.
final bestMoveProvider = Provider<BestMove?>((ref) {
  final profile = ref.watch(moneyProfileProvider);
  return bestMove(
    profile: profile,
    asOf: DateTime.now(),
    dataPack: ref.watch(dataPackProvider),
  );
});
