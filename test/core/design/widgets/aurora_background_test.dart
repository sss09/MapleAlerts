import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/core/design/widgets/aurora_background.dart';

void main() {
  Widget _wrap(Widget child) => MaterialApp(
        theme: mapleThemeData(DesignTheme.fog),
        home: Scaffold(body: child),
      );

  group('AuroraBackground', () {
    testWidgets('static (motion:false) renders and child is visible',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 300,
            height: 600,
            child: Stack(
              children: [
                AuroraBackground(motion: false),
                Text('hi'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('hi'), findsOneWidget);
      expect(find.byType(AuroraBackground), findsOneWidget);
    });

    testWidgets('motion:true pumps 50 ms without throwing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 300,
            height: 600,
            child: Stack(
              children: [
                AuroraBackground(motion: true),
                Text('animated'),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('animated'), findsOneWidget);
    });

    testWidgets('explicit aurora override renders without throw',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 300,
            height: 600,
            child: AuroraBackground(
              aurora: DesignTheme.fog.aurora,
              motion: false,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AuroraBackground), findsOneWidget);
    });
  });
}
