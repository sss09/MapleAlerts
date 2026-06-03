import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/services/data_pack_service.dart';
import 'package:maple_alerts/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _validPack =
    '{"schemaVersion":1,"packVersion":"2099-01-01"}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 6, 2, 12);

  test('refreshIfStale fetches, validates and caches when no cache exists',
      () async {
    SharedPreferences.setMockInitialValues({});
    var fetches = 0;
    final svc = DataPackService(
      fetch: (_) async {
        fetches++;
        return _validPack;
      },
      now: () => now,
    );

    final fresh = await svc.refreshIfStale();
    expect(fresh, _validPack);
    expect(fetches, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kDataPackJsonKey), _validPack);
    expect(prefs.getString(kDataPackFetchedAtKey), now.toIso8601String());
  });

  test('refreshIfStale is a no-op when the cache is fresh', () async {
    SharedPreferences.setMockInitialValues({
      kDataPackJsonKey: _validPack,
      kDataPackFetchedAtKey:
          now.subtract(const Duration(hours: 1)).toIso8601String(),
    });
    var fetches = 0;
    final svc = DataPackService(
      fetch: (_) async {
        fetches++;
        return _validPack;
      },
      now: () => now,
    );
    expect(await svc.refreshIfStale(), isNull);
    expect(fetches, 0);
  });

  test('refreshIfStale fetches again when the cache is older than 24h',
      () async {
    SharedPreferences.setMockInitialValues({
      kDataPackJsonKey: _validPack,
      kDataPackFetchedAtKey:
          now.subtract(const Duration(hours: 25)).toIso8601String(),
    });
    var fetches = 0;
    final svc = DataPackService(
      fetch: (_) async {
        fetches++;
        return _validPack;
      },
      now: () => now,
    );
    expect(await svc.refreshIfStale(), _validPack);
    expect(fetches, 1);
  });

  test('a failed fetch keeps the previous cache and returns null', () async {
    SharedPreferences.setMockInitialValues({
      kDataPackJsonKey: _validPack,
      kDataPackFetchedAtKey:
          now.subtract(const Duration(hours: 25)).toIso8601String(),
    });
    final svc = DataPackService(
      fetch: (_) async => throw Exception('offline'),
      now: () => now,
    );
    expect(await svc.refreshIfStale(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kDataPackJsonKey), _validPack);
  });

  test('a pack that fails validation is not cached', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = DataPackService(
      fetch: (_) async => '{"schemaVersion":99,"packVersion":"x"}',
      now: () => now,
    );
    expect(await svc.refreshIfStale(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kDataPackJsonKey), isNull);
  });

  test('loadCached returns the stored JSON or null', () async {
    SharedPreferences.setMockInitialValues({kDataPackJsonKey: _validPack});
    expect(await DataPackService(now: () => now).loadCached(), _validPack);
    SharedPreferences.setMockInitialValues({});
    expect(await DataPackService(now: () => now).loadCached(), isNull);
  });
}
