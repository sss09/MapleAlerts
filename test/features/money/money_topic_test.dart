import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/features/money/presentation/money_insight.dart';
import 'package:maple_alerts/features/money/presentation/money_topic.dart';

MoneyInsight insight(String id, InsightKind kind) => MoneyInsight(
      id: id,
      kind: kind,
      severity: InsightSeverity.positive,
      headline: id,
    );

void main() {
  group('topic ↔ insight mapping', () {
    test('resolves topics from insight ids', () {
      expect(MoneyTopic.fromInsightId('tfsa_room'), MoneyTopic.tfsa);
      expect(MoneyTopic.fromInsightId('rrsp_room'), MoneyTopic.rrsp);
      expect(MoneyTopic.fromInsightId('ccb'), MoneyTopic.ccb);
      expect(MoneyTopic.fromInsightId('unknown'), isNull);
    });
  });

  group('codec + defaults', () {
    test('defaults enable TFSA and RRSP but not CCB', () {
      expect(kDefaultEnabledTopics, {MoneyTopic.tfsa, MoneyTopic.rrsp});
    });

    test('null/absent names decode to the defaults', () {
      expect(topicsFromNames(null), kDefaultEnabledTopics);
    });

    test('round-trips a set through names', () {
      final set = {MoneyTopic.tfsa, MoneyTopic.ccb};
      expect(topicsFromNames(topicsToNames(set)), set);
    });

    test('an explicitly empty list decodes to an empty set (not defaults)', () {
      expect(topicsFromNames(const []), isEmpty);
    });
  });

  group('partitionFoundMoney', () {
    test('hides disabled topics and splits setup vs real cards', () {
      final insights = [
        insight('tfsa_room', InsightKind.setup),
        insight('rrsp_room', InsightKind.foundMoney),
        insight('ccb', InsightKind.setup),
      ];
      final view =
          partitionFoundMoney(insights, {MoneyTopic.tfsa, MoneyTopic.rrsp});

      expect(view.cards.map((i) => i.id), ['rrsp_room']);
      expect(view.setups.map((i) => i.id), ['tfsa_room']); // ccb hidden
    });

    test('enabling CCB surfaces its setup prompt', () {
      final insights = [
        insight('ccb', InsightKind.setup),
      ];
      final view = partitionFoundMoney(insights, {MoneyTopic.ccb});
      expect(view.setups.map((i) => i.id), ['ccb']);
    });
  });
}
