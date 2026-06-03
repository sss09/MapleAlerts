import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  test('shipped web/datapack/pack.json parses and matches the embedded pack',
      () {
    const embedded = EmbeddedDataPack();
    final raw = File('web/datapack/pack.json').readAsStringSync();
    final pack = RemoteDataPack.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
      fallback: embedded,
    );

    expect(pack.packVersion, kEmbeddedPackVersion);
    expect(pack.tfsaAnnualLimit(2026), embedded.tfsaAnnualLimit(2026));
    expect(pack.tfsaFirstYear, embedded.tfsaFirstYear);
    expect(pack.rrspAnnualMax(2026), embedded.rrspAnnualMax(2026));
    expect(pack.rrspOverContributionBuffer,
        embedded.rrspOverContributionBuffer);
    expect(pack.fhsaLifetimeLimit, embedded.fhsaLifetimeLimit);
    expect(pack.ccbParams(2026).maxUnder6, embedded.ccbParams(2026).maxUnder6);
    expect(pack.ccbParams(2026).step2Rates,
        embedded.ccbParams(2026).step2Rates);
    expect(pack.oasParams(2026).recoveryThreshold,
        embedded.oasParams(2026).recoveryThreshold);
    expect(pack.federalBrackets(2026).length,
        embedded.federalBrackets(2026).length);
    for (final p in Province.values) {
      expect(pack.provincialBrackets(2026, p).length,
          embedded.provincialBrackets(2026, p).length,
          reason: 'province ${p.code} bracket count drifted');
    }
  });
}
