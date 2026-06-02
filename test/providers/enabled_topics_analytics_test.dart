import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/analytics/analytics_service.dart';
import 'package:maple_alerts/features/money/presentation/money_topic.dart';
import 'package:maple_alerts/providers/enabled_topics_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('toggle emits topic_enabled / topic_disabled', () async {
    SharedPreferences.setMockInitialValues({});
    final recorded = <(String, Map<String, Object>)>[];
    final notifier = EnabledTopicsNotifier(
      analytics: AnalyticsService(
        sink: (e, p) => recorded.add((e, p)),
        isEnabled: () => true,
      ),
    );

    await notifier.setEnabled(MoneyTopic.ccb, true);
    await notifier.setEnabled(MoneyTopic.ccb, false);

    expect(recorded.length, 2);
    expect(recorded[0].$1, 'topic_enabled');
    expect(recorded[0].$2, {'topic': 'ccb'});
    expect(recorded[1].$1, 'topic_disabled');
    expect(recorded[1].$2, {'topic': 'ccb'});
  });

  test('constructor without analytics stays silent (back-compat)', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = EnabledTopicsNotifier();
    await expectLater(notifier.setEnabled(MoneyTopic.ccb, true), completes);
  });
}
