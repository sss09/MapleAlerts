import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  group('RatesData', () {
    test('parses from json correctly', () {
      final r = RatesData.fromJson({
        'asOf': '2026-06-05',
        'disclaimer': 'Verify rates.',
        'hisa': [
          {
            'id': 'eq_bank',
            'name': 'EQ Bank',
            'rate': 4.75,
            'insurance': 'CDIC',
            'tier': 1,
            'hasAffiliate': true
          },
          {
            'id': 'big_bank',
            'name': 'Big bank',
            'rate': 0.05,
            'insurance': 'CDIC',
            'tier': 3,
            'hasAffiliate': false
          },
        ],
        'gic_1yr': [
          {
            'id': 'oaken',
            'name': 'Oaken',
            'rate': 4.90,
            'insurance': 'CDIC',
            'hasAffiliate': false
          }
        ],
      });

      expect(r.asOf, '2026-06-05');
      expect(r.hisa.length, 2);
      expect(r.bestHisa?.id, 'eq_bank');
      expect(r.bigBankRate, 0.05);
      expect(r.bestGic1yr?.rate, 4.90);
    });

    test('falls back to empty on missing keys', () {
      final r = RatesData.fromJson({});
      expect(r, same(RatesData.empty));
    });

    test('bestHisa returns null when no tier-1 entries', () {
      final r = RatesData.fromJson({
        'hisa': [
          {
            'id': 'motive',
            'name': 'Motive',
            'rate': 4.55,
            'insurance': 'CDIC',
            'tier': 2,
            'hasAffiliate': false
          }
        ],
      });
      expect(r.bestHisa, isNull);
    });

    test('bestGic1yr returns null when gic_1yr is empty', () {
      final r = RatesData.fromJson({'gic_1yr': []});
      expect(r.bestGic1yr, isNull);
    });

    test('note field is optional', () {
      final r = RatesData.fromJson({
        'hisa': [
          {
            'id': 'x',
            'name': 'X Bank',
            'rate': 4.0,
            'insurance': 'CDIC',
            'tier': 1,
            'hasAffiliate': false,
            // no 'note' key
          }
        ],
      });
      expect(r.hisa.first.note, isNull);
    });

    test('tier defaults to 1 when absent', () {
      final rate = InstitutionRate.fromJson({
        'id': 'x',
        'name': 'X',
        'rate': 3.0,
        'insurance': 'CDIC',
        'hasAffiliate': false,
        // no 'tier'
      });
      expect(rate.tier, 1);
    });

    test('pack.json parses without error and has rates', () {
      final raw = File('web/datapack/pack.json').readAsStringSync();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final rates = RatesData.fromJson(
          decoded['rates'] as Map<String, dynamic>? ?? {});
      expect(rates.hisa, isNotEmpty);
      expect(rates.gic1yr, isNotEmpty);
      expect(rates.asOf, '2026-06-05');
      expect(rates.bestHisa, isNotNull);
      expect(rates.bestGic1yr, isNotNull);
      expect(rates.bigBankRate, 0.05);
    });

    test('RemoteDataPack exposes rates from pack.json', () {
      final raw = File('web/datapack/pack.json').readAsStringSync();
      final pack = RemoteDataPack.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
        fallback: const EmbeddedDataPack(),
      );
      expect(pack.rates.hisa, isNotEmpty);
      expect(pack.rates.gic1yr, isNotEmpty);
      expect(pack.rates.bestHisa?.id, 'eq_bank');
    });
  });
}
