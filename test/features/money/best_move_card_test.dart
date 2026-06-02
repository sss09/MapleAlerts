import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/features/money/presentation/widgets/best_move_card.dart';
import 'package:maple_alerts/providers/best_move_provider.dart';
import '../../helpers/analytics_spy.dart';

Widget _wrap(BestMove? move, {AnalyticsSpy? spy}) => ProviderScope(
      overrides: [
        bestMoveProvider.overrideWithValue(move),
        if (spy != null) spy.override,
      ],
      child: MaterialApp(
        theme: mapleThemeData(DesignTheme.fog),
        home: const Scaffold(body: SingleChildScrollView(child: BestMoveCard())),
      ),
    );

void main() {
  testWidgets('hides when there is no best move', (tester) async {
    await tester.pumpWidget(_wrap(null));
    await tester.pump();
    expect(find.text('YOUR BEST MOVE'), findsNothing);
  });

  testWidgets('renders the recommendation, value, and a how-we-decided toggle',
      (tester) async {
    final spy = AnalyticsSpy();
    await tester.pumpWidget(_wrap(const BestMove(
      kind: BestMoveKind.opportunity,
      title: 'Contribute to your RRSP',
      detail: 'At your ~37% marginal rate, an RRSP contribution saves more tax.',
      dollarValue: 7432,
      targetInsightId: 'rrsp_room',
      sources: [FigureSource('Why RRSP over TFSA', 'Marginal rate ~37%', 'rule')],
    ), spy: spy));
    await tester.pump();

    expect(find.text('YOUR BEST MOVE'), findsOneWidget);
    expect(find.text('Contribute to your RRSP'), findsOneWidget);
    expect(find.text(r'$7,432'), findsOneWidget);

    expect(find.textContaining('Marginal rate ~37%'), findsNothing);
    await tester.tap(find.text('How we decided'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Marginal rate ~37%'), findsOneWidget);
    expect(find.textContaining('not financial advice'), findsOneWidget);

    final shown = spy.propsOf('best_move_shown');
    expect(shown, isNotNull);
    expect(shown!.keys, containsAll(['kind', 'target']));
  });
}
