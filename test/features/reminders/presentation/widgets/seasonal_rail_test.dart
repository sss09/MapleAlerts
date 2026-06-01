import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/features/reminders/presentation/widgets/seasonal_rail.dart';

void main() {
  Widget _wrap(Widget child) => MaterialApp(
        theme: mapleThemeData(DesignTheme.fog),
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      );

  group('SeasonalRail', () {
    testWidgets('renders and shows CRA filing card', (tester) async {
      await tester.pumpWidget(_wrap(const SeasonalRail()));
      await tester.pump();

      expect(find.textContaining('CRA filing'), findsOneWidget);
    });

    testWidgets('renders section header with correct labels', (tester) async {
      await tester.pumpWidget(_wrap(const SeasonalRail()));
      await tester.pump();

      expect(find.text('Seasonal — Canada'), findsOneWidget);
      expect(find.text('this month'), findsOneWidget);
    });

    testWidgets('all 4 seasonal cards are present', (tester) async {
      await tester.pumpWidget(_wrap(const SeasonalRail()));
      await tester.pump();

      expect(find.textContaining('CRA filing'), findsOneWidget);
      expect(find.textContaining('Carbon rebate'), findsOneWidget);
      expect(find.textContaining('Daylight saving'), findsOneWidget);
      expect(find.textContaining('Property tax'), findsOneWidget);
    });
  });
}
