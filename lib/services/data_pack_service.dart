import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/canadian_data_engine/canadian_data_engine.dart';
import '../utils/constants.dart';

/// Signature for the HTTP fetch — injectable so tests never hit the network.
typedef PackFetcher = Future<String> Function(Uri url);

/// Fetches + caches the hosted data pack (same pattern as [BocRateService]):
/// injectable fetcher, prefs cache, 24h TTL, every failure path swallowed.
class DataPackService {
  DataPackService({PackFetcher? fetch, DateTime Function()? now})
      : _fetch = fetch ?? _defaultFetch,
        _now = now ?? DateTime.now;

  final PackFetcher _fetch;
  final DateTime Function() _now;

  static Future<String> _defaultFetch(Uri url) async {
    final res = await http.get(url).timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) {
      throw http.ClientException('HTTP ${res.statusCode}', url);
    }
    return res.body;
  }

  /// The cached raw pack JSON, or null.
  Future<String?> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(kDataPackJsonKey);
    } catch (_) {
      return null;
    }
  }

  /// Fetches a fresh pack when the cache is older than [kDataPackTtl].
  /// Returns the fresh JSON on success, null when the cache is still fresh or
  /// anything fails (offline, bad status, pack fails validation) — in which
  /// case the previous cache is left untouched.
  Future<String?> refreshIfStale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fetchedAt =
          DateTime.tryParse(prefs.getString(kDataPackFetchedAtKey) ?? '');
      if (fetchedAt != null && _now().difference(fetchedAt) < kDataPackTtl) {
        return null; // cache is fresh
      }
      final body = await _fetch(Uri.parse(kDataPackUrl));
      // Validation gate: must parse as a supported pack before we cache it.
      RemoteDataPack.fromJson(
        jsonDecode(body) as Map<String, dynamic>,
        fallback: const EmbeddedDataPack(),
      );
      await prefs.setString(kDataPackJsonKey, body);
      await prefs.setString(
          kDataPackFetchedAtKey, _now().toIso8601String());
      return body;
    } catch (_) {
      return null; // fail-soft: keep whatever cache we had
    }
  }
}
