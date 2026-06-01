import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/core/design/widgets/progress_ring.dart';

void main() {
  group('ProgressRing', () {
    Widget _wrap(Widget child) => MaterialApp(
          theme: mapleThemeData(DesignTheme.fog),
          home: Scaffold(body: child),
        );

    testWidgets('renders with child text — builds and shows text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProgressRing(
            progress: 0.5,
            color: Color(0xFF5BC6A0),
            child: Text('2'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ProgressRing), findsOne);
      expect(find.text('2'), findsOne);
    });

    testWidgets('renders without child — no throw', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProgressRing(
            progress: 0.75,
            color: Color(0xFFE4B469),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ProgressRing), findsOne);
    });

    testWidgets('clamps progress 0 — no throw', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProgressRing(progress: 0, color: Color(0xFF5BC6A0)),
        ),
      );
      await tester.pump();
      expect(find.byType(ProgressRing), findsOne);
    });

    testWidgets('clamps progress 1 — no throw', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProgressRing(progress: 1, color: Color(0xFF5BC6A0)),
        ),
      );
      await tester.pump();
      expect(find.byType(ProgressRing), findsOne);
    });

    testWidgets('glow=false — no throw', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProgressRing(
            progress: 0.6,
            color: Color(0xFF71C3D6),
            glow: false,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ProgressRing), findsOne);
    });
  });
}
