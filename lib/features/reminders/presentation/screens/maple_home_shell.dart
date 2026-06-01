import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_scaffold.dart';
import 'home_screen_v2.dart';

/// The top-level app shell for the Aurora design.
///
/// Wraps all tab destinations in [MapleScaffold] which provides the
/// AuroraBackground + glass tab bar + central FAB.  Tabs 1–3 are
/// placeholder screens until their full implementations land.
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
      onAdd: () {
        // TODO: open add-reminder sheet
      },
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
        return const _PlaceholderTab(label: 'Timeline');
      case 2:
        return const _PlaceholderTab(label: 'Alerts');
      case 3:
        return const _PlaceholderTab(label: 'You');
      default:
        return const HomeScreenV2();
    }
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>();
    final muted = colors?.muted ?? const Color(0xFF6B7A8D);

    return Center(
      child: Text(
        '$label — coming soon',
        style: TextStyle(
          fontSize: 16,
          color: muted,
        ),
      ),
    );
  }
}
