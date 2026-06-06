import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/engine/canadian_data_engine/data/data_pack.dart';
import 'package:maple_alerts/features/money/presentation/widgets/boc_rate_card.dart';
import 'package:maple_alerts/providers/boc_rate_provider.dart';
import 'package:maple_alerts/providers/data_pack_provider.dart';
import 'package:maple_alerts/services/boc_rate_service.dart';

Widget _wrap(BocRate? rate) => ProviderScope(
      overrides: [
        bocRateProvider.overrideWith((ref) => rate),
        // EmbeddedDataPack.rates already returns RatesData.empty — the CTA just needs to not crash.
        dataPackProvider.overrideWithValue(const EmbeddedDataPack()),
      ],
      child: MaterialApp(
        theme: mapleThemeData(DesignTheme.fog),
        home: const Scaffold(body: SingleChildScrollView(child: BocRateCard())),
      ),
    );

void main() {
  testWidgets('hides when no rate is available', (tester) async {
    await tester.pumpWidget(_wrap(null));
    await tester.pumpAndSettle();
    expect(find.text('Rates'), findsNothing);
  });

  testWidgets('renders policy rate, typical prime, and as-of date', (tester) async {
    await tester.pumpWidget(_wrap(BocRate(
      policyRate: 2.75,
      asOf: DateTime(2026, 4, 16),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Rates'), findsOneWidget);
    expect(find.text('2.75%'), findsOneWidget);
    expect(find.textContaining('Typical prime ≈ 4.95%'), findsOneWidget);
    expect(find.textContaining('As of Apr 16, 2026'), findsOneWidget);
  });

  testWidgets('shows an offline hint for a cached rate', (tester) async {
    await tester.pumpWidget(_wrap(BocRate(
      policyRate: 2.75,
      asOf: DateTime(2026, 4, 16),
      fromCache: true,
    )));
    await tester.pumpAndSettle();
    expect(find.textContaining('Offline'), findsOneWidget);
  });

  testWidgets('elevated rate (4.75%) shows elevated context', (tester) async {
    await tester.pumpWidget(_wrap(BocRate(
      policyRate: 4.75,
      asOf: DateTime(2026, 4, 16),
    )));
    await tester.pumpAndSettle();
    expect(find.textContaining('elevated'), findsOneWidget);
  });

  testWidgets('moderate rate (3.0%) shows moderate context', (tester) async {
    await tester.pumpWidget(_wrap(BocRate(
      policyRate: 3.0,
      asOf: DateTime(2026, 4, 16),
    )));
    await tester.pumpAndSettle();
    expect(find.textContaining('Moderate'), findsOneWidget);
  });

  testWidgets('low rate (2.0%) shows low context', (tester) async {
    await tester.pumpWidget(_wrap(BocRate(
      policyRate: 2.0,
      asOf: DateTime(2026, 4, 16),
    )));
    await tester.pumpAndSettle();
    expect(find.textContaining('low'), findsOneWidget);
  });

  testWidgets('CTA row is visible', (tester) async {
    await tester.pumpWidget(_wrap(BocRate(
      policyRate: 4.75,
      asOf: DateTime(2026, 4, 16),
    )));
    await tester.pumpAndSettle();
    expect(find.textContaining('See best HISA'), findsOneWidget);
  });
}
