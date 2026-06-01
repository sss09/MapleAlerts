import 'package:flutter/material.dart';
import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_section_header.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';

/// A single item in the seasonal rail.
class _SeasonalItem {
  const _SeasonalItem({
    required this.icon,
    required this.title,
    required this.sub,
  });

  final String icon;
  final String title;
  final String sub;
}

/// Canadian seasonal intelligence cards, ported from [SEASONAL] in
/// `docs/design/ux-design-1/data.js`.
const List<_SeasonalItem> _seasonal = [
  _SeasonalItem(
    icon: 'finance',
    title: 'CRA filing season is open',
    sub: 'Most returns due Apr 30. Forward your T4 to file early.',
  ),
  _SeasonalItem(
    icon: 'leaf',
    title: 'Carbon rebate (CCR) deposit',
    sub: 'Next quarterly payment lands ~Apr 15.',
  ),
  _SeasonalItem(
    icon: 'seasonal',
    title: 'Daylight saving ends soon',
    sub: 'Clocks back one hour — we\'ll shift your morning alerts.',
  ),
  _SeasonalItem(
    icon: 'home',
    title: 'Property tax — installment 2',
    sub: 'City of Toronto pre-auth due May 1.',
  ),
];

// Teal accent colour used for the seasonal icon chip.
const _kSeasonalTeal = Color(0xFF71C3D6);
const _kSeasonalTealBg = Color(0x1F71C3D6); // rgba(113,195,214,0.12)

/// A "Seasonal — Canada" section with a horizontal rail of 4 cards.
///
/// Each card is a [MapleSurface(level: bordered)] 192 px wide containing:
/// - A 34×34 rounded icon chip with a teal [StrokeIcon]
/// - A title at 14 sp / weight 650
/// - A subtitle at 11.5 sp / muted
///
/// Ported from the `SeasonalRail` component in
/// `docs/design/ux-design-1/home.jsx` and the `SEASONAL` data in
/// `docs/design/ux-design-1/data.js`.
class SeasonalRail extends StatelessWidget {
  const SeasonalRail({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MapleSectionHeader(
          label: 'Seasonal — Canada',
          count: 'this month',
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _seasonal.map((item) {
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
                        // Icon chip
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
                        // Title
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
                        // Subtitle
                        Text(
                          item.sub,
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
