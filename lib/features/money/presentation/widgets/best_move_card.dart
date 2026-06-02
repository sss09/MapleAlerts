import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/features/money/presentation/money_insight.dart';
import 'package:maple_alerts/features/money/presentation/money_topic.dart';
import 'package:maple_alerts/features/money/presentation/widgets/ccb_setup_sheet.dart';
import 'package:maple_alerts/features/money/presentation/widgets/fhsa_setup_sheet.dart';
import 'package:maple_alerts/features/money/presentation/widgets/gic_setup_sheet.dart';
import 'package:maple_alerts/features/money/presentation/widgets/oas_setup_sheet.dart';
import 'package:maple_alerts/features/money/presentation/widgets/rrsp_setup_sheet.dart';
import 'package:maple_alerts/features/money/presentation/widgets/tfsa_setup_sheet.dart';
import 'package:maple_alerts/providers/analytics_provider.dart';
import 'package:maple_alerts/providers/best_move_provider.dart';

/// The pinned "Your best move" recommendation card at the top of Home. Hidden
/// when the engine has nothing actionable to recommend.
class BestMoveCard extends ConsumerStatefulWidget {
  const BestMoveCard({super.key});

  @override
  ConsumerState<BestMoveCard> createState() => _BestMoveCardState();
}

class _BestMoveCardState extends ConsumerState<BestMoveCard> {
  bool _showWhy = false;

  String get _ctaLabel {
    final move = ref.read(bestMoveProvider);
    switch (move?.kind) {
      case BestMoveKind.fixGuardrail:
        return 'Fix it';
      case BestMoveKind.deadline:
        return 'Act before the deadline';
      case BestMoveKind.opportunity:
      case null:
        return 'See how';
    }
  }

  void _act(BestMove move) {
    final topic = MoneyTopic.fromInsightId(move.targetInsightId ?? '');
    switch (topic?.setupAction) {
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
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    final move = ref.watch(bestMoveProvider);
    if (move == null) return const SizedBox.shrink();

    ref.read(analyticsProvider).track('best_move_shown', {
      'kind': move.kind.name,
      'target': move.targetInsightId ?? '',
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123A34), Color(0xFF0C2230)],
        ),
        border: Border.all(color: colors.accent.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StrokeIcon(name: 'sparkle', size: 15, color: colors.accentHi),
              const SizedBox(width: 7),
              Text(
                'YOUR BEST MOVE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.09,
                  color: colors.accentHi,
                ),
              ),
              const Spacer(),
              if (move.dollarValue != null && move.dollarValue! > 0)
                Text(
                  formatDollars(move.dollarValue!),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.accentHi,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            move.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: colors.text,
              letterSpacing: -0.02 * 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            move.detail,
            style: TextStyle(fontSize: 13.5, height: 1.45, color: colors.text.withValues(alpha: 0.85)),
          ),

          if (move.sources.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _showWhy = !_showWhy),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    'How we decided',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.faint,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showWhy ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: colors.faint,
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: _showWhy
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final s in move.sources)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text('${s.label} · ${s.source}',
                                        style: TextStyle(
                                            fontSize: 12, color: colors.muted)),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(s.value,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colors.text)),
                                ],
                              ),
                            ),
                          Text(
                            'Guidance, not financial advice.',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: colors.faint,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],

          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _act(move),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                _ctaLabel,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF06231C),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
