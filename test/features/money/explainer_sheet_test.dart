import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/features/money/presentation/money_topic.dart';
import 'package:maple_alerts/features/money/presentation/widgets/explainer_sheet.dart';
import 'package:maple_alerts/providers/enabled_topics_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/analytics_spy.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget wrap(ProviderContainer container, Explainer explainer) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: mapleThemeData(DesignTheme.fog),
        home: Scaffold(body: ExplainerSheet(explainer: explainer)),
      ),
    );
  }

  testWidgets('account explainer offers Track CTA for an untracked topic',
      (t) async {
    final spy = AnalyticsSpy();
    final container = ProviderContainer(overrides: [spy.override]);
    addTearDown(container.dispose);

    // FHSA is NOT in the default-enabled set -> the CTA must show.
    final fhsa = explainerForInsightId(MoneyTopic.fhsa.insightId)!;
    await t.pumpWidget(wrap(container, fhsa));
    await t.pump();

    final cta = find.textContaining('Track FHSA');
    await t.ensureVisible(cta);
    expect(cta, findsOneWidget);

    await t.tap(cta, warnIfMissed: false);
    await t.pump();

    expect(
        container.read(enabledTopicsProvider).contains(MoneyTopic.fhsa), isTrue);
    expect(spy.propsOf('topic_enabled'), {'topic': 'fhsa'});
  });

  testWidgets('already-tracked topic and jargon explainers show no CTA',
      (t) async {
    final spy = AnalyticsSpy();
    final container = ProviderContainer(overrides: [spy.override]);
    addTearDown(container.dispose);

    // TFSA is default-enabled -> no CTA.
    final tfsa = explainerForInsightId(MoneyTopic.tfsa.insightId)!;
    await t.pumpWidget(wrap(container, tfsa));
    await t.pump();
    expect(find.textContaining('Track TFSA'), findsNothing);

    // A jargon explainer has no topic -> no CTA.
    final jargon = kExplainers.firstWhere(
        (e) => MoneyTopic.fromInsightId(e.topicInsightId ?? '') == null);
    await t.pumpWidget(wrap(container, jargon));
    await t.pump();
    expect(find.textContaining('Track '), findsNothing);
  });
}
