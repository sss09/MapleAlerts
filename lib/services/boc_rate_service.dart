import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

/// A Bank of Canada policy-rate snapshot.
class BocRate {
  /// Target for the overnight rate, as a percent (e.g. 2.75).
  final double policyRate;

  /// The observation date the rate is "as of".
  final DateTime asOf;

  /// Whether this came from the offline cache (vs a fresh fetch).
  final bool fromCache;

  const BocRate({
    required this.policyRate,
    required this.asOf,
    this.fromCache = false,
  });

  /// Typical chartered-bank prime = policy + standing spread (banks set their
  /// own; shown as a "typical" figure).
  double get typicalPrime => policyRate + kBocPrimeSpread;

  BocRate copyWith({bool? fromCache}) => BocRate(
        policyRate: policyRate,
        asOf: asOf,
        fromCache: fromCache ?? this.fromCache,
      );

  Map<String, dynamic> toJson() => {
        'policyRate': policyRate,
        'asOf': asOf.toIso8601String(),
      };

  factory BocRate.fromJson(Map<String, dynamic> json) => BocRate(
        policyRate: (json['policyRate'] as num).toDouble(),
        asOf: DateTime.parse(json['asOf'] as String),
        fromCache: true,
      );
}

/// Parses a Valet `observations` JSON payload for the policy-rate series into a
/// [BocRate]. Throws [FormatException] when no usable observation is present.
BocRate parseValetPolicyRate(String body) {
  final decoded = jsonDecode(body);
  final obs = (decoded is Map) ? decoded['observations'] : null;
  if (obs is! List || obs.isEmpty) {
    throw const FormatException('No observations in Valet response');
  }
  final latest = obs.last as Map<String, dynamic>;
  final dateStr = latest['d'] as String?;
  final series = latest[kBocValetPolicySeries];
  final valueStr = (series is Map) ? series['v'] as String? : null;
  if (dateStr == null || valueStr == null) {
    throw const FormatException('Malformed Valet observation');
  }
  final rate = double.tryParse(valueStr);
  if (rate == null) throw const FormatException('Non-numeric rate');
  return BocRate(policyRate: rate, asOf: DateTime.parse(dateStr));
}

/// Signature for the HTTP fetch — injectable so tests never hit the network.
typedef Fetcher = Future<String> Function(Uri url);

/// Fetches + caches the BoC policy rate from the free Valet API. Degrades
/// gracefully: a failed fetch falls back to the cached value (if any).
class BocRateService {
  BocRateService({Fetcher? fetch}) : _fetch = fetch ?? _defaultFetch;

  final Fetcher _fetch;

  static Future<String> _defaultFetch(Uri url) async {
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw http.ClientException('HTTP ${res.statusCode}', url);
    }
    return res.body;
  }

  /// The cached rate, or null if none stored.
  Future<BocRate?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kBocRateKey);
    if (raw == null) return null;
    try {
      return BocRate.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Fetches a fresh rate and caches it; on any failure returns the cached
  /// value (flagged [BocRate.fromCache]) or null.
  Future<BocRate?> refresh() async {
    try {
      final body = await _fetch(Uri.parse(kBocValetPolicyRateUrl));
      final rate = parseValetPolicyRate(body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kBocRateKey, jsonEncode(rate.toJson()));
      return rate;
    } catch (_) {
      return load();
    }
  }
}
