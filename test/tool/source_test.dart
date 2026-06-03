import 'package:flutter_test/flutter_test.dart';
import '../../tool/data_sources/source.dart';

void main() {
  num? always7000(String _) => 7000;
  num? alwaysNull(String _) => null;

  WatchedSource src(num? Function(String) parser) => WatchedSource(
        id: 'tfsa',
        label: 'TFSA annual limit',
        url: Uri.parse('https://example.test/tfsa'),
        parse: parser,
        min: 5000,
        max: 20000,
        step: 500,
      );

  group('WatchedSource.evaluate', () {
    test('in-band value equal to current → noChange', () {
      final r = src(always7000).evaluate('<html/>', current: 7000);
      expect(r.kind, SourceResultKind.noChange);
      expect(r.value, 7000);
    });

    test('in-band value different from current → change', () {
      final r = src(always7000).evaluate('<html/>', current: 6500);
      expect(r.kind, SourceResultKind.change);
      expect(r.value, 7000);
    });

    test('parser returns null → failure', () {
      final r = src(alwaysNull).evaluate('<html/>', current: 7000);
      expect(r.kind, SourceResultKind.failure);
      expect(r.reason, contains('could not parse'));
    });

    test('value below min → failure (misparse guard)', () {
      final r = src((_) => 100).evaluate('<html/>', current: 7000);
      expect(r.kind, SourceResultKind.failure);
      expect(r.reason, contains('out of range'));
    });

    test('value above max → failure (the \$75,000 guard)', () {
      final r = src((_) => 75000).evaluate('<html/>', current: 7000);
      expect(r.kind, SourceResultKind.failure);
    });

    test('value violating step → failure', () {
      final r = src((_) => 7200).evaluate('<html/>', current: 7000);
      expect(r.kind, SourceResultKind.failure);
      expect(r.reason, contains('step'));
    });

    test('null step skips the step check', () {
      final s = WatchedSource(
        id: 'oas', label: 'OAS', url: Uri.parse('https://x.test'),
        parse: (_) => 95000, min: 50000, max: 200000, step: null);
      final r = s.evaluate('<html/>', current: 93454);
      expect(r.kind, SourceResultKind.change);
    });
  });
}
