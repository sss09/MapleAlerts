import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_section_header.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/providers/boc_rate_provider.dart';

const _months = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Rates" section showing the live Bank of Canada policy rate + typical prime.
/// Hidden until a rate is available (live or cached). Tap to refresh.
class BocRateCard extends ConsumerWidget {
  const BocRateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    final async = ref.watch(bocRateProvider);
    final rate = async.valueOrNull;
    if (rate == null) return const SizedBox.shrink();

    final asOf =
        '${_months[rate.asOf.month]} ${rate.asOf.day}, ${rate.asOf.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MapleSectionHeader(label: 'Rates'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => ref.invalidate(bocRateProvider),
          behavior: HitTestBehavior.opaque,
          child: MapleSurface(
            level: MapleSurfaceLevel.minimal,
            radius: 22,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                StrokeIcon(name: 'finance', size: 22, color: colors.accent),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bank of Canada policy rate',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: colors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Typical prime ≈ ${rate.typicalPrime.toStringAsFixed(2)}%',
                        style: TextStyle(fontSize: 12, color: colors.faint),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rate.fromCache
                            ? 'Offline · last known $asOf'
                            : 'As of $asOf',
                        style: TextStyle(fontSize: 11, color: colors.faint),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${rate.policyRate.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
