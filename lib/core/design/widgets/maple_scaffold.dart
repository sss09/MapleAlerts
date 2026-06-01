import 'dart:ui';

import 'package:flutter/material.dart';

import '../tokens/maple_colors.dart';
import 'aurora_background.dart';
import 'stroke_icon.dart';

/// A single navigation destination in [MapleScaffold].
class MapleTab {
  final String iconName;
  final String label;

  const MapleTab(this.iconName, this.label);
}

/// The top-level app shell.
///
/// Composes three layers inside a full-screen [Stack]:
///   1. [AuroraBackground] — fills the entire screen including below the bar.
///   2. [body] — the active screen content (positioned to fill).
///   3. [_BottomDock] — a floating glass pill anchored 16 px above the bottom
///      edge, containing 4 tabs split either side of a centred FAB.
///
/// Requires exactly 4 [tabs] (two left + two right of the FAB gap).
///
/// The scaffold is transparent so the aurora bleeds through the system
/// navigation area. Pass [extendBody: true] on the inner [Scaffold] so
/// Flutter does not clip the body at the bottom bar.
class MapleScaffold extends StatelessWidget {
  const MapleScaffold({
    required this.currentIndex,
    required this.tabs,
    required this.onTab,
    this.onAdd,
    required this.body,
    super.key,
  });

  /// The index of the currently selected tab (0-based).
  final int currentIndex;

  /// Exactly 4 tabs: [0,1] rendered left of the FAB, [2,3] right.
  final List<MapleTab> tabs;

  /// Called when the user taps a tab with its index.
  final ValueChanged<int> onTab;

  /// Called when the user taps the central FAB. If null the FAB is still
  /// rendered but taps are no-ops.
  final VoidCallback? onAdd;

  /// The active screen widget. It fills the area behind the bottom dock.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final canvas =
        Theme.of(context).extension<MapleColors>()?.canvas ??
            const Color(0xFF070D15);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          // 1. Aurora fills everything including the bottom safe-area.
          const Positioned.fill(child: AuroraBackground()),
          // 2. Active screen content.
          Positioned.fill(child: body),
          // 3. Bottom fade — dissolves scrolling content into the canvas so the
          //    floating dock reads as floating over a clean gradient, not over
          //    leaked list content.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bottomInset + 96,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [canvas.withValues(alpha: 0.0), canvas],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          // 4. Floating glass bottom bar + FAB.
          _BottomDock(
            tabs: tabs,
            currentIndex: currentIndex,
            onTab: onTab,
            onAdd: onAdd,
          ),
        ],
      ),
    );
  }
}

// ── Glass bottom bar with centred FAB ──────────────────────────────────────

class _BottomDock extends StatelessWidget {
  const _BottomDock({
    required this.tabs,
    required this.currentIndex,
    required this.onTab,
    required this.onAdd,
  });

  final List<MapleTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTab;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    // Resolve accent colour from MapleColors theme extension.
    final mc = Theme.of(context).extension<MapleColors>();
    final accentHi = mc?.accentHi ?? const Color(0xFF62D2A8);

    const unselectedColor = Color(0x80BECCDA);
    const barRadius = Radius.circular(26);
    const barBorderRadius = BorderRadius.all(barRadius);

    final left = tabs.take(2).toList();
    final right = tabs.skip(2).take(2).toList();

    // Lift the dock above the system navigation bar / gesture area so it never
    // overlaps the OS nav. viewPadding.bottom is the raw inset even with
    // extendBody / SafeArea consumed.
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Positioned(
      left: 14,
      right: 14,
      bottom: 16 + bottomInset,
      height: 66,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Glass pill bar
          ClipRRect(
            borderRadius: barBorderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xA80B131E),
                  borderRadius: barBorderRadius,
                  border: Border.all(
                    color: const Color(0x1F9CB2C8),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Left tabs (0, 1)
                    for (var i = 0; i < left.length; i++)
                      Expanded(
                        child: _TabItem(
                          tab: left[i],
                          selected: currentIndex == i,
                          onTap: () => onTab(i),
                          selectedColor: accentHi,
                          unselectedColor: unselectedColor,
                        ),
                      ),
                    // Central gap for the FAB
                    const SizedBox(width: 64),
                    // Right tabs (2, 3)
                    for (var i = 0; i < right.length; i++)
                      Expanded(
                        child: _TabItem(
                          tab: right[i],
                          selected: currentIndex == (i + 2),
                          onTap: () => onTab(i + 2),
                          selectedColor: accentHi,
                          unselectedColor: unselectedColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Centred FAB — positioned relative to the bar's own coordinate space.
          // bottom: 30 from the screen bottom → bar is at bottom:16, bar height 66,
          // so FAB centre should be at (30 - 16) = 14 px above the bar top → use
          // a negative top offset of (60/2 - 66/2 - (30-16)) relative to bar.
          // Simpler: just use Positioned with bottom offset relative to bar itself.
          Positioned(
            // FAB sits at screen-bottom + 30 px; bar bottom edge = screen-bottom +16.
            // So FAB bottom relative to bar bottom edge = 30 - 16 = 14 px.
            bottom: 14,
            left: 0,
            right: 0,
            child: Center(
              child: _CentredFab(onAdd: onAdd),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Individual tab item ────────────────────────────────────────────────────

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
  });

  final MapleTab tab;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : unselectedColor;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StrokeIcon(name: tab.iconName, size: 22, color: color),
          const SizedBox(height: 3),
          Text(
            tab.label,
            style: TextStyle(
              fontSize: 9.5,
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.01,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Central FAB ────────────────────────────────────────────────────────────

class _CentredFab extends StatelessWidget {
  const _CentredFab({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF62D2A8), Color(0xFF3CA07E)],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x6B5BC6A0),
              blurRadius: 26,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: StrokeIcon(
            name: 'plus',
            size: 26,
            color: Color(0xFF06231C),
            strokeWidth: 2.4,
          ),
        ),
      ),
    );
  }
}
