import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/features/money/presentation/widgets/rates_sheet.dart';
import 'package:maple_alerts/providers/data_pack_provider.dart';

import '../../helpers/analytics_spy.dart';

// ─── Test data ────────────────────────────────────────────────────────────────

final _testRates = RatesData.fromJson({
  'asOf': '2026-06-05',
  'disclaimer': 'Rates sourced from public institution websites.',
  'hisa': [
    {
      'id': 'eq_bank',
      'name': 'EQ Bank',
      'rate': 4.75,
      'insurance': 'CDIC',
      'tier': 1,
      'hasAffiliate': true,
    },
    {
      'id': 'wealthsimple',
      'name': 'Wealthsimple Cash',
      'rate': 4.50,
      'insurance': 'CIPF',
      'tier': 1,
      'hasAffiliate': true,
    },
    {
      'id': 'neo',
      'name': 'Neo Financial',
      'rate': 4.25,
      'insurance': 'CDIC',
      'tier': 1,
      'hasAffiliate': false,
    },
    {
      'id': 'simplii',
      'name': 'Simplii Financial',
      'rate': 4.10,
      'insurance': 'CDIC',
      'tier': 1,
      'hasAffiliate': false,
    },
    {
      'id': 'tangerine',
      'name': 'Tangerine',
      'rate': 3.80,
      'insurance': 'CDIC',
      'tier': 2,
      'hasAffiliate': true,
    },
    {
      'id': 'big5',
      'name': 'Big Five Banks',
      'rate': 0.05,
      'insurance': 'CDIC',
      'tier': 3,
      'hasAffiliate': false,
    },
  ],
  'gic_1yr': [
    {
      'id': 'eq_bank',
      'name': 'EQ Bank GIC',
      'rate': 4.90,
      'insurance': 'CDIC',
      'tier': 1,
      'hasAffiliate': true,
    },
    {
      'id': 'oaken',
      'name': 'Oaken Financial',
      'rate': 4.85,
      'insurance': 'CDIC',
      'tier': 1,
      'hasAffiliate': false,
      'note': 'Non-redeemable',
    },
  ],
});

// ─── Test double ──────────────────────────────────────────────────────────────

class _MockPack extends EmbeddedDataPack {
  _MockPack(this._rates);
  final RatesData _rates;

  @override
  RatesData get rates => _rates;
}

// ─── Helper ───────────────────────────────────────────────────────────────────

