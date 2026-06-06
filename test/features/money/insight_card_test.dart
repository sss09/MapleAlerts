import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/features/money/presentation/money_insight.dart';
import 'package:maple_alerts/features/money/presentation/widgets/insight_card.dart';

import '../../helpers/analytics_spy.dart';

// ─── Helper ───────────────────────────────────────────────────────────────────

Widget _wrap(MoneyInsight insight, {AnalyticsSpy? spy}) {
  final effectiveSpy = spy ?? AnalyticsSpy();
  return ProviderScope(
    overrides: [effectiveSpy.override],
    child: MaterialApp(
      theme: mapleThemeData(DesignTheme.fog),
      home: Scaffold(
        body: SingleChildScrollView(
          child: InsightCard(insight: insight),
        ),
      ),
    ),
  );
}

// ─── Shared insight factories ─────────────────────────────────────────────────

MoneyInsight _tfsaInsight({double amount = 10000}) => MoneyInsight(
      id: 'tfsa_room',
      kind: InsightKind.foundMoney,
      severity: InsightSeverity.positive,
      headline: 'You have \$${amount.toInt()} in TFSA room',
      subline: 'Tax-free room available to invest or save.',
      amount: amount,
    );

MoneyInsight _rrspInsight({double amount = 15000}) => MoneyInsight(
      id: 'rrsp_room',
      kind: InsightKind.foundMoney,
      severity: InsightSeverity.positive,
      headline: 'You have \$${amount.toInt()} of RRSP room',
      subline: 'Contributing it could save tax.',
      amount: amount,
    );

MoneyInsight _gicInsight({InsightSeverity severity = InsightSeverity.alert}) =>
    MoneyInsight(
      id: 'gic',
      kind: InsightKind.foundMoney,
      severity: severity,
      headline: 'Your GIC matures soon',
      subline: 'Consider reinvesting.',
    );

MoneyInsight _ccbInsight() => MoneyInsight(
      id: 'ccb',
      kind: InsightKind.foundMoney,
      severity: InsightSeverity.positive,
      headline: r'≈$500/month in Canada Child Benefit',
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('InsightCard — affiliate CTAs', () {
    testWidgets(
        'TFSA card with amount > 5000, expanded → shows EQ Bank HISA CTA',
        (tester) async {
      await tester.pumpWidget(_wrap(_tfsaInsight(amount: 10000)));
      await tester.pump();

      // CTA not visible before expansion
      expect(find.text('Open a TFSA HISA at EQ Bank →'), findsNothing);

      // Tap to expand
      await tester.tap(find.text('You have \$10000 in TFSA room'));
      await tester.pump();

      expect(find.text('Open a TFSA HISA at EQ Bank →'), findsOneWidget);
    });

    testWidgets(
        'TFSA card with amount <= 5000, expanded → no affiliate CTA',
        (tester) async {
      await tester.pumpWidget(_wrap(_tfsaInsight(amount: 4000)));
      await tester.pump();

      await tester.tap(find.text('You have \$4000 in TFSA room'));
      await tester.pump();

      expect(find.text('Open a TFSA HISA at EQ Bank →'), findsNothing);
    });

    testWidgets(
        'RRSP card with amount > 5000, expanded → shows Wealthsimple CTA',
        (tester) async {
      await tester.pumpWidget(_wrap(_rrspInsight(amount: 15000)));
      await tester.pump();

      expect(find.text('Open an RRSP with Wealthsimple →'), findsNothing);

      await tester.tap(find.text('You have \$15000 of RRSP room'));
      await tester.pump();

      expect(find.text('Open an RRSP with Wealthsimple →'), findsOneWidget);
    });

    testWidgets(
        'GIC card with severity alert, expanded → shows both GIC CTAs',
        (tester) async {
      await tester.pumpWidget(
          _wrap(_gicInsight(severity: InsightSeverity.alert)));
      await tester.pump();

      expect(find.text('Compare GIC rates at EQ Bank →'), findsNothing);

      await tester.tap(find.text('Your GIC matures soon'));
      await tester.pump();

      expect(find.text('Compare GIC rates at EQ Bank →'), findsOneWidget);
      expect(find.text('Oaken Financial — top GIC rates →'), findsOneWidget);
    });

    testWidgets(
        'GIC card with severity caution, expanded → shows both GIC CTAs',
        (tester) async {
      await tester.pumpWidget(
          _wrap(_gicInsight(severity: InsightSeverity.caution)));
      await tester.pump();

      await tester.tap(find.text('Your GIC matures soon'));
      await tester.pump();

      expect(find.text('Compare GIC rates at EQ Bank →'), findsOneWidget);
      expect(find.text('Oaken Financial — top GIC rates →'), findsOneWidget);
    });

    testWidgets(
        'RRSP card NOT expanded → no affiliate CTA visible (even with amount > 5000)',
        (tester) async {
      await tester.pumpWidget(_wrap(_rrspInsight(amount: 20000)));
      await tester.pump();

      // Do NOT tap — card stays collapsed
      expect(find.text('Open an RRSP with Wealthsimple →'), findsNothing);
    });

    testWidgets(
        'TFSA card NOT expanded → no affiliate CTA visible',
        (tester) async {
      await tester.pumpWidget(_wrap(_tfsaInsight(amount: 14000)));
      await tester.pump();

      // Do NOT tap — card stays collapsed
      expect(find.text('Open a TFSA HISA at EQ Bank →'), findsNothing);
    });

    testWidgets(
        'CCB insight expanded → no affiliate CTA',
        (tester) async {
      await tester.pumpWidget(_wrap(_ccbInsight()));
      await tester.pump();

      await tester.tap(find.textContaining('Canada Child Benefit'));
      await tester.pump();

      expect(find.text('Open a TFSA HISA at EQ Bank →'), findsNothing);
      expect(find.text('Open an RRSP with Wealthsimple →'), findsNothing);
      expect(find.text('Compare GIC rates at EQ Bank →'), findsNothing);
    });

    testWidgets(
        'tapping affiliate CTA fires affiliate_tapped analytics event',
        (tester) async {
      final spy = AnalyticsSpy();
      await tester.pumpWidget(_wrap(_tfsaInsight(amount: 10000), spy: spy));
      await tester.pump();

      // Expand first
      await tester.tap(find.text('You have \$10000 in TFSA room'));
      await tester.pump();

      // Tap the affiliate link
      await tester.tap(find.text('Open a TFSA HISA at EQ Bank →'));
      await tester.pump();

      expect(spy.fired('affiliate_tapped'), isTrue);
      final props = spy.propsOf('affiliate_tapped')!;
      expect(props['insight_id'], 'tfsa_room');
      expect(props['partner'], 'eq_bank');
      expect(props['from'], 'insight_card');
    });

    testWidgets(
        'card expand/collapse toggle — second tap hides CTA',
        (tester) async {
      await tester.pumpWidget(_wrap(_tfsaInsight(amount: 10000)));
      await tester.pump();

      // Expand
      await tester.tap(find.text('You have \$10000 in TFSA room'));
      await tester.pump();
      expect(find.text('Open a TFSA HISA at EQ Bank →'), findsOneWidget);

      // Collapse
      await tester.tap(find.text('You have \$10000 in TFSA room'));
      await tester.pump();
      expect(find.text('Open a TFSA HISA at EQ Bank →'), findsNothing);
    });
  });
}
