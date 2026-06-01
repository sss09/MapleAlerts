import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';

void main() {
  group('StrokeIcon', () {
    Widget _wrap(Widget child) => MaterialApp(
          theme: mapleThemeData(DesignTheme.fog),
          home: Scaffold(body: child),
        );

    testWidgets('renders known icon without throwing', (tester) async {
      await tester.pumpWidget(_wrap(const StrokeIcon(name: 'bell')));
      await tester.pump();
      expect(find.byType(StrokeIcon), findsOne);
    });

    testWidgets('renders SizedBox for unknown icon name — no throw',
        (tester) async {
      await tester.pumpWidget(_wrap(const StrokeIcon(name: '___nope___')));
      await tester.pump();
      // Widget itself is still in the tree — just renders a SizedBox fallback.
      expect(find.byType(StrokeIcon), findsOne);
    });

    testWidgets('kStrokeIconPaths contains all 24 expected icons',
        (tester) async {
      const expected = [
        'health', 'vehicle', 'gov', 'bill', 'finance', 'home',
        'passport', 'rx', 'seasonal', 'family', 'bell', 'calendar',
        'plus', 'sparkle', 'mic', 'scan', 'user', 'clock', 'check',
        'chevron', 'timeline', 'snooze', 'leaf', 'wallet',
      ];
      for (final name in expected) {
        expect(kStrokeIconPaths.containsKey(name), isTrue,
            reason: 'missing icon: $name');
      }
      expect(kStrokeIconPaths.length, expected.length);
    });

    testWidgets('accepts custom size and color', (tester) async {
      await tester.pumpWidget(
        _wrap(const StrokeIcon(
          name: 'check',
          size: 32,
          color: Color(0xFF5BC6A0),
          strokeWidth: 2.0,
        )),
      );
      await tester.pump();
      expect(find.byType(StrokeIcon), findsOne);
    });
  });
}