/// Pump [RatesSheetContent] directly as a regular widget for faster tests.
Widget _wrapDirect({RatesData? rates, AnalyticsSpy? spy}) {
  final effectiveRates = rates ?? _testRates;
  final pack = _MockPack(effectiveRates);
  final effectiveSpy = spy ?? AnalyticsSpy();
  return ProviderScope(
    overrides: [
      dataPackProvider.overrideWithValue(pack),
      effectiveSpy.override,
    ],
    child: MaterialApp(
      theme: mapleThemeData(DesignTheme.fog),
      home: Scaffold(
        body: RatesSheetContent(rates: effectiveRates),
      ),
    ),
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('urlForInstitution', () {
    test('returns EQ Bank HISA url for eq_bank HISA', () {
      expect(urlForInstitution('eq_bank'), contains('eqbank'));
    });

    test('returns EQ Bank GIC url for eq_bank GIC', () {
      expect(urlForInstitution('eq_bank', isGic: true), contains('gic'));
    });

    test('returns ratehub fallback for unknown HISA institution', () {
      expect(urlForInstitution('unknown_bank'), contains('ratehub'));
    });

    test('returns ratehub fallback for unknown GIC institution', () {
      expect(urlForInstitution('unknown_bank', isGic: true), contains('ratehub'));
    });

    test('returns wealthsimple for wealthsimple', () {
      expect(urlForInstitution('wealthsimple'), contains('wealthsimple'));
    });

    test('returns neo for neo', () {
      expect(urlForInstitution('neo'), contains('neo'));
    });

    test('returns tangerine for tangerine GIC', () {
      expect(urlForInstitution('tangerine', isGic: true), contains('tangerine'));
    });
  });

  group('RatesSheetContent', () {
    testWidgets('shows High-Interest Savings section header', (tester) async {
      await tester.pumpWidget(_wrapDirect());
      await tester.pump();

      expect(find.text('High-Interest Savings'), findsOneWidget);
    });

    testWidgets('shows 1-Year GIC Rates section header', (tester) async {
      await tester.pumpWidget(_wrapDirect());
      await tester.pump();

      expect(find.text('1-Year GIC Rates'), findsOneWidget);
    });

    testWidgets('shows EQ Bank and 4.75% in HISA section', (tester) async {
      await tester.pumpWidget(_wrapDirect());
      await tester.pump();

      expect(find.text('EQ Bank'), findsWidgets);
      expect(find.text('4.75%'), findsOneWidget);
    });

    testWidgets('shows Open account → for eq_bank (hasAffiliate: true)',
        (tester) async {
      await tester.pumpWidget(_wrapDirect());
      await tester.pump();

      // EQ Bank has hasAffiliate: true — should show "Open account →"
      expect(find.text('Open account →'), findsWidgets);
    });

    testWidgets('shows Compare at Ratehub → for non-affiliate institution',
        (tester) async {
      await tester.pumpWidget(_wrapDirect());
      await tester.pump();

      // neo and simplii have hasAffiliate: false
      expect(find.text('Compare at Ratehub →'), findsWidgets);
    });

    testWidgets('shows disclaimer text', (tester) async {
      await tester.pumpWidget(_wrapDirect());
      await tester.pump();

      expect(
        find.textContaining('Rates sourced from public institution websites.'),
        findsOneWidget,
      );
    });

    testWidgets('See more institutions button toggles tier-2 visibility',
        (tester) async {
      await tester.pumpWidget(_wrapDirect());
      await tester.pump();

      // Tangerine is tier-2 and should NOT be visible initially
      expect(find.text('Tangerine'), findsNothing);

      // The toggle button should be present
      expect(find.text('See more institutions'), findsOneWidget);

      // Tap it
      await tester.tap(find.text('See more institutions'));
      await tester.pump();

      // Now Tangerine should be visible
      expect(find.text('Tangerine'), findsOneWidget);

      // Button text should change
      expect(find.text('Show fewer institutions'), findsOneWidget);

      // Tap again to hide
      await tester.tap(find.text('Show fewer institutions'));
      await tester.pump();

      expect(find.text('Tangerine'), findsNothing);
      expect(find.text('See more institutions'), findsOneWidget);
    });

    testWidgets('shows footer disclaimer text', (tester) async {
      await tester.pumpWidget(_wrapDirect());
      await tester.pump();

      expect(
        find.textContaining('Rates update weekly'),
        findsOneWidget,
      );
    });

    testWidgets('shows big bank baseline with For comparison only label',
        (tester) async {
      await tester.pumpWidget(_wrapDirect());
      await tester.pump();

      expect(find.text('For comparison only'), findsOneWidget);
    });

    testWidgets('empty rates shows fallback for GIC section', (tester) async {
      await tester.pumpWidget(_wrapDirect(rates: RatesData.empty));
      await tester.pump();

      expect(
        find.textContaining('GIC rates unavailable'),
        findsOneWidget,
      );
    });

    testWidgets('CDIC insurance badge renders green chip', (tester) async {
      await tester.pumpWidget(_wrapDirect());
      await tester.pump();

      // CDIC badge should appear for EQ Bank
      expect(find.text('CDIC'), findsWidgets);
    });

    testWidgets('CIPF insurance badge renders for Wealthsimple', (tester) async {
      await tester.pumpWidget(_wrapDirect());
      await tester.pump();

      expect(find.text('CIPF'), findsOneWidget);
    });

    testWidgets('note text shown for Oaken (non-redeemable)', (tester) async {
      await tester.pumpWidget(_wrapDirect());
      await tester.pump();

      expect(find.textContaining('Non-redeemable'), findsOneWidget);
    });
  });
}
