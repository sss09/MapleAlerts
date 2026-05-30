import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'services/notification_service.dart';
import 'services/revenue_cat_service.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService.instance.initialize();
  await RevenueCatService.instance.initialize();
  runApp(const ProviderScope(child: MapleAlertsApp()));
}

class MapleAlertsApp extends ConsumerWidget {
  const MapleAlertsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
