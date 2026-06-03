import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/providers/data_pack_provider.dart';

void main() {
  test('null cache resolves to the embedded pack', () {
    expect(resolveDataPack(null), isA<EmbeddedDataPack>());
  });

  test('garbage cache resolves to the embedded pack', () {
    expect(resolveDataPack('not json'), isA<EmbeddedDataPack>());
    expect(resolveDataPack('{"schemaVersion":99,"packVersion":"x"}'),
        isA<EmbeddedDataPack>());
  });

  test('an older or equal cached pack loses to embedded', () {
    expect(
        resolveDataPack(
            '{"schemaVersion":1,"packVersion":"2020-01-01"}'),
        isA<EmbeddedDataPack>());
    expect(
        resolveDataPack(
            '{"schemaVersion":1,"packVersion":"$kEmbeddedPackVersion"}'),
        isA<EmbeddedDataPack>());
  });

  test('a newer cached pack wins', () {
    final pack = resolveDataPack(
        '{"schemaVersion":1,"packVersion":"2099-01-01","tfsaAnnualLimits":{"2099":9000}}');
    expect(pack, isA<RemoteDataPack>());
    expect(pack.packVersion, '2099-01-01');
    expect(pack.tfsaAnnualLimit(2099), 9000);
    // Per-field fallback still reaches embedded data.
    expect(pack.tfsaAnnualLimit(2026), const EmbeddedDataPack().tfsaAnnualLimit(2026));
  });

  test('dataPackProvider follows cachedPackJsonProvider updates', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(dataPackProvider), isA<EmbeddedDataPack>());
    container.read(cachedPackJsonProvider.notifier).state =
        '{"schemaVersion":1,"packVersion":"2099-01-01"}';
    expect(container.read(dataPackProvider), isA<RemoteDataPack>());
  });
}
