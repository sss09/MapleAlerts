import 'package:flutter/material.dart';
import 'package:maple_alerts/core/design/tokens/maple_colors.dart';

/// A section heading row with an optional trailing count label.
///
/// Renders a [label] at 19 sp / weight 700 and, when [count] is provided,
/// a smaller [count] span in the faint token color.
///
/// Ported from the `SectionHeader` component in
/// `docs/design/ux-design-1/home.jsx`.
class MapleSectionHeader extends StatelessWidget {
  const MapleSectionHeader({
    required this.label,
    this.count,
    super.key,
  });

  /// Primary heading text (e.g. 'Today', 'Seasonal — Canada').
  final String label;

  /// Optional secondary label shown to the right (e.g. '3 items', 'this month').
  final String? count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: colors.text,
              letterSpacing: -0.02,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 9),
            Text(
              count!,
              style: TextStyle(
                fontSize: 12.5,
                color: colors.faint,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
