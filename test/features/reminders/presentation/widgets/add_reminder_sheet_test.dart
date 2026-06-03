import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/design/design_theme.dart';
import 'package:maple_alerts/core/design/maple_theme.dart';
import 'package:maple_alerts/models/alert.dart';
import 'package:maple_alerts/providers/alerts_provider.dart';
import 'package:maple_alerts/features/reminders/presentation/widgets/add_reminder_sheet.dart';
import '../../../../helpers/analytics_spy.dart';

void main() {
  /// Helper that builds a full widget tree with ProviderScope so we can
  /// capture the WidgetRef and pass it to [AddReminderSheetContent].
  Widget _wrap({
    required _StubAlerts stub,
    AnalyticsSpy? spy,
    required Widget Function(WidgetRef ref) builder,
  }) {
    return ProviderScope(
      overrides: [
        alertsProvider.overrideWith((_) => stub),
        if (spy != null) spy.override,
      ],
      child: MaterialApp(
        theme: mapleThemeData(DesignTheme.fog),
        home: Scaffold(
          body: Consumer(builder: (_, ref, __) => builder(ref)),
        ),
      ),
    );
  }

  testWidgets(
      'shows categorization preview "Government" when passport text entered',
      (tester) async {
    final stub = _StubAlerts();

    late WidgetRef capturedRef;

    await tester.pumpWidget(
      _wrap(
        stub: stub,
        builder: (ref) {
          capturedRef = ref;
          return AddReminderSheetContent(ref: capturedRef);
        },
      ),
    );
    await tester.pump();

    // Enter text that triggers the "Government" rule
    await tester.enterText(
      find.byType(TextField),
      'Renew my passport in September',
    );
    await tester.pump();

    // Categorization preview should mention "Government"
    expect(find.textContaining('Government'), findsOneWidget);

    // Primary button should now say "Add reminder"
    expect(find.text('Add reminder'), findsOneWidget);
  });

  testWidgets('shows suggestion chips when field is empty', (tester) async {
    final stub = _StubAlerts();
    late WidgetRef capturedRef;

    await tester.pumpWidget(
      _wrap(
        stub: stub,
        builder: (ref) {
          capturedRef = ref;
          return AddReminderSheetContent(ref: capturedRef);
        },
      ),
    );
    await tester.pump();

    // Empty field → suggestion chips visible
    expect(find.text('Renew passport in September'), findsOneWidget);
    // Primary button disabled label
    expect(find.text('Type something to begin'), findsOneWidget);
    // Date row is always visible
    expect(find.text('When?'), findsOneWidget);
  });

  testWidgets('tapping a suggestion chip fills the text field', (tester) async {
    final stub = _StubAlerts();
    late WidgetRef capturedRef;

    await tester.pumpWidget(
      _wrap(
        stub: stub,
        builder: (ref) {
          capturedRef = ref;
          return AddReminderSheetContent(ref: capturedRef);
        },
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Snow tires by November'));
    await tester.pump();

    // After tap, field has text → categorization should show "Vehicle"
    expect(find.textContaining('Vehicle'), findsOneWidget);
    expect(find.text('Add reminder'), findsOneWidget);
  });

  testWidgets('addCustom is called and sheet closes on Add reminder tap',
      (tester) async {
    final stub = _StubAlerts();
    final spy = AnalyticsSpy();
    late WidgetRef capturedRef;

    // Use a Navigator so pop() works
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alertsProvider.overrideWith((_) => stub),
          spy.override,
        ],
        child: MaterialApp(
          theme: mapleThemeData(DesignTheme.fog),
          home: Scaffold(
            body: Consumer(
              builder: (_, ref, __) {
                capturedRef = ref;
                return AddReminderSheetContent(ref: capturedRef);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Enter text
    await tester.enterText(find.byType(TextField), 'Pay my rent');
    await tester.pump();

    expect(find.text('Add reminder'), findsOneWidget);

    await tester.tap(find.text('Add reminder'));
    await tester.pump();

    expect(stub.addCustomCalls, 1);
    expect(stub.lastAlert?.title, 'Pay my rent');
    expect(spy.propsOf('reminder_added')!['category'], isNotEmpty);
  });
}

// ── Stub AlertsNotifier ───────────────────────────────────────────────────────

class _StubAlerts extends AlertsNotifier {
  _StubAlerts() {
    // Start with empty data so screens render without SQLite
    state = const AsyncData([]);
  }

  int addCustomCalls = 0;
  Alert? lastAlert;

  @override
  Future<void> addCustom(Alert alert) async {
    addCustomCalls++;
    lastAlert = alert;
    // Don't call super — no DB in tests
  }
}
