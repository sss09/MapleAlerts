import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/features/reminders/presentation/widgets/day_handled_hero.dart';

void main() {
  Widget _wrap(Widget child) => MaterialApp(
        theme: mapleThemeData(DesignTheme.fog),
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      );

  group('DayHandledHero', () {
    testWidgets('renders headline and body copy', (tester) async {
      await tester.pumpWidget(
        _wrap(const DayHandledHero(needs: 2, total: 8)),
      );
      await tester.pump();

      expect(find.text('YOUR DAY, HANDLED'), findsOneWidget);
      expect(find.textContaining('need you this week'), findsOneWidget);
    });

    testWidgets('needs count appears inside ring', (tester) async {
      await tester.pumpWidget(
        _wrap(const DayHandledHero(needs: 3, total: 10)),
      );
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('to do'), findsOneWidget);
    });

    testWidgets('zero total does not throw (progress = 1)', (tester) async {
      await tester.pumpWidget(
        _wrap(const DayHandledHero(needs: 0, total: 0)),
      );
      await tester.pump();

      expect(find.text('YOUR DAY, HANDLED'), findsOneWidget);
    });
  });
}
