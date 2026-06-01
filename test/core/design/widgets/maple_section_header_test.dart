import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/core/design/widgets/maple_section_header.dart';

void main() {
  Widget _wrap(Widget child) => MaterialApp(
        theme: mapleThemeData(DesignTheme.fog),
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      );

  group('MapleSectionHeader', () {
    testWidgets('renders label only', (tester) async {
      await tester.pumpWidget(
        _wrap(const MapleSectionHeader(label: 'Today')),
      );
      await tester.pump();

      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('renders label + count', (tester) async {
      await tester.pumpWidget(
        _wrap(const MapleSectionHeader(label: 'Today', count: '2 items')),
      );
      await tester.pump();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);
    });

    testWidgets('omitting count shows no extra text', (tester) async {
      await tester.pumpWidget(
        _wrap(const MapleSectionHeader(label: 'This Week')),
      );
      await tester.pump();

      expect(find.text('This Week'), findsOneWidget);
      // Only one text widget (the label); count absent → no second widget
      expect(find.byType(Text), findsOneWidget);
    });
  });
}
