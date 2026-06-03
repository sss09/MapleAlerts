// Regenerates web/datapack/pack.json from the embedded tables.
// Run after any embedded-table change:  dart run tool/generate_data_pack.dart
import 'dart:convert';
import 'dart:io';

import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  const pack = EmbeddedDataPack();
  const year = 2026; // representative year for the year-keyed param lookups
  final ccb = pack.ccbParams(year);
  final oas = pack.oasParams(year);

  List<List<num>> brackets(List<TaxBracket> bs) =>
      bs.map((b) => [b.lowerBound, b.rate]).toList();

  final json = <String, dynamic>{
    'schemaVersion': kSupportedPackSchemaVersion,
    'packVersion': kEmbeddedPackVersion,
    'tfsaAnnualLimits': {
      for (var y = pack.tfsaFirstYear; y <= pack.tfsaLatestYear; y++)
        '$y': pack.tfsaAnnualLimit(y),
    },
    'rrspAnnualMax': {
      for (final e in kRrspAnnualMax.entries) '${e.key}': e.value,
    },
    'rrspOverContributionBuffer': pack.rrspOverContributionBuffer,
    'fhsa': {
      'annualLimit': pack.fhsaAnnualLimit,
      'lifetimeLimit': pack.fhsaLifetimeLimit,
    },
    'ccb': {
      'maxUnder6': ccb.maxUnder6,
      'max6to17': ccb.max6to17,
      'threshold1': ccb.threshold1,
      'threshold2': ccb.threshold2,
      'step1Rates': ccb.step1Rates,
      'step2Rates': ccb.step2Rates,
    },
    'oas': {
      'recoveryThreshold': oas.recoveryThreshold,
      'recoveryRate': oas.recoveryRate,
      'upperThreshold65to74': oas.upperThreshold65to74,
      'upperThreshold75plus': oas.upperThreshold75plus,
    },
    'tax': {
      'federal': brackets(pack.federalBrackets(year)),
      'provincial': {
        for (final p in Province.values)
          if (pack.provincialBrackets(year, p).isNotEmpty)
            p.name: brackets(pack.provincialBrackets(year, p)),
      },
    },
  };

  final file = File('web/datapack/pack.json');
  file.createSync(recursive: true);
  file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n');
  stdout.writeln('Wrote ${file.path} (packVersion $kEmbeddedPackVersion)');
}
