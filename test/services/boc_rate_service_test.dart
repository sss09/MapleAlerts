import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maple_alerts/services/boc_rate_service.dart';
import 'package:maple_alerts/utils/constants.dart';

const _validJson =
    '{"observations":[{"d":"2026-04-16","V39079":{"v":"2.75"}}]}';

void main() {
  group('parseValetPolicyRate', () {
    test('parses the rate and date from a Valet observation', () {
      final r = parseValetPolicyRate(_validJson);
      expect(r.policyRate, 2.75);
      expect(r.asOf, DateTime(2026, 4, 16));
      expect(r.typicalPrime, closeTo(2.75 + kBocPrimeSpread, 1e-9));
    });

    test('throws on empty observations', () {
      expect(() => parseValetPolicyRate('{"observations":[]}'),
          throwsFormatException);
    });
  });

  group('BocRateService', () {
    test('refresh fetches, returns, and caches the rate', () async {
      SharedPreferences.setMockInitialValues({});
      final service = BocRateService(fetch: (_) async => _validJson);

      final rate = await service.refresh();
      expect(rate, isNotNull);
      expect(rate!.policyRate, 2.75);
      expect(rate.fromCache, isFalse);

      // Cached for next time.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kBocRateKey), isNotNull);
    });

    test('refresh falls back to cache when the fetch fails', () async {
      SharedPreferences.setMockInitialValues({});
      // First, seed the cache with a good fetch.
      await BocRateService(fetch: (_) async => _validJson).refresh();

      // Now a failing fetcher should return the cached value, flagged fromCache.
      final service =
          BocRateService(fetch: (_) async => throw Exception('network down'));
      final rate = await service.refresh();
      expect(rate, isNotNull);
      expect(rate!.policyRate, 2.75);
      expect(rate.fromCache, isTrue);
    });

    test('refresh returns null when fetch fails and there is no cache', () async {
      SharedPreferences.setMockInitialValues({});
      final service =
          BocRateService(fetch: (_) async => throw Exception('down'));
      expect(await service.refresh(), isNull);
    });

    test('load returns the cached value or null', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await BocRateService(fetch: (_) async => _validJson).load(), isNull);
      await BocRateService(fetch: (_) async => _validJson).refresh();
      final cached = await BocRateService(fetch: (_) async => _validJson).load();
      expect(cached!.policyRate, 2.75);
      expect(cached.fromCache, isTrue);
    });
  });
}
