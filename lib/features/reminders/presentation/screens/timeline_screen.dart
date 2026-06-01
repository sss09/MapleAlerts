import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/tokens/maple_semantics.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/features/reminders/domain/reminder_category.dart';
import 'package:maple_alerts/features/reminders/presentation/alert_presentation.dart';
import 'package:maple_alerts/providers/alerts_provider.dart';

/// Aurora Timeline screen — vertical time rail showing upcoming reminders
/// sorted nearest-first, ported from TimelineScreen in sheets.jsx.
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    final sem = Theme.of(context).extension<MapleSemantics>()!;
    final alertsAsync = ref.watch(alertsProvider);

    return alertsAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: colors.accent),
      ),
      error: (_, __) => const Center(
        child: Text('Something went wrong loading your timeline.'),
      ),
      data: (alerts) {
        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);

        // Keep today + future only, map → ReminderView, sort by progress desc
        final items = alerts
            .where((a) {
              final d = DateTime(a.deadline.year, a.deadline.month, a.deadline.day);
              return !d.isBefore(todayDate);
            })
            .map((a) => AlertPresentation.map(a, now))
            .toList()
          ..sort((a, b) => b.progress.compareTo(a.progress));

        if (items.isEmpty) {
          return Center(
            child: Text(
              'Nothing on the horizon',
              style: TextStyle(color: colors.muted, fontSize: 15),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 64, 20, 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Text(
                'Your life, on a line',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                  letterSpacing: -0.03 * 27,
                ),
              ),
              const SizedBox(height: 22),

              // ── Vertical timeline ─────────────────────────────────────────
              _TimelineList(items: items, colors: colors, sem: sem),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({
    required this.items,
    required this.colors,
    required this.sem,
  });

  final List<dynamic> items; // List<ReminderView>
  final MapleColors colors;
  final MapleSemantics sem;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Left gradient rail ─────────────────────────────────────────────
        Positioned(
          left: 6,
          top: 6,
          bottom: 10,
          child: Container(
            width: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.accent,
                  colors.slate.withValues(alpha: 0.22),
                ],
              ),
            ),
          ),
        ),

        // ── Items ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              final statusTokens = sem.byName(item.status);
              final cat = categoryFor(item.categoryId);
              final isPassive = item.status == 'planning';

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Status dot on the rail ─────────────────────────────
                    Positioned(
                      left: -29,
                      top: 15,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusTokens.color,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xF2070D15), // dark ring
                              spreadRadius: 4,
                              blurRadius: 0,
                            ),
                            if (!isPassive)
                              BoxShadow(
                                color: statusTokens.glow,
                                blurRadius: 10,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // ── Card ──────────────────────────────────────────────
                    MapleSurface(
                      level: MapleSurfaceLevel.minimal,
                      status: item.status,
                      active: !isPassive,
                      passive: isPassive,
                      radius: 18,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cat.icon,
                            size: 18,
                            color: isPassive ? colors.slate : cat.color,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: isPassive
                                        ? colors.text.withValues(alpha: 0.8)
                                        : colors.text,
                                    letterSpacing: -0.01 * 14.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.whenLabel,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: statusTokens.color,
                                  ),
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
            }).toList(),
          ),
        ),
      ],
    );
  }
}
