import 'package:flutter_test/flutter_test.dart';
import '../../tool/data_sources/runner.dart';
import '../../tool/data_sources/source.dart';

void main() {
  SourceResult ok(num v, num prev) =>
      SourceResult(v == prev ? SourceResultKind.noChange : SourceResultKind.change,
          value: v, previous: prev);
  SourceResult fail(String why) =>
      SourceResult(SourceResultKind.failure, reason: why);

  group('decideOutcome', () {
    test('all noChange → quiet (exit 0)', () {
      final o = decideOutcome({'tfsa': ok(7000, 7000)});
      expect(o.exitCode, 0);
      expect(o.changes, isEmpty);
      expect(o.failures, isEmpty);
    });

    test('a change, no failure → PR outcome (exit 10)', () {
      final o = decideOutcome(
          {'tfsa': ok(7500, 7000), 'rrsp': ok(33810, 33810)});
      expect(o.exitCode, 10);
      expect(o.changes, {'tfsa': 7500});
    });

    test('any failure → issue outcome (exit 20), precedence over changes', () {
      final o = decideOutcome({
        'tfsa': ok(7500, 7000),
        'oas': fail('could not parse'),
      });
      expect(o.exitCode, 20);
      expect(o.failures.length, 1);
      // changes are NOT applied when any source failed
      expect(o.changes, isEmpty);
    });

    test('summary lists each change old→new', () {
      final o = decideOutcome({'tfsa': ok(7500, 7000)});
      expect(o.summary, contains('tfsa'));
      expect(o.summary, contains('7000'));
      expect(o.summary, contains('7500'));
    });
  });
}
