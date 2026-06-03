import 'dart:async';

import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'utils/constants.dart';
import 'services/notification_service.dart';
import 'services/revenue_cat_service.dart';
import 'core/design/design_theme_provider.dart';
import 'providers/data_pack_provider.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService.instance.initialize();
  // Fire-and-forget: schedule annual Canadian reminders (RRSP, CCB, BoC)
  // only when the user has not disabled notifications.
  // kIsWeb-guarded inside scheduleAnnualReminders; never blocks startup.
  SharedPreferences.getInstance().then((p) {
    if (p.getBool(kNotificationsEnabledKey) ?? true) {
      NotificationService.instance.scheduleAnnualReminders();
    }
  }).catchError((_) {});
  await RevenueCatService.instance.initialize();
  // Anonymous analytics (Aptabase). The key is a public app identifier.
  // Failure must never block boot — offline/blocked is fine.
  try {
    await Aptabase.init('A-US-2496453611');
  } catch (_) {
    // App works fully without analytics.
  }
  final container = ProviderContainer();
  unawaited(initDataPack(container));
  runApp(UncontrolledProviderScope(
    container: container,
    child: const MapleAlertsApp(),
  ));
}

class MapleAlertsApp extends ConsumerWidget {
  const MapleAlertsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final lightTheme = ref.watch(lightThemeDataProvider);
    final darkTheme = ref.watch(darkThemeDataProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
