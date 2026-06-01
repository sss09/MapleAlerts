import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';

void main() {
  group('MapleSurface', () {
    Widget _wrap(Widget child) => MaterialApp(
          theme: mapleThemeData(DesignTheme.fog),
          home: Scaffold(body: child),
        );

    testWidgets('default (minimal) surface renders child', (tester) async {
      await tester.pumpWidget(
        _wrap(const MapleSurface(child: Text('x'))),
      );
      await tester.pump();
      expect(find.byType(MapleSurface), findsOne);
      expect(find.text('x'), findsOne);
    });

    testWidgets('active + status surface renders child', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MapleSurface(
            status: 'urgent',
            active: true,
            child: Text('y'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(MapleSurface), findsOne);
      expect(find.text('y'), findsOne);
    });

    testWidgets('bordered level renders without throw', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MapleSurface(
            level: MapleSurfaceLevel.bordered,
            child: Text('bordered'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(MapleSurface), findsOne);
      expect(find.text('bordered'), findsOne);
    });

    testWidgets('solid level renders without throw', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MapleSurface(
            level: MapleSurfaceLevel.solid,
            child: Text('solid'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(MapleSurface), findsOne);
      expect(find.text('solid'), findsOne);
    });

    testWidgets('passive mode renders without throw', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MapleSurface(
            passive: true,
            child: Text('passive'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(MapleSurface), findsOne);
      expect(find.text('passive'), findsOne);
    });

    testWidgets('active + upcoming status renders child', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MapleSurface(
            status: 'upcoming',
            active: true,
            level: MapleSurfaceLevel.bordered,
            child: Text('z'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(MapleSurface), findsOne);
      expect(find.text('z'), findsOne);
    });
  });
}
