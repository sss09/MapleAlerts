import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'utils/constants.dart';
import 'services/notification_service.dart';
import 'services/revenue_cat_service.dart';
import 'core/design/design_theme_provider.dart';
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
  runApp(const ProviderScope(child: MapleAlertsApp()));
}

class MapleAlertsApp extends ConsumerWidget {
  const MapleAlertsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(themeDataProvider);
    return MaterialApp.router(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
