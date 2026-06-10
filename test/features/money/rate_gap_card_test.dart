import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/features/money/presentation/widgets/rate_gap_card.dart';
import 'package:maple_alerts/providers/data_pack_provider.dart';
import 'package:maple_alerts/providers/money_profile_provider.dart';
import 'package:maple_alerts/services/money_profile_store.dart';
import '../../helpers/analytics_spy.dart';

// ─── Test doubles ─────────────────────────────────────────────────────────────

final _hisaRates = RatesData.fromJson({
  'asOf': '2026-06-05',
  'disclaimer': 'Verify.',
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
      'id': 'big5',
      'name': 'Big Five',
      'rate': 0.05,
      'insurance': 'CDIC',
      'tier': 3,
      'hasAffiliate': false,
    },
  ],
  'gic_1yr': [],
});

/// DataPack stub that returns the given [RatesData].
class _MockPack extends EmbeddedDataPack {
  _MockPack(this._rates);
  final RatesData _rates;
  @override
  RatesData get rates => _rates;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Widget _wrap({
  MoneyProfile profile = MoneyProfile.empty,
  RatesData? rates,
  AnalyticsSpy? spy,
}) {
  final pack = _MockPack(rates ?? RatesData.empty);
  // Always override analytics so tests that render State B don't hit Aptabase.
  final effectiveSpy = spy ?? AnalyticsSpy();
  return ProviderScope(
    overrides: [
      moneyProfileProvider.overrideWith(
        (ref) => MoneyProfileNotifier(store: _NoOpStore(profile)),
      ),
      dataPackProvider.overrideWithValue(pack),
      effectiveSpy.override,
    ],
    child: MaterialApp(
      theme: mapleThemeData(DesignTheme.fog),
      home: const Scaffold(
        body: SingleChildScrollView(child: RateGapCard()),
      ),
    ),
  );
}

/// A MoneyProfileStore that returns a fixed profile and discards saves.
class _NoOpStore extends MoneyProfileStore {
  _NoOpStore(this._profile);
  final MoneyProfile _profile;

  @override
  Future<MoneyProfile> load() async => _profile;

  @override
  Future<void> save(MoneyProfile profile) async {}
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RateGapCard', () {
    testWidgets('State A — no balance: shows capture prompt', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.text('Are you losing money at your bank?'), findsOneWidget);
      expect(
        find.textContaining('Add your savings balance'),
        findsOneWidget,
      );
      expect(find.text('Calculate'), findsOneWidget);
    });

    testWidgets('State B — balance set + rates: shows annual gap with /yr',
        (tester) async {
      const profile = MoneyProfile(savingsBalance: 10000);
      await tester.pumpWidget(_wrap(profile: profile, rates: _hisaRates));
      await tester.pump();

      // annualGap = 10000 * (4.75 - 0.05) / 100 = 470
      expect(find.textContaining('/yr'), findsOneWidget);
      // The RATE GAP label is always uppercase in the card.
      expect(find.text('RATE GAP'), findsOneWidget);
      // Institution name
      expect(find.textContaining('EQ Bank'), findsOneWidget);
      // Insurance chip
      expect(find.textContaining('CDIC insured'), findsOneWidget);
      // CTAs
      expect(find.text('See best rates →'), findsOneWidget);
      expect(find.text('Update balance'), findsOneWidget);
    });

    testWidgets(
        'State C — balance set but empty rates: collapses silently, no crash',
        (tester) async {
      const profile = MoneyProfile(savingsBalance: 5000);
      await tester.pumpWidget(
        _wrap(profile: profile, rates: RatesData.empty),
      );
      await tester.pump();

      // No rates available → card collapses to SizedBox.shrink() with no text.
      expect(find.textContaining('/yr'), findsNothing);
      expect(find.textContaining('See best rates'), findsNothing);
    });

    testWidgets('State A calculate button transitions to State B on valid input',
        (tester) async {
      await tester.pumpWidget(_wrap(rates: _hisaRates, spy: AnalyticsSpy()));
      await tester.pump();

      // Type a balance
      await tester.enterText(find.byType(TextField), '20000');
      await tester.pump();

      await tester.tap(find.text('Calculate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // After setting, State B should appear.
      expect(find.textContaining('/yr'), findsOneWidget);
    });

    testWidgets('State A shows validation error for non-numeric input',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      await tester.tap(find.text('Calculate'));
      await tester.pump();

      expect(find.textContaining('Enter a positive dollar amount'),
          findsOneWidget);
    });

    testWidgets(
        'State B Update balance link returns to State A',
        (tester) async {
      const profile = MoneyProfile(savingsBalance: 10000);
      await tester.pumpWidget(_wrap(profile: profile, rates: _hisaRates));
      await tester.pump();

      expect(find.textContaining('/yr'), findsOneWidget);

      await tester.tap(find.text('Update balance'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Are you losing money at your bank?'), findsOneWidget);
    });
  });
}
