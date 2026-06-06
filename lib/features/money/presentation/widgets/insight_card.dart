import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/tokens/maple_semantics.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/features/money/presentation/money_insight.dart';
import 'package:maple_alerts/providers/analytics_provider.dart';
import 'package:maple_alerts/utils/constants.dart';

/// Renders one [MoneyInsight]. Generic by design — every rule projects onto
/// [MoneyInsight] and is drawn by this single card, so Home doesn't accrete
/// bespoke widgets per feature.
///
/// Tapping the card body toggles the expanded detail section, which includes
/// contextual affiliate CTAs for TFSA, RRSP, and GIC insights.
class InsightCard extends ConsumerStatefulWidget {
  const InsightCard({
    required this.insight,
    this.onAction,
    this.onLearnMore,
    super.key,
  });

  final MoneyInsight insight;

  /// Invoked when the card's CTA is tapped.
  final void Function(InsightAction action)? onAction;

  /// When non-null, a "Learn more" link is shown that opens the topic explainer.
  final VoidCallback? onLearnMore;

  @override
  ConsumerState<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends ConsumerState<InsightCard> {
  bool _showSources = false;
  bool _isExpanded = false;

  /// Maps insight severity onto the app's semantic status palette.
  String get _statusName {
    switch (widget.insight.severity) {
      case InsightSeverity.positive:
        return 'upcoming';
      case InsightSeverity.info:
        return 'info';
      case InsightSeverity.caution:
        return 'attention';
      case InsightSeverity.alert:
        return 'urgent';
    }
  }

  String get _eyebrow {
    switch (widget.insight.kind) {
      case InsightKind.foundMoney:
        return 'FOUND MONEY';
      case InsightKind.guardrail:
        return 'HEADS UP';
      case InsightKind.setup:
        return 'SET UP';
      case InsightKind.info:
        return 'GOOD TO KNOW';
    }
  }

  String get _iconName {
    switch (widget.insight.kind) {
      case InsightKind.foundMoney:
        return 'wallet';
      case InsightKind.guardrail:
        return 'bell';
      case InsightKind.setup:
        return 'sparkle';
      case InsightKind.info:
        return 'clock';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    final sem = Theme.of(context).extension<MapleSemantics>()!;
    final insight = widget.insight;
    final accent = sem.byName(_statusName).color;
    final active = insight.severity != InsightSeverity.info;

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      behavior: HitTestBehavior.opaque,
      child: MapleSurface(
        level: MapleSurfaceLevel.minimal,
        status: _statusName,
        active: active,
        radius: 22,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Eyebrow + estimate tag ────────────────────────────────────
            Row(
              children: [
                StrokeIcon(name: _iconName, size: 14, color: accent),
                const SizedBox(width: 6),
                Text(
                  _eyebrow,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08,
                    color: accent,
                  ),
                ),
                const Spacer(),
                if (insight.isEstimate) _EstimatePill(colors: colors),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: colors.faint,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Headline ──────────────────────────────────────────────────
            Text(
              insight.headline,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: colors.text,
                letterSpacing: -0.02 * 17,
              ),
            ),

            // ── Subline ───────────────────────────────────────────────────
            if (insight.subline != null) ...[
              const SizedBox(height: 6),
              Text(
                insight.subline!,
                style: TextStyle(fontSize: 13, height: 1.45, color: colors.muted),
              ),
            ],

            // ── Expanded detail section ───────────────────────────────────
            if (_isExpanded) ...[
              // ── Learn more (opens the topic explainer) ──────────────────
              if (widget.onLearnMore != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: widget.onLearnMore,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Learn more',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward, size: 13, color: accent),
                    ],
                  ),
                ),
              ],

              // ── How we got this ──────────────────────────────────────────
              if (insight.sources.isNotEmpty) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _showSources = !_showSources),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Text(
                        'How we got this',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.faint,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showSources
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16,
                        color: colors.faint,
                      ),
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: _showSources
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final s in insight.sources)
                                _SourceRow(source: s, colors: colors),
                              const SizedBox(height: 8),
                              Text(
                                'Informational, not financial advice.',
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

              // ── CTA ──────────────────────────────────────────────────────
              if (insight.cta != null) ...[
                const SizedBox(height: 14),
                _CtaButton(
                  label: insight.cta!.label,
                  accent: accent,
                  filled: insight.kind == InsightKind.setup,
                  onTap: () => widget.onAction?.call(insight.cta!.action),
                ),
              ],

              // ── Affiliate CTA ─────────────────────────────────────────────
              Builder(
                builder: (ctx) {
                  final cta = _affiliateCta(insight, colors);
                  if (cta == null) return const SizedBox.shrink();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Divider(color: colors.line, thickness: 0.5),
                      const SizedBox(height: 8),
                      cta,
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Returns a contextual affiliate CTA for specific insight ids, or null.
  Widget? _affiliateCta(MoneyInsight insight, MapleColors colors) {
    return switch (insight.id) {
      'tfsa_room' when (insight.amount ?? 0) > 5000 => _AffiliateCtaRow(
          label: 'Open a TFSA HISA at EQ Bank →',
          url: kEqBankHisaUrl,
          partner: 'eq_bank',
          insightId: insight.id,
          colors: colors,
        ),
      'rrsp_room' when (insight.amount ?? 0) > 5000 => _AffiliateCtaRow(
          label: 'Open an RRSP with Wealthsimple →',
          url: kWealthsimpleUrl,
          partner: 'wealthsimple',
          insightId: insight.id,
          colors: colors,
        ),
      'gic' when insight.severity == InsightSeverity.alert ||
              insight.severity == InsightSeverity.caution =>
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AffiliateCtaRow(
              label: 'Compare GIC rates at EQ Bank →',
              url: kEqBankGicUrl,
              partner: 'eq_bank',
              insightId: insight.id,
              colors: colors,
            ),
            const SizedBox(height: 4),
            _AffiliateCtaRow(
              label: 'Oaken Financial — top GIC rates →',
              url: kOakenGicUrl,
              partner: 'oaken',
              insightId: insight.id,
              colors: colors,
            ),
          ],
        ),
      _ => null,
    };
  }
}

class _EstimatePill extends StatelessWidget {
  const _EstimatePill({required this.colors});
  final MapleColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.line,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Estimate',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colors.faint,
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source, required this.colors});
  final FigureSource source;
  final MapleColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              source.label,
              style: TextStyle(fontSize: 12, color: colors.muted),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            source.value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            '  · ${source.source}',
            style: TextStyle(fontSize: 11, color: colors.faint),
          ),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.label,
    required this.accent,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        width: filled ? double.infinity : null,
        padding: filled ? null : const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: filled ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          border: filled ? null : Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: filled ? const Color(0xFF06231C) : accent,
          ),
        ),
      ),
    );
  }
}

/// A small tappable affiliate link row shown in the expanded section of an
/// [InsightCard]. Launches the given [url] in an external browser and tracks
/// an `affiliate_tapped` analytics event.
class _AffiliateCtaRow extends ConsumerWidget {
  const _AffiliateCtaRow({
    required this.label,
    required this.url,
    required this.partner,
    required this.insightId,
    required this.colors,
  });

  final String label;
  final String url;
  final String partner;
  final String insightId;
  final MapleColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        try {
          ref.read(analyticsProvider).track('affiliate_tapped', {
            'insight_id': insightId,
            'partner': partner,
            'from': 'insight_card',
          });
        } catch (_) {
          // Analytics must never prevent the link from opening.
        }
        try {
          await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {
          // Fire-and-forget: URL launch failures are non-fatal.
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StrokeIcon(name: 'chevron', size: 12, color: colors.muted),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: colors.muted,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
