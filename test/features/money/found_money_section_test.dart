import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/features/money/presentation/money_insight.dart';
import 'package:maple_alerts/features/money/presentation/widgets/found_money_section.dart';
import 'package:maple_alerts/providers/money_insights_provider.dart';

Widget _wrap(List<MoneyInsight> insights) => ProviderScope(
      overrides: [
        moneyInsightsProvider.overrideWithValue(insights),
      ],
      child: MaterialApp(
        theme: mapleThemeData(DesignTheme.fog),
        home: const Scaffold(
          body: SingleChildScrollView(child: FoundMoneySection()),
        ),
      ),
    );

void main() {
  testWidgets('renders nothing when there are no insights', (tester) async {
    await tester.pumpWidget(_wrap(const []));
    await tester.pump();
    expect(find.text('Found money'), findsNothing);
  });

  testWidgets('renders the setup prompt with its CTA', (tester) async {
    await tester.pumpWidget(_wrap(const [
      MoneyInsight(
        id: 'tfsa_room',
        kind: InsightKind.setup,
        severity: InsightSeverity.info,
        headline: 'Find your TFSA room',
        cta: InsightCta('Set up', InsightAction.editTfsaProfile),
      ),
    ]));
    await tester.pump();

    expect(find.text('Found money'), findsOneWidget);
    expect(find.text('Find your TFSA room'), findsOneWidget);
    expect(find.text('Set up'), findsOneWidget);
  });

  testWidgets('found-money insight reveals its sources when expanded',
      (tester) async {
    await tester.pumpWidget(_wrap(const [
      MoneyInsight(
        id: 'tfsa_room',
        kind: InsightKind.foundMoney,
        severity: InsightSeverity.positive,
        headline: r'You have $14,000 in TFSA room',
        subline: 'Tax-free room available to invest or save.',
        amount: 14000,
        sources: [FigureSource('2026 TFSA limit', r'$7,000', 'CRA')],
      ),
    ]));
    await tester.pump();

    expect(find.text(r'You have $14,000 in TFSA room'), findsOneWidget);
    expect(find.text('FOUND MONEY'), findsOneWidget);

    // Sources are collapsed until tapped.
    expect(find.text('2026 TFSA limit'), findsNothing);
    await tester.tap(find.text('How we got this'));
    await tester.pumpAndSettle();
    expect(find.text('2026 TFSA limit'), findsOneWidget);
    expect(find.textContaining('not financial advice'), findsOneWidget);
  });

  testWidgets('renders TFSA and RRSP cards together from the combined list',
      (tester) async {
    await tester.pumpWidget(_wrap(const [
      MoneyInsight(
        id: 'tfsa_room',
        kind: InsightKind.foundMoney,
        severity: InsightSeverity.positive,
        headline: r'You have $14,000 in TFSA room',
      ),
      MoneyInsight(
        id: 'rrsp_room',
        kind: InsightKind.foundMoney,
        severity: InsightSeverity.positive,
        headline: r'You have $30,000 of RRSP room',
        subline: r'Contributing it could save ≈$8,895 at your ~30% marginal rate.',
      ),
    ]));
    await tester.pump();

    expect(find.text(r'You have $14,000 in TFSA room'), findsOneWidget);
    expect(find.text(r'You have $30,000 of RRSP room'), findsOneWidget);
    expect(find.text('FOUND MONEY'), findsNWidgets(2));
  });
}
