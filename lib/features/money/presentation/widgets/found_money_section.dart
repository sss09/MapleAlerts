import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_section_header.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/features/money/presentation/money_insight.dart';
import 'package:maple_alerts/features/money/presentation/money_topic.dart';
import 'package:maple_alerts/features/money/presentation/widgets/ccb_setup_sheet.dart';
import 'package:maple_alerts/features/money/presentation/widgets/fhsa_setup_sheet.dart';
import 'package:maple_alerts/features/money/presentation/widgets/gic_setup_sheet.dart';
import 'package:maple_alerts/features/money/presentation/widgets/explainer_sheet.dart';
import 'package:maple_alerts/features/money/presentation/widgets/insight_card.dart';
import 'package:maple_alerts/features/money/presentation/widgets/money_topics_sheet.dart';
import 'package:maple_alerts/features/money/presentation/widgets/oas_setup_sheet.dart';
import 'package:maple_alerts/features/money/presentation/widgets/rrsp_setup_sheet.dart';
import 'package:maple_alerts/features/money/presentation/widgets/tfsa_setup_sheet.dart';
import 'package:maple_alerts/providers/analytics_provider.dart';
import 'package:maple_alerts/providers/enabled_topics_provider.dart';
import 'package:maple_alerts/providers/money_insights_provider.dart';

/// The "Found money" home surface. Renders real insight cards for tracked +
/// configured topics, collapses unconfigured-but-tracked topics into ONE
/// "get started" card, and offers a "Track more" control to change which
/// topics apply.
class FoundMoneySection extends ConsumerWidget {
  const FoundMoneySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    final insights = ref.watch(moneyInsightsProvider);
    final enabled = ref.watch(enabledTopicsProvider);
    final view = partitionFoundMoney(insights, enabled);

    final children = <Widget>[
      const MapleSectionHeader(label: 'Found money'),
      const SizedBox(height: 8),
    ];

    for (final card in view.cards) {
      ref.read(analyticsProvider).track('insight_card_viewed', {'id': card.id});
      final explainer = explainerForInsightId(card.id);
      children.add(InsightCard(
        insight: card,
        onAction: (a) {
          ref.read(analyticsProvider).track('insight_cta_tapped', {'id': card.id});
          _handleAction(context, a);
        },
        onLearnMore: explainer == null
            ? null
            : () {
                ref.read(analyticsProvider)
                    .track('explainer_opened', {'id': explainer.id});
                showExplainerSheet(context, explainer);
              },
      ));
      children.add(const SizedBox(height: 10));
    }

    if (view.setups.isNotEmpty) {
      children.add(_GetStartedCard(
        setups: view.setups,
        colors: colors,
        onTap: (insight, a) {
          ref.read(analyticsProvider).track('insight_cta_tapped', {'id': insight.id});
          _handleAction(context, a);
        },
      ));
      children.add(const SizedBox(height: 10));
    }

    void openTopics() {
      ref.read(analyticsProvider).track('topics_sheet_opened');
      showMoneyTopicsSheet(context);
    }

    if (view.cards.isEmpty && view.setups.isEmpty) {
      children.add(_TrackPrompt(colors: colors, onTap: openTopics));
    } else {
      children.add(_TrackMoreButton(colors: colors, onTap: openTopics));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  void _handleAction(BuildContext context, InsightAction action) {
    switch (action) {
      case InsightAction.editTfsaProfile:
        showTfsaSetupSheet(context);
      case InsightAction.editRrspProfile:
        showRrspSetupSheet(context);
      case InsightAction.editCcbProfile:
        showCcbSetupSheet(context);
      case InsightAction.editOasProfile:
        showOasSetupSheet(context);
      case InsightAction.editGicProfile:
        showGicSetupSheet(context);
      case InsightAction.editFhsaProfile:
        showFhsaSetupSheet(context);
    }
  }
}

/// One card that collapses all enabled-but-unconfigured topics into a single
/// "set up your money profile" entry with a tappable row per topic.
class _GetStartedCard extends StatelessWidget {
  const _GetStartedCard({
    required this.setups,
    required this.colors,
    required this.onTap,
  });

  final List<MoneyInsight> setups;
  final MapleColors colors;
  final void Function(MoneyInsight insight, InsightAction action) onTap;

  @override
  Widget build(BuildContext context) {
    return MapleSurface(
      level: MapleSurfaceLevel.minimal,
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StrokeIcon(name: 'sparkle', size: 14, color: colors.accent),
              const SizedBox(width: 6),
              Text(
                'SET UP YOUR MONEY PROFILE',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                  color: colors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Add a couple of numbers to unlock what you’re owed and what to do next.',
            style: TextStyle(fontSize: 13, height: 1.4, color: colors.muted),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < setups.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.line),
            _SetupRow(insight: setups[i], colors: colors, onTap: onTap),
          ],
        ],
      ),
    );
  }
}

class _SetupRow extends StatelessWidget {
  const _SetupRow({required this.insight, required this.colors, required this.onTap});

  final MoneyInsight insight;
  final MapleColors colors;
  final void Function(MoneyInsight insight, InsightAction action) onTap;

  @override
  Widget build(BuildContext context) {
    final topic = MoneyTopic.fromInsightId(insight.id);
    final action = insight.cta?.action;
    return GestureDetector(
      onTap: action == null ? null : () => onTap(insight, action),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            StrokeIcon(name: topic?.icon ?? 'sparkle', size: 17, color: colors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                insight.headline,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.text,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: colors.faint),
          ],
        ),
      ),
    );
  }
}

class _TrackMoreButton extends StatelessWidget {
  const _TrackMoreButton({required this.colors, required this.onTap});
  final MapleColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: colors.accent),
            const SizedBox(width: 6),
            Text(
              'Track more',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackPrompt extends StatelessWidget {
  const _TrackPrompt({required this.colors, required this.onTap});
  final MapleColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: MapleSurface(
        level: MapleSurfaceLevel.minimal,
        radius: 18,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            StrokeIcon(name: 'wallet', size: 18, color: colors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Track your TFSA room, RRSP refund, child benefits and more',
                style: TextStyle(fontSize: 13.5, color: colors.text),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: colors.faint),
          ],
        ),
      ),
    );
  }
}
