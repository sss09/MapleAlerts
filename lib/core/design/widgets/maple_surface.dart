import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/tokens/maple_semantics.dart';

/// Visual elevation level for [MapleSurface].
///
/// Mirrors the three levels from `surface()` in `docs/design/ux-design-1/ui.jsx`.
enum MapleSurfaceLevel {
  /// Lightest surface — translucent with a subtle backdrop blur.
  minimal,

  /// Mid-weight surface — slightly darker with a stronger border.
  bordered,

  /// Heaviest surface — most opaque, largest blur.
  solid,
}

/// A depth-aware, status-reactive matte-glass container.
///
/// Ported from the `surface()` helper in `docs/design/ux-design-1/ui.jsx`.
/// Renders a [BackdropFilter] blur inside a [ClipRRect], overlaid with a
/// [Container] carrying the background color, border, and box-shadow.
///
/// Token lookup via `Theme.of(context).extension<MapleColors>()` and
/// `Theme.of(context).extension<MapleSemantics>()` — both must be registered
/// on the ambient [ThemeData] (e.g. via [mapleThemeData]).
///
/// **Level behaviour** (background / blur):
/// - [MapleSurfaceLevel.minimal]  → rgba(17,30,40,0.55)  / σ 9
/// - [MapleSurfaceLevel.bordered] → rgba(13,24,34,0.42)  / σ 7
/// - [MapleSurfaceLevel.solid]    → rgba(22,35,46,0.72)  / σ 12
/// - any level when [passive]     → rgba(13,20,29,0.42)  / σ 6
///
/// **Border**: active + status → semantic edge color; otherwise `colors.line`
/// (or `colors.lineStrong` for the bordered level).
///
/// **Shadow**: active + status → semantic glow pair; otherwise a neutral drop.
class MapleSurface extends StatelessWidget {
  const MapleSurface({
    this.level = MapleSurfaceLevel.minimal,
    this.status,
    this.active = false,
    this.passive = false,
    this.radius = 22,
    this.padding = const EdgeInsets.all(15),
    required this.child,
    super.key,
  });

  /// Surface elevation level (controls background opacity and blur).
  final MapleSurfaceLevel level;

  /// Optional semantic status name (e.g. `'urgent'`, `'upcoming'`).
  /// Used together with [active] to drive border color and box-shadow glow.
  final String? status;

  /// When true and [status] is set, the surface shows the semantic edge + glow.
  final bool active;

  /// Passive mode — desaturates to a neutral muted tone regardless of [level].
  final bool passive;

  /// Corner radius applied to [ClipRRect] and [BoxDecoration] (default 22).
  final double radius;

  /// Padding applied inside the [Container] wrapping [child].
  final EdgeInsetsGeometry padding;

  /// Content of the surface.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    final sem = Theme.of(context).extension<MapleSemantics>()!;

    // ── Background color & blur sigma ──────────────────────────────────────
    final Color bg;
    final double blurSigma;

    if (passive) {
      bg = const Color(0x6B0D141D); // rgba(13,20,29,0.42)
      blurSigma = 6;
    } else {
      switch (level) {
        case MapleSurfaceLevel.minimal:
          bg = const Color(0x8C111E28); // rgba(17,30,40,0.55)
          blurSigma = 9;
        case MapleSurfaceLevel.bordered:
          bg = const Color(0x6B0D1822); // rgba(13,24,34,0.42)
          blurSigma = 7;
        case MapleSurfaceLevel.solid:
          bg = const Color(0xB816232E); // rgba(22,35,46,0.72)
          blurSigma = 12;
      }
    }

    // ── Border ─────────────────────────────────────────────────────────────
    final Color borderColor;
    if (active && status != null) {
      borderColor = sem.byName(status!).edge;
    } else if (level == MapleSurfaceLevel.bordered) {
      borderColor = colors.lineStrong;
    } else {
      borderColor = colors.line;
    }
    final border = Border.all(color: borderColor, width: 1);

    // ── Box shadows ────────────────────────────────────────────────────────
    final List<BoxShadow> shadows;
    if (active && status != null) {
      final statusTokens = sem.byName(status!);
      shadows = [
        BoxShadow(color: statusTokens.glow, blurRadius: 26),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.40),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
      ];
    } else {
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.30),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ];
    }

    // ── Render ─────────────────────────────────────────────────────────────
    final borderRadius = BorderRadius.circular(radius);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: borderRadius,
            border: border,
            boxShadow: shadows,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
