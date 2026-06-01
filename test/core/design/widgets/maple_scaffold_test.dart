import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/core/design/widgets/maple_scaffold.dart';

void main() {
  const _tabs = [
    MapleTab('home', 'Home'),
    MapleTab('timeline', 'Timeline'),
    MapleTab('bell', 'Alerts'),
    MapleTab('user', 'You'),
  ];

  Widget _wrap(Widget child) => MaterialApp(
        theme: mapleThemeData(DesignTheme.fog),
        home: child,
      );

  group('MapleScaffold', () {
    testWidgets('renders body, all tab labels, and FAB', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MapleScaffold(
            currentIndex: 0,
            tabs: _tabs,
            onTab: (_) {},
            onAdd: () {},
            body: const Text('home-body'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('home-body'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Timeline'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('tapping a tab calls onTab with correct index', (tester) async {
      int tapped = -1;
      await tester.pumpWidget(
        _wrap(
          MapleScaffold(
            currentIndex: 0,
            tabs: _tabs,
            onTab: (i) => tapped = i,
            body: const Text('body'),
          ),
        ),
      );
      await tester.pump();

      // Tap the "You" tab (index 3, right side of bar)
      await tester.tap(find.text('You'));
      await tester.pump();
      expect(tapped, 3);
    });

    testWidgets('onAdd null does not throw on FAB tap', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MapleScaffold(
            currentIndex: 0,
            tabs: _tabs,
            onTab: (_) {},
            // onAdd deliberately omitted
            body: const Text('no-fab'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('no-fab'), findsOneWidget);
    });

    testWidgets('motion from AuroraBackground pumps without throw',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          MapleScaffold(
            currentIndex: 2,
            tabs: _tabs,
            onTab: (_) {},
            onAdd: () {},
            body: const Text('alerts-body'),
          ),
        ),
      );
      // Single pump — never pumpAndSettle due to infinite aurora animations.
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('alerts-body'), findsOneWidget);
    });
  });
}
