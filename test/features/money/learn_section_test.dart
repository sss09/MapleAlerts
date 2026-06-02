import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/features/money/presentation/widgets/explainer_sheet.dart';
import 'package:maple_alerts/features/money/presentation/widgets/learn_section.dart';
import '../../helpers/analytics_spy.dart';

Widget _wrap(Widget child, {AnalyticsSpy? spy}) => ProviderScope(
      overrides: [
        if (spy != null) spy.override,
      ],
      child: MaterialApp(
        theme: mapleThemeData(DesignTheme.fog),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  testWidgets('Learn section renders the explainer rail', (tester) async {
    await tester.pumpWidget(_wrap(const LearnSection(), spy: AnalyticsSpy()));
    await tester.pump();
    expect(find.text('Learn the rules'), findsOneWidget);
    expect(find.text('TFSA, explained'), findsOneWidget);
  });

  testWidgets('explainer sheet shows points and the not-advice footer',
      (tester) async {
    final tfsa = explainerForInsightId('tfsa_room')!;
    await tester.pumpWidget(_wrap(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showExplainerSheet(context, tfsa),
          child: const Text('open'),
        ),
      ),
      spy: AnalyticsSpy(),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('TFSA, explained'), findsOneWidget);
    expect(find.textContaining('not financial advice'), findsOneWidget);
  });

  testWidgets('tapping an explainer chip fires explainer_opened with the explainer id',
      (tester) async {
    final spy = AnalyticsSpy();
    await tester.pumpWidget(_wrap(const LearnSection(), spy: spy));
    await tester.pump();

    // Ensure the first chip is visible before tapping (the rail may clip).
    await tester.ensureVisible(find.text(kExplainers.first.title));
    await tester.tap(find.text(kExplainers.first.title), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(spy.fired('explainer_opened'), isTrue);
    expect(spy.propsOf('explainer_opened'), {'id': kExplainers.first.id});
  });
}
