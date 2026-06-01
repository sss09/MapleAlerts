import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/tokens/maple_aurora.dart';

void main() {
  test('registry has the 4 aurora systems', () {
    for (final k in ['emerald', 'teal', 'arctic', 'lights']) {
      expect(kAuroras.containsKey(k), isTrue, reason: 'missing $k');
    }
  });
  test('each aurora has base stops and 3 blobs', () {
    for (final a in kAuroras.values) {
      expect(a.baseStops.length, greaterThanOrEqualTo(2));
      expect(a.blobs.length, 3);
    }
  });
}
