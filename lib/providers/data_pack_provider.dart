import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/canadian_data_engine/canadian_data_engine.dart';
import '../services/data_pack_service.dart';

/// Raw cached pack JSON. Seeded from prefs + refreshed over the air by
/// [initDataPack]; null until then (or when no cache exists).
final cachedPackJsonProvider = StateProvider<String?>((ref) => null);

/// Resolves which [DataPack] the app should use: the cached hosted pack when
/// it parses AND is strictly newer than the embedded one (so an app update
/// beats a stale cache), else the embedded pack.
DataPack resolveDataPack(String? cachedJson) {
  if (cachedJson == null) return const EmbeddedDataPack();
  try {
    final remote = RemoteDataPack.fromJson(
      jsonDecode(cachedJson) as Map<String, dynamic>,
      fallback: const EmbeddedDataPack(),
    );
    // ISO dates compare lexicographically.
    if (remote.packVersion.compareTo(kEmbeddedPackVersion) > 0) return remote;
  } catch (_) {
    // Unparseable cache — embedded wins.
  }
  return const EmbeddedDataPack();
}

/// The app-wide [DataPack] every rule provider reads.
final dataPackProvider = Provider<DataPack>(
    (ref) => resolveDataPack(ref.watch(cachedPackJsonProvider)));

/// Startup hook: seed the provider from the prefs cache, then refresh over
/// the air when stale. Fire-and-forget — never blocks or throws.
Future<void> initDataPack(ProviderContainer container,
    {DataPackService? service}) async {
  try {
    final svc = service ?? DataPackService();
    final cached = await svc.loadCached();
    if (cached != null) {
      container.read(cachedPackJsonProvider.notifier).state = cached;
    }
    final fresh = await svc.refreshIfStale();
    if (fresh != null) {
      container.read(cachedPackJsonProvider.notifier).state = fresh;
    }
  } catch (_) {
    // Fail-soft: embedded pack remains in effect.
  }
}
