import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  const fallback = EmbeddedDataPack();

  Map<String, dynamic> fullJson() => {
        'schemaVersion': 1,
        'packVersion': '2027-01-01',
        'tfsaAnnualLimits': {'2009': 5000, '2026': 7000, '2027': 7500},
        'rrspAnnualMax': {'2027': 34000},
        'rrspOverContributionBuffer': 2000,
        'fhsa': {'annualLimit': 8000, 'lifetimeLimit': 40000},
        'ccb': {
          'maxUnder6': 8100.0,
          'max6to17': 6800.0,
          'threshold1': 38000.0,
          'threshold2': 82000.0,
          'step1Rates': [0.07, 0.135, 0.19, 0.23],
          'step2Rates': [0.032, 0.057, 0.08, 0.095],
        },
        'oas': {
          'recoveryThreshold': 95000.0,
          'recoveryRate': 0.15,
          'upperThreshold65to74': 153000.0,
          'upperThreshold75plus': 159000.0,
        },
        'tax': {
          'federal': [
            [0, 0.14],
            [60000, 0.205],
          ],
          'provincial': {
            'on': [
              [0, 0.0505],
              [55000, 0.0915],
            ],
          },
        },
      };

  group('RemoteDataPack.fromJson', () {
    test('full pack overrides every member', () {
      final pack = RemoteDataPack.fromJson(fullJson(), fallback: fallback);
      expect(pack.packVersion, '2027-01-01');
      expect(pack.tfsaAnnualLimit(2027), 7500);
      expect(pack.tfsaLatestYear, 2027);
      expect(pack.tfsaFirstYear, 2009);
      expect(pack.rrspAnnualMax(2027), 34000);
      expect(pack.rrspOverContributionBuffer, 2000);
      expect(pack.fhsaAnnualLimit, 8000);
      expect(pack.fhsaLifetimeLimit, 40000);
      expect(pack.ccbParams(2027).maxUnder6, 8100);
      expect(pack.oasParams(2027).recoveryThreshold, 95000);
      expect(pack.federalBrackets(2027).first.rate, 0.14);
      expect(pack.federalBrackets(2027)[1].lowerBound, 60000);
      expect(pack.provincialBrackets(2027, Province.on)[1].lowerBound, 55000);
    });

    test('empty pack delegates everything to the fallback', () {
      final pack = RemoteDataPack.fromJson(
        {'schemaVersion': 1, 'packVersion': '2027-01-01'},
        fallback: fallback,
      );
      expect(pack.tfsaAnnualLimit(2026), fallback.tfsaAnnualLimit(2026));
      expect(pack.tfsaFirstYear, fallback.tfsaFirstYear);
      expect(pack.rrspAnnualMax(2026), fallback.rrspAnnualMax(2026));
      expect(pack.ccbParams(2026).maxUnder6, fallback.ccbParams(2026).maxUnder6);
      expect(pack.oasParams(2026).recoveryThreshold,
          fallback.oasParams(2026).recoveryThreshold);
      expect(pack.fhsaLifetimeLimit, fallback.fhsaLifetimeLimit);
      expect(pack.federalBrackets(2026).length,
          fallback.federalBrackets(2026).length);
      expect(pack.provincialBrackets(2026, Province.bc).length,
          fallback.provincialBrackets(2026, Province.bc).length);
    });

    test('a year missing from a present table delegates to the fallback', () {
      final json = {
        'schemaVersion': 1,
        'packVersion': '2027-01-01',
        'tfsaAnnualLimits': {'2027': 7500},
      };
      final pack = RemoteDataPack.fromJson(json, fallback: fallback);
      expect(pack.tfsaAnnualLimit(2027), 7500);
      expect(pack.tfsaAnnualLimit(2020), fallback.tfsaAnnualLimit(2020));
    });

    test('one corrupt section falls back alone, others still apply', () {
      final json = fullJson();
      json['ccb'] = {'maxUnder6': 'not-a-number'};
      final pack = RemoteDataPack.fromJson(json, fallback: fallback);
      expect(pack.ccbParams(2026).maxUnder6, fallback.ccbParams(2026).maxUnder6);
      expect(pack.tfsaAnnualLimit(2027), 7500); // unaffected
    });

    test('an unknown province key is skipped, not fatal to the whole map', () {
      // Future pack adds a region this build's Province enum doesn't know —
      // known provinces must still get the remote brackets (review finding).
      final json = fullJson();
      (json['tax'] as Map)['provincial'] = {
        'on': [
          [0, 0.0505],
          [55000, 0.0915],
        ],
        'zz': [
          [0, 0.01],
        ],
      };
      final pack = RemoteDataPack.fromJson(json, fallback: fallback);
      expect(pack.provincialBrackets(2027, Province.on)[1].lowerBound, 55000);
      // Unlisted provinces still fall back per-province.
      expect(pack.provincialBrackets(2027, Province.bc).length,
          fallback.provincialBrackets(2027, Province.bc).length);
    });

    test('unsupported schemaVersion throws', () {
      expect(
        () => RemoteDataPack.fromJson(
            {'schemaVersion': 2, 'packVersion': 'x'}, fallback: fallback),
        throwsFormatException,
      );
    });

    test('missing packVersion throws', () {
      expect(
        () => RemoteDataPack.fromJson({'schemaVersion': 1}, fallback: fallback),
        throwsFormatException,
      );
    });
  });

  test('EmbeddedDataPack.packVersion is the comparable ISO-date constant', () {
    expect(fallback.packVersion, kEmbeddedPackVersion);
    expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(kEmbeddedPackVersion), isTrue);
  });
}
