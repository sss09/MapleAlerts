import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/data_sources/parsers.dart';

// Fixtures are LIVE captures (2026-06-03) trimmed to the section holding the
// figure, then wrapped in minimal <html>. Working source URLs (also recorded
// in tool/data_sources/parsers.dart):
//   tfsa/rrsp: canada.ca/.../pspa/mp-rrsp-dpsp-tfsa-limits-ympe.html
//   oas:       canada.ca/.../publicpensions/old-age-security/recovery-tax.html
//   ccb:       canada.ca/.../canada-child-benefit/how-much.html
// Expected values below are read directly from the *_good.html fixtures.
String fx(String name) => File('test/tool/fixtures/$name').readAsStringSync();

void main() {
  group('parseTfsaLimit', () {
    test('extracts the current limit from the good fixture', () {
      // tfsa_good.html: latest TFSA dollar limit row (2026) = $7,000.
      expect(parseTfsaLimit(fx('tfsa_good.html')), 7000);
    });
    test('returns null on mangled markup', () {
      expect(parseTfsaLimit(fx('tfsa_mangled.html')), isNull);
    });
  });

  group('parseRrspMax', () {
    test('extracts the current dollar max', () {
      // rrsp_good.html: latest *complete* RRSP dollar limit row (2026) =
      // $33,810. The 2027 row carries only the RRSP column (MP limit is "-").
      expect(parseRrspMax(fx('rrsp_good.html')), 33810);
    });
    test('null on mangled', () {
      expect(parseRrspMax(fx('rrsp_mangled.html')), isNull);
    });
  });

  group('parseOasRecoveryThreshold', () {
    test('extracts the threshold', () {
      // oas_good.html: minimum income recovery threshold for the latest
      // *final* (non-estimate, no <sup>) income year (2025) = $93,454.
      expect(parseOasRecoveryThreshold(fx('oas_good.html')), 93454);
    });
    test('null on mangled', () {
      expect(parseOasRecoveryThreshold(fx('oas_mangled.html')), isNull);
    });
  });

  group('parseCcb', () {
    test('extracts maxUnder6, max6to17, threshold1, threshold2', () {
      final r = parseCcb(fx('ccb_good.html'));
      expect(r, isNotNull);
      expect(r!.maxUnder6, 7997);
      expect(r.max6to17, 6748);
      expect(r.threshold1, 37487);
      expect(r.threshold2, 81222);
    });
    test('null on mangled', () {
      expect(parseCcb(fx('ccb_mangled.html')), isNull);
    });
  });
}
