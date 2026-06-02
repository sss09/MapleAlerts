import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_section_header.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/features/money/presentation/widgets/explainer_sheet.dart';
import 'package:maple_alerts/providers/analytics_provider.dart';

/// "Learn the rules" — a horizontal rail of plain-language explainer chips.
class LearnSection extends ConsumerWidget {
  const LearnSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<MapleColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MapleSectionHeader(label: 'Learn the rules'),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: kExplainers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final e = kExplainers[i];
              return GestureDetector(
                onTap: () {
                  ref.read(analyticsProvider).track('explainer_opened', {'id': e.id});
                  showExplainerSheet(context, e);
                },
                child: SizedBox(
                  width: 168,
                  child: MapleSurface(
                    level: MapleSurfaceLevel.minimal,
                    radius: 18,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StrokeIcon(name: 'sparkle', size: 15, color: colors.accent),
                        const Spacer(),
                        Text(
                          e.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            color: colors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
