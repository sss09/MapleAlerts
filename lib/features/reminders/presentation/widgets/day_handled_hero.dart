import 'package:flutter/material.dart';
import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/progress_ring.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';

/// Hero summary card for the Home screen.
///
/// Displays how many reminders still need the user's attention ([needs]) vs
/// the total active reminders ([total]).  The progress ring fills as items
/// are resolved; the copy adapts the counters live.
///
/// Ported from the `Hero` component in `docs/design/ux-design-1/home.jsx`.
class DayHandledHero extends StatelessWidget {
  const DayHandledHero({
    required this.needs,
    required this.total,
    super.key,
  });

  /// Number of reminders that still require action.
  final int needs;

  /// Total number of active reminders (handled + needs).
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    final handled = total - needs;
    final progress = total == 0 ? 1.0 : handled / total;

    return MapleSurface(
      level: MapleSurfaceLevel.minimal,
      radius: 26,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Progress ring with needs count inside ────────────────────────
          ProgressRing(
            progress: progress,
            size: 66,
            strokeWidth: 5,
            color: colors.accent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$needs',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    height: 1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'to do',
                  style: TextStyle(
                    fontSize: 8.5,
                    color: colors.faint,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // ── Right column: headline + body copy ──────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sparkle + headline
                Row(
                  children: [
                    StrokeIcon(
                      name: 'sparkle',
                      size: 14,
                      color: colors.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'YOUR DAY, HANDLED',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.08,
                        color: colors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Body copy — "$needs things" is bold
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: colors.text,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: '$needs things',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' need you this week. '),
                      TextSpan(
                        text:
                            'The other $handled are quietly taken care of.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
