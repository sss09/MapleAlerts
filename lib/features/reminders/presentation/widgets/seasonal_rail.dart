import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_section_header.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/features/reminders/presentation/seasonal_events.dart';

// Teal accent colour used for the seasonal icon chip.
const _kSeasonalTeal = Color(0xFF71C3D6);
const _kSeasonalTealBg = Color(0x1F71C3D6); // rgba(113,195,214,0.12)

/// A "Seasonal — Canada" section: a horizontal rail of upcoming Canadian
/// seasonal events. Each event's *next* occurrence is computed relative to
/// now, only upcoming events within the look-ahead window are shown (soonest
/// first), and the whole section hides itself when nothing is upcoming.
class SeasonalRail extends StatelessWidget {
  const SeasonalRail({super.key, this.now});

  /// Injectable clock for tests; defaults to [DateTime.now].
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    final clock = now ?? DateTime.now();
    final items = upcomingSeasonalEvents(clock);

    // Hide the section entirely when there's nothing seasonally relevant.
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MapleSectionHeader(
          label: 'Seasonal — Canada',
          count: 'coming up',
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((item) {
              final dateLabel = DateFormat('MMM d').format(item.date);
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 192,
                  child: MapleSurface(
                    level: MapleSurfaceLevel.bordered,
                    radius: 20,
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _kSeasonalTealBg,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          alignment: Alignment.center,
                          child: StrokeIcon(
                            name: item.icon,
                            size: 18,
                            color: _kSeasonalTeal,
                          ),
                        ),
                        const SizedBox(height: 11),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.text,
                            height: 1.25,
                            letterSpacing: -0.01,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${item.sub} · $dateLabel',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colors.muted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
