import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/features/reminders/presentation/reminder_view.dart';
import 'package:maple_alerts/features/reminders/presentation/widgets/reminder_card.dart';

const _v = ReminderView(
  id: 'hydro',
  title: 'Hydro bill due',
  description: 'Toronto Hydro auto-pay is off this cycle.',
  categoryId: 'bills',
  status: 'urgent',
  section: 'Today',
  whenLabel: 'In 2 days',
  progress: 0.9,
  amount: '\$142.60',
);

Widget _host(Widget child) => MaterialApp(
      theme: mapleThemeData(DesignTheme.fog),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('renders title, amount, when, category', (t) async {
    await t.pumpWidget(_host(const ReminderCard(item: _v)));
    await t.pump();
    expect(find.text('Hydro bill due'), findsOneWidget);
    expect(find.text('\$142.60'), findsOneWidget);
    expect(find.text('In 2 days'), findsOneWidget);
    expect(find.text('Bills'), findsOneWidget);
  });
  testWidgets('tap expands to reveal Mark done', (t) async {
    var done = false;
    await t.pumpWidget(_host(ReminderCard(item: _v, onDone: () => done = true)));
    await t.pump();
    expect(find.text('Mark done'), findsNothing);
    await t.tap(find.text('Hydro bill due'));
    await t.pumpAndSettle();
    expect(find.text('Mark done'), findsOneWidget);
    await t.tap(find.text('Mark done'));
    await t.pump();
    expect(done, isTrue);
  });
}
