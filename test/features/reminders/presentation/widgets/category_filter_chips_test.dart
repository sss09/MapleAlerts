import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/features/reminders/presentation/widgets/category_filter_chips.dart';

void main() {
  Widget _wrap(Widget child) => MaterialApp(
        theme: mapleThemeData(DesignTheme.fog),
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      );

  group('CategoryFilterChips + StatusLegend', () {
    testWidgets('renders All chip and Finance chip', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              CategoryFilterChips(active: 'All', onPick: (_) {}),
              const StatusLegend(),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Finance'), findsOneWidget);
    });

    testWidgets('renders Upcoming in status legend', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              CategoryFilterChips(active: 'All', onPick: (_) {}),
              const StatusLegend(),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Upcoming'), findsOneWidget);
    });

    testWidgets('all 8 category chips are present', (tester) async {
      await tester.pumpWidget(
        _wrap(CategoryFilterChips(active: 'All', onPick: (_) {})),
      );
      await tester.pump();

      for (final label in [
        'Government',
        'Bills',
        'Vehicle',
        'Health',
        'Finance',
        'Home',
        'Family',
        'Seasonal',
      ]) {
        expect(find.text(label), findsOneWidget, reason: '$label chip missing');
      }
    });

    testWidgets('onPick callback fires with correct id', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _wrap(CategoryFilterChips(active: 'All', onPick: (id) => picked = id)),
      );
      await tester.pump();

      await tester.tap(find.text('Finance'));
      expect(picked, 'finance');
    });

    testWidgets('all 5 legend status labels are present', (tester) async {
      await tester.pumpWidget(_wrap(const StatusLegend()));
      await tester.pump();

      // Labels come from MapleSemantics — verify all five
      expect(find.text('Urgent'), findsOneWidget);
      expect(find.text('Needs attention'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Good to know'), findsOneWidget);
      expect(find.text('Planning ahead'), findsOneWidget);
    });
  });
}
