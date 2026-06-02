import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/features/money/presentation/widgets/explainer_sheet.dart';
import 'package:maple_alerts/features/money/presentation/widgets/learn_section.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: mapleThemeData(DesignTheme.fog),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('Learn section renders the explainer rail', (tester) async {
    await tester.pumpWidget(_wrap(const LearnSection()));
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
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('TFSA, explained'), findsOneWidget);
    expect(find.textContaining('not financial advice'), findsOneWidget);
  });
}
