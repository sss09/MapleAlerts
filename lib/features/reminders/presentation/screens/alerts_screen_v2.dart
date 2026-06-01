import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/tokens/maple_semantics.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/features/reminders/domain/reminder_category.dart';
import 'package:maple_alerts/features/reminders/presentation/alert_presentation.dart';
import 'package:maple_alerts/features/reminders/presentation/hidden_reminders_provider.dart';
import 'package:maple_alerts/providers/alerts_provider.dart';
import 'package:maple_alerts/features/reminders/presentation/reminder_collation.dart';

/// Aurora Alerts screen — calm notification experience.
///
/// Ported from AlertsScreen in sheets.jsx. Shows real upcoming reminders
/// (today/future, sorted by progress, capped at 6). Falls back to the 4
/// NOTES sample cards when no reminders exist, so the screen is never empty.
class AlertsScreenV2 extends ConsumerWidget {
  const AlertsScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    final sem = Theme.of(context).extension<MapleSemantics>()!;
    final alertsAsync = ref.watch(alertsProvider);
    final hidden = ref.watch(hiddenRemindersProvider);

    return alertsAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: colors.accent),
      ),
      error: (_, __) => const Center(
        child: Text('Something went wrong loading alerts.'),
      ),
      data: (alerts) {
        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);

        final collapsed = collapseRecurringSeries(alerts, now);

        // Map upcoming reminders (today+future), exclude hidden/done/snoozed,
        // sort by progress desc, take 6
        final items = collapsed
            .where((a) {
              final d = DateTime(a.deadline.year, a.deadline.month, a.deadline.day);
              return !d.isBefore(todayDate);
            })
            .map((a) => AlertPresentation.map(a, now))
            .where((v) => !(hidden[v.id]?.isAfter(now) ?? false))
            .toList()
          ..sort((a, b) => b.progress.compareTo(a.progress));

        final displayItems = items.take(6).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 64, 20, 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Text(
                'The way alerts should feel',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Calm notifications',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                  letterSpacing: -0.03 * 27,
                ),
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  'Human, never robotic. We tell you what matters — and never make you panic.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: colors.muted,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // ── Cards ─────────────────────────────────────────────────────
              if (displayItems.isNotEmpty)
                ...displayItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: _CalmCard(
                      title: item.title,
                      body: item.description.isEmpty
                          ? item.title
                          : item.description,
                      whenLabel: item.whenLabel,
                      categoryLabel: categoryFor(item.categoryId).label,
                      statusLabel: item.title, // subtitle after dot
                      status: item.status,
                      colors: colors,
                      sem: sem,
                    ),
                  ),
                )
              else
                ..._kSampleNotes.map(
                  (n) => Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: _CalmCard(
                      title: n.title,
                      body: n.body,
                      whenLabel: n.time,
                      categoryLabel: n.cat,
                      statusLabel: n.title,
                      status: n.status,
                      colors: colors,
                      sem: sem,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Calm notification card ────────────────────────────────────────────────────

class _CalmCard extends StatelessWidget {
  const _CalmCard({
    required this.title,
    required this.body,
    required this.whenLabel,
    required this.categoryLabel,
    required this.statusLabel,
    required this.status,
    required this.colors,
    required this.sem,
  });

  final String title;
  final String body;
  final String whenLabel;
  final String categoryLabel;
  final String statusLabel;
  final String status;
  final MapleColors colors;
  final MapleSemantics sem;

  @override
  Widget build(BuildContext context) {
    final statusTokens = sem.byName(status);

    return MapleSurface(
      level: MapleSurfaceLevel.solid,
      status: status,
      active: true,
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ───────────────────────────────────────────────────
          Row(
            children: [
              // MapleAlerts app chip
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF102A26),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: StrokeIcon(
                    name: 'leaf',
                    size: 16,
                    color: colors.accentHi,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'MapleAlerts',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '· $title',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.faint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusTokens.soft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusTokens.color,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      statusTokens.label,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: statusTokens.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Body text ────────────────────────────────────────────────────
          Text(
            body,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: colors.text.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 10),

          // ── Footer ───────────────────────────────────────────────────────
          Text(
            '$whenLabel · $categoryLabel',
            style: TextStyle(
              fontSize: 11,
              color: colors.faint,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sample fallback notes (from sheets.jsx NOTES) ─────────────────────────────

class _Note {
  const _Note({
    required this.cat,
    required this.status,
    required this.title,
    required this.body,
    required this.time,
  });

  final String cat;
  final String status;
  final String title;
  final String body;
  final String time;
}

const List<_Note> _kSampleNotes = [
  _Note(
    cat: 'Finance',
    status: 'planning',
    title: 'A gentle heads-up',
    body:
        'Your mortgage renewal window opens next month. Want me to pull current rates so you can compare?',
    time: 'now',
  ),
  _Note(
    cat: 'Vehicle',
    status: 'info',
    title: 'Winter\'s coming',
    body:
        'Looks like snow-tire season is approaching. Most shops near you book 4–5 days out.',
    time: '2h ago',
  ),
  _Note(
    cat: 'Government',
    status: 'upcoming',
    title: 'No rush, just a note',
    body:
        'Your OHIP card expires in 18 days. Renewing online takes about 5 minutes.',
    time: 'Yesterday',
  ),
  _Note(
    cat: 'Finance',
    status: 'attention',
    title: 'Before the deadline',
    body:
        'You have a little RRSP room left. Even a small top-up could trim your tax bill.',
    time: 'Mon',
  ),
];

