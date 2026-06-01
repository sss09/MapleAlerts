import 'package:flutter/material.dart';
import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/tokens/maple_semantics.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/progress_ring.dart';
import 'package:maple_alerts/features/reminders/domain/reminder_category.dart';
import 'package:maple_alerts/features/reminders/presentation/affiliate_links.dart';
import 'package:maple_alerts/features/reminders/presentation/reminder_view.dart';
import 'package:url_launcher/url_launcher.dart';

/// A tap-to-expand, swipe-to-act card for a single [ReminderView].
///
/// - Swiping end-to-start reveals Snooze + Done action chips; confirming
///   the swipe calls [onDone] but never removes the widget (parent controls
///   list membership).
/// - Tapping anywhere on the card face toggles an expandable detail section
///   that shows the description, status badge, and "Mark done" / "Snooze"
///   action pills.
class ReminderCard extends StatefulWidget {
  const ReminderCard({
    required this.item,
    this.onDone,
    this.onSnooze,
    super.key,
  });

  /// The reminder data to display.
  final ReminderView item;

  /// Called when the user confirms "Mark done" (tap pill or swipe confirm).
  final VoidCallback? onDone;

  /// Called when the user taps "Snooze".
  final VoidCallback? onSnooze;

  @override
  State<ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<ReminderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    final sem = Theme.of(context).extension<MapleSemantics>()!;

    final cat = categoryFor(widget.item.categoryId);
    final status = sem.byName(widget.item.status, warmAccents: true);

    return Dismissible(
      key: ValueKey(widget.item.id),
      direction: DismissDirection.endToStart,
      // Background revealed on swipe (end-to-start = right side action strip).
      background: _SwipeBackground(status: status, colors: colors),
      // Swipe triggers Done but never removes the widget — parent controls list.
      confirmDismiss: (_) async {
        widget.onDone?.call();
        return false;
      },
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: MapleSurface(
          level: MapleSurfaceLevel.minimal,
          status: widget.item.status,
          active: _expanded,
          radius: 22,
          padding: const EdgeInsets.fromLTRB(14, 15, 15, 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Ring + category icon avatar
                  ProgressRing(
                    progress: widget.item.progress,
                    size: 42,
                    strokeWidth: 3,
                    color: status.color,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(cat.icon, size: 17, color: cat.color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title + amount, when + category
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.item.title,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: colors.text,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.item.amount != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                widget.item.amount!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.text.withValues(alpha: 0.82),
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // When + category row
                        Row(
                          children: [
                            // Status dot
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: status.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.item.whenLabel,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: status.color,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Faint separator dot
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: colors.faint,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: colors.faint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Animated chevron
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: colors.faint,
                    ),
                  ),
                ],
              ),

              // ── Expandable detail ────────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _expanded
                    ? _ExpandedDetail(
                        item: widget.item,
                        status: status,
                        colors: colors,
                        onDone: widget.onDone,
                        onSnooze: widget.onSnooze,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Expanded detail section ───────────────────────────────────────────────────

class _ExpandedDetail extends StatefulWidget {
  const _ExpandedDetail({
    required this.item,
    required this.status,
    required this.colors,
    this.onDone,
    this.onSnooze,
  });

  final ReminderView item;
  final MapleStatus status;
  final MapleColors colors;
  final VoidCallback? onDone;
  final VoidCallback? onSnooze;

  @override
  State<_ExpandedDetail> createState() => _ExpandedDetailState();
}

class _ExpandedDetailState extends State<_ExpandedDetail> {
  Future<void> _launchAffiliate(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final affiliateLink = affiliateForCategory(widget.item.categoryId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        // Divider
        Divider(
          height: 1,
          thickness: 1,
          color: widget.colors.line,
        ),
        const SizedBox(height: 12),
        // Status badge pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: widget.status.soft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.status.color.withValues(alpha: 0.20),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: widget.status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.status.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: widget.status.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Description
        Text(
          widget.item.description,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: widget.colors.text.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: 14),
        // Action pills row
        Row(
          children: [
            // Mark done — solid status color background
            _ActionPill(
              label: 'Mark done',
              background: widget.status.color,
              textColor: const Color(0xFF0A1520),
              onTap: widget.onDone,
            ),
            const SizedBox(width: 8),
            // Snooze — subtle background
            _ActionPill(
              label: 'Snooze',
              background: widget.colors.surface2.withValues(alpha: 0.70),
              textColor: widget.colors.text,
              onTap: widget.onSnooze,
            ),
          ],
        ),
        // ── Affiliate CTA (only for categories with a partner) ───────────
        if (affiliateLink != null) ...[
          const SizedBox(height: 10),
          // "Sponsored" transparency tag
          Text(
            'PARTNER',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: widget.colors.faint,
            ),
          ),
          const SizedBox(height: 5),
          // Full-width subtle CTA button
          GestureDetector(
            onTap: () => _launchAffiliate(affiliateLink.url),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: widget.colors.surface2.withValues(alpha: 0.50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.colors.accent.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      affiliateLink.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.colors.accent,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: widget.colors.accent.withValues(alpha: 0.70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Action pill ───────────────────────────────────────────────────────────────

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.background,
    required this.textColor,
    this.onTap,
  });

  final String label;
  final Color background;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(17),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// ── Swipe background ─────────────────────────────────────────────────────────

/// Revealed behind the card during an end-to-start swipe.
///
/// Shows a Snooze chip on the left and a Done chip on the right of the strip.
/// The swipe confirming Done is handled by [ReminderCard.confirmDismiss].
class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.status,
    required this.colors,
  });

  final MapleStatus status;
  final MapleColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: status.soft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Snooze chip
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: colors.surface2.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.snooze, size: 15, color: colors.muted),
                const SizedBox(width: 6),
                Text(
                  'Snooze',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Done chip
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: status.color.withValues(alpha: 0.40),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 15, color: status.color),
                const SizedBox(width: 6),
                Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: status.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
