import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/widgets/maple_section_header.dart';
import 'package:maple_alerts/features/money/presentation/money_insight.dart';
import 'package:maple_alerts/features/money/presentation/widgets/insight_card.dart';
import 'package:maple_alerts/features/money/presentation/widgets/tfsa_setup_sheet.dart';
import 'package:maple_alerts/providers/tfsa_insight_provider.dart';

/// The "Found money" home surface: renders the current list of money insights
/// (today just TFSA room) as a stack of generic [InsightCard]s. Hidden when
/// there are no insights.
class FoundMoneySection extends ConsumerWidget {
  const FoundMoneySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(tfsaInsightsProvider);
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MapleSectionHeader(label: 'Found money'),
        const SizedBox(height: 8),
        for (final insight in insights) ...[
          InsightCard(
            insight: insight,
            onAction: (action) => _handleAction(context, action),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  void _handleAction(BuildContext context, InsightAction action) {
    switch (action) {
      case InsightAction.editTfsaProfile:
        showTfsaSetupSheet(context);
    }
  }
}
