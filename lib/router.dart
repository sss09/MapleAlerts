import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/settings_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/alerts/alerts_screen.dart';
import 'screens/alerts/add_gic_screen.dart';
import 'screens/alerts/add_mortgage_screen.dart';
import 'screens/tracker/tracker_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/paywall/paywall_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final settings = ref.watch(settingsProvider);
  return GoRouter(
    initialLocation: settings.onboardingDone ? '/home' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/alerts',
            builder: (context, state) => const AlertsScreen(),
            routes: [
              GoRoute(
                path: 'add-gic',
                builder: (context, state) => const AddGicScreen(),
              ),
              GoRoute(
                path: 'add-mortgage',
                builder: (context, state) => const AddMortgageScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/tracker',
            builder: (context, state) => const TrackerScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
