import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/settings_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/alerts/add_gic_screen.dart';
import 'screens/alerts/add_mortgage_screen.dart';
import 'screens/paywall/paywall_screen.dart';
import 'features/reminders/presentation/screens/maple_home_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final settings = ref.watch(settingsProvider);
  return GoRouter(
    initialLocation: settings.onboardingDone ? '/' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      // Aurora shell — owns its own tab state; sub-routes below are kept
      // for deep-linking from other parts of the app (add alert, etc.).
      GoRoute(
        path: '/',
        builder: (context, state) => const MapleHomeShell(),
      ),
      GoRoute(
        path: '/alerts/add-gic',
        builder: (context, state) => const AddGicScreen(),
      ),
      GoRoute(
        path: '/alerts/add-mortgage',
        builder: (context, state) => const AddMortgageScreen(),
      ),
    ],
  );
});
