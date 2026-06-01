import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_section_header.dart';
import 'package:maple_alerts/features/reminders/presentation/alert_presentation.dart';
import 'package:maple_alerts/features/reminders/presentation/reminder_view.dart';
import 'package:maple_alerts/features/reminders/presentation/widgets/category_filter_chips.dart';
import 'package:maple_alerts/features/reminders/presentation/widgets/day_handled_hero.dart';
import 'package:maple_alerts/features/reminders/presentation/widgets/reminder_card.dart';
import 'package:maple_alerts/features/reminders/presentation/widgets/seasonal_rail.dart';
import 'package:maple_alerts/providers/alerts_provider.dart';
import 'package:maple_alerts/core/design/design_theme_provider.dart';

/// The scrollable Home screen content.
///
/// Provides no Scaffold / nav bar — [MapleHomeShell] wraps this in
/// [MapleScaffold] which supplies the AuroraBackground and the glass tab bar.
class HomeScreenV2 extends ConsumerStatefulWidget {
  const HomeScreenV2({super.key});

  @override
  ConsumerState<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends ConsumerState<HomeScreenV2> {
  String _activeCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    final alertsAsync = ref.watch(alertsProvider);
    final tweaks = ref.watch(tweaksProvider);

    final now = DateTime.now();
    final greeting = _greeting(now.hour);
    final dateLabel = DateFormat('EEEE, MMM d').format(now);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 130),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                // ── Header row ──────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: colors.accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: colors.text,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Alert content ───────────────────────────────────────────
                alertsAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(color: colors.accent),
                  ),
                  error: (err, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Couldn't load reminders",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        err.toString(),
                        style: TextStyle(fontSize: 12, color: colors.muted),
                      ),
                    ],
                  ),
                  data: (alerts) {
                    final views = alerts
                        .map((a) => AlertPresentation.map(a, now))
                        .toList();

                    final filtered = _activeCategory == 'All'
                        ? views
                        : views
                            .where((v) => v.categoryId == _activeCategory)
                            .toList();

                    final needs = filtered
                        .where(
                          (v) =>
                              v.status == 'urgent' || v.status == 'attention',
                        )
                        .length;
                    final total = filtered.length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero summary
                        DayHandledHero(needs: needs, total: total),
                        const SizedBox(height: 16),

                        // Category filter chips
                        CategoryFilterChips(
                          active: _activeCategory,
                          onPick: (c) =>
                              setState(() => _activeCategory = c),
                        ),
                        const SizedBox(height: 12),

                        // Status legend
                        if (tweaks.legend) ...[
                          const StatusLegend(),
                          const SizedBox(height: 20),
                        ] else
                          const SizedBox(height: 8),

                        // Sections
                        ..._buildSections(
                          filtered,
                          colors: colors,
                        ),

                        // Seasonal rail
                        const SizedBox(height: 24),
                        const SeasonalRail(),
                        const SizedBox(height: 24),

                        // Footer
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: colors.faint,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "You're all caught up",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.faint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSections(
    List<ReminderView> views, {
    required MapleColors colors,
  }) {
    const sections = ['Today', 'This Week', 'Upcoming'];
    final widgets = <Widget>[];

    for (final section in sections) {
      final items = views.where((v) => v.section == section).toList();
      if (items.isEmpty) continue;

      widgets.add(
        MapleSectionHeader(
          label: section,
          count: '${items.length} item${items.length == 1 ? '' : 's'}',
        ),
      );
      widgets.add(const SizedBox(height: 8));

      for (final item in items) {
        widgets.add(
          ReminderCard(
            item: item,
            onDone: () {},
            onSnooze: () {},
          ),
        );
        widgets.add(const SizedBox(height: 10));
      }
      widgets.add(const SizedBox(height: 8));
    }

    return widgets;
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
