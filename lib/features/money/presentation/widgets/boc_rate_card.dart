import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_section_header.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/providers/analytics_provider.dart';
import 'package:maple_alerts/providers/boc_rate_provider.dart';
import 'package:maple_alerts/features/money/presentation/widgets/rates_sheet.dart';

const _months = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _rateContext(double policyRate) {
  if (policyRate > 4.0) return 'Rates are elevated — HISA and GIC yields are strong. Consider locking in.';
  if (policyRate >= 2.5) return 'Moderate rate environment — compare HISA rates to maximise your return.';
  return 'Rates are low — shop high-interest savings accounts for the best yield.';
}

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                const SizedBox(height: 8),
                Text(
                  _rateContext(rate.policyRate),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.muted,
                    height: 1.4,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    try {
                      ref.read(analyticsProvider).track('boc_rate_cta_tapped');
                    } catch (_) {}
                    showRatesSheet(context, ref, source: 'boc_card');
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'See best HISA + GIC rates →',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        StrokeIcon(name: 'chevron', size: 14, color: colors.accent),
                      ],
                    ),
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
