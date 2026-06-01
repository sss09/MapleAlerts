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

const _vFinance = ReminderView(
  id: 'tfsa',
  title: 'TFSA contribution room',
  description: 'Unused contribution room from last year.',
  categoryId: 'finance',
  status: 'upcoming',
  section: 'This week',
  whenLabel: 'In 7 days',
  progress: 0.3,
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

  testWidgets('bills card expanded — no affiliate CTA', (t) async {
    await t.pumpWidget(_host(const ReminderCard(item: _v)));
    await t.pump();
    await t.tap(find.text('Hydro bill due'));
    await t.pumpAndSettle();
    expect(find.text('Compare savings & GIC rates'), findsNothing);
    expect(find.text('Compare mortgage rates'), findsNothing);
    expect(find.text('PARTNER'), findsNothing);
  });

  testWidgets('finance card expanded — shows affiliate CTA', (t) async {
    await t.pumpWidget(_host(const ReminderCard(item: _vFinance)));
    await t.pump();
    // CTA not visible before expand
    expect(find.text('Compare savings & GIC rates'), findsNothing);
    await t.tap(find.text('TFSA contribution room'));
    await t.pumpAndSettle();
    expect(find.text('Compare savings & GIC rates'), findsOneWidget);
    expect(find.text('PARTNER'), findsOneWidget);
  });
}
