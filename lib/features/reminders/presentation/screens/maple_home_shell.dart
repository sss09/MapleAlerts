import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/widgets/maple_scaffold.dart';
import 'package:maple_alerts/features/reminders/presentation/widgets/add_reminder_sheet.dart';
import 'alerts_screen_v2.dart';
import 'home_screen_v2.dart';
import 'profile_screen_v2.dart';
import 'timeline_screen.dart';

/// The top-level app shell for the Aurora design.
///
/// Wraps all tab destinations in [MapleScaffold] which provides the
/// AuroraBackground + glass tab bar + central FAB.
class MapleHomeShell extends ConsumerStatefulWidget {
  const MapleHomeShell({super.key});

  @override
  ConsumerState<MapleHomeShell> createState() => _MapleHomeShellState();
}

class _MapleHomeShellState extends ConsumerState<MapleHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return MapleScaffold(
      currentIndex: _index,
      onTab: (i) => setState(() => _index = i),
      onAdd: () => showAddReminderSheet(context, ref),
      tabs: const [
        MapleTab('home', 'Home'),
        MapleTab('timeline', 'Timeline'),
        MapleTab('bell', 'Alerts'),
        MapleTab('user', 'You'),
      ],
      body: _body(),
    );
  }

  Widget _body() {
    switch (_index) {
      case 0:
        return const HomeScreenV2();
      case 1:
        return const TimelineScreen();
      case 2:
        return const AlertsScreenV2();
      case 3:
        return const ProfileScreenV2();
      default:
        return const HomeScreenV2();
    }
  }
}
