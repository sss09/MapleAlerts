import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/data_sources/pack_merge.dart';

void main() {
  Map<String, dynamic> base() => {
        'schemaVersion': 1,
        'packVersion': '2026-06-02',
        'tfsaAnnualLimits': {'2026': 7000},
        'rrspAnnualMax': {'2026': 33810},
        'oas': {'recoveryThreshold': 93454, 'recoveryRate': 0.15},
        'ccb': {
          'maxUnder6': 7997, 'max6to17': 6748,
          'threshold1': 37487, 'threshold2': 81222,
        },
      };

  test('currentValueFor reads the right field', () {
    final p = base();
    expect(currentValueFor(p, 'tfsa', 2027), 7000); // latest known
    expect(currentValueFor(p, 'rrsp', 2027), 33810);
    expect(currentValueFor(p, 'oas', 2027), 93454);
    expect(currentValueFor(p, 'ccb_maxUnder6', 2027), 7997);
  });

  test('applyChange writes a new figure and bumps packVersion', () {
    final p = base();
    final out = applyChange(p, {'tfsa': 7500}, year: 2027,
        newVersion: '2027-01-15');
    expect((out['tfsaAnnualLimits'] as Map)['2027'], 7500);
    expect(out['packVersion'], '2027-01-15');
    // untouched fields preserved
    expect((out['rrspAnnualMax'] as Map)['2026'], 33810);
  });

  test('applyChange updates a nested ccb field in place', () {
    final out = applyChange(base(), {'ccb_maxUnder6': 8100}, year: 2027,
        newVersion: '2027-07-01');
    expect((out['ccb'] as Map)['maxUnder6'], 8100);
  });

  test('round-trips through json without losing structure', () {
    final out = applyChange(base(), {'oas': 95000}, year: 2027,
        newVersion: '2027-01-15');
    final reparsed = jsonDecode(jsonEncode(out)) as Map<String, dynamic>;
    expect((reparsed['oas'] as Map)['recoveryThreshold'], 95000);
  });
}
