import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/analytics/analytics_service.dart';

void main() {
  late List<(String, Map<String, Object>)> recorded;
  AnalyticsService make({bool enabled = true}) => AnalyticsService(
        sink: (e, p) => recorded.add((e, p)),
        isEnabled: () => enabled,
      );

  setUp(() => recorded = []);

  group('AnalyticsService.track', () {
    test('forwards event name and props to the sink', () {
      make().track('topic_enabled', {'topic': 'tfsa'});
      expect(recorded.length, 1);
      expect(recorded.first.$1, 'topic_enabled');
      expect(recorded.first.$2, {'topic': 'tfsa'});
    });

    test('drops events when disabled', () {
      make(enabled: false).track('topic_enabled', {'topic': 'tfsa'});
      expect(recorded, isEmpty);
    });

    test('swallows sink exceptions (fire-and-forget)', () {
      final svc = AnalyticsService(
        sink: (_, __) => throw StateError('network down'),
        isEnabled: () => true,
      );
      expect(() => svc.track('paywall_viewed'), returnsNormally);
    });

    test('de-dupes insight_card_viewed per id per session', () {
      final svc = make();
      svc.track('insight_card_viewed', {'id': 'tfsa_room'});
      svc.track('insight_card_viewed', {'id': 'tfsa_room'});
      svc.track('insight_card_viewed', {'id': 'rrsp_room'});
      expect(recorded.length, 2);
    });

    test('de-dupes best_move_shown per kind+target per session', () {
      final svc = make();
      svc.track('best_move_shown', {'kind': 'opportunity', 'target': 'rrsp_room'});
      svc.track('best_move_shown', {'kind': 'opportunity', 'target': 'rrsp_room'});
      expect(recorded.length, 1);
    });

    test('does not de-dupe other events', () {
      final svc = make();
      svc.track('reminder_added', {'category': 'finance'});
      svc.track('reminder_added', {'category': 'finance'});
      expect(recorded.length, 2);
    });

    test('asserts on denylisted property names (debug-mode PII guard)', () {
      expect(() => make().track('bad_event', {'income': '90000'}),
          throwsAssertionError);
      expect(() => make().track('bad_event', {'amount': '5'}),
          throwsAssertionError);
    });
  });
}
