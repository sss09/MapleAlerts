import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:maple_alerts/core/design/design_theme_provider.dart';
import 'package:maple_alerts/core/design/tokens/maple_aurora.dart';
import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_section_header.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/providers/analytics_provider.dart';
import 'package:maple_alerts/providers/settings_provider.dart';
import 'package:maple_alerts/providers/subscription_provider.dart';
import 'package:maple_alerts/services/notification_service.dart';

/// Aurora "You" / Profile screen — Day 2 task D2-3.
///
/// Renders:
///  1. Profile header (avatar + name + plan).
///  2. MapleAlerts+ premium card (gradient, perks, CTA or member badge).
///  3. Appearance section: aurora swatch grid + three tweaks toggles.
class ProfileScreenV2 extends ConsumerWidget {
  const ProfileScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    final tweaks = ref.watch(tweaksProvider);
    final subscriptionAsync = ref.watch(subscriptionProvider);
    final isPremium = subscriptionAsync.valueOrNull ?? false;
    final notificationsEnabled =
        ref.watch(settingsProvider).notificationsEnabled;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 64, 20, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Profile header ───────────────────────────────────────────
          _ProfileHeader(isPremium: isPremium, colors: colors),
          const SizedBox(height: 24),

          // ── 2. Premium card ─────────────────────────────────────────────
          _PremiumCard(isPremium: isPremium, colors: colors),
          const SizedBox(height: 28),

          // ── 3. Appearance section ────────────────────────────────────────
          const MapleSectionHeader(label: 'Appearance'),
          const SizedBox(height: 12),

          // Aurora swatch picker
          MapleSurface(
            level: MapleSurfaceLevel.minimal,
            radius: 18,
            padding: const EdgeInsets.all(14),
            child: _AuroraGrid(
              selectedId: tweaks.auroraId,
              colors: colors,
              onSelect: (id) => ref
                  .read(tweaksProvider.notifier)
                  .set(tweaks.copyWith(auroraId: id)),
            ),
          ),
          const SizedBox(height: 10),

          // Tweak toggles
          // Wrap in a transparent Material so SwitchListTile can paint its
          // ink/background without triggering the "DecoratedBox ancestor" assertion.
          MapleSurface(
            level: MapleSurfaceLevel.minimal,
            radius: 18,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  _TweakToggle(
                    label: 'Warm urgency accents',
                    value: tweaks.warmAccents,
                    colors: colors,
                    onChanged: (v) => ref
                        .read(tweaksProvider.notifier)
                        .set(tweaks.copyWith(warmAccents: v)),
                  ),
                  Divider(height: 1, color: colors.line),
                  _TweakToggle(
                    label: 'Status colour legend',
                    value: tweaks.legend,
                    colors: colors,
                    onChanged: (v) => ref
                        .read(tweaksProvider.notifier)
                        .set(tweaks.copyWith(legend: v)),
                  ),
                  Divider(height: 1, color: colors.line),
                  _TweakToggle(
                    label: 'Ambient motion',
                    value: tweaks.motion,
                    colors: colors,
                    onChanged: (v) => ref
                        .read(tweaksProvider.notifier)
                        .set(tweaks.copyWith(motion: v)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── 4. Notifications section ─────────────────────────────────────
          const MapleSectionHeader(label: 'Notifications'),
          const SizedBox(height: 12),

          MapleSurface(
            level: MapleSurfaceLevel.minimal,
            radius: 18,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Material(
              type: MaterialType.transparency,
              child: _TweakToggle(
                label: 'Reminder notifications',
                value: notificationsEnabled,
                colors: colors,
                onChanged: (v) async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setNotificationsEnabled(v);
                  if (!v) {
                    try {
                      await NotificationService.instance.cancelAll();
                    } catch (_) {}
                  } else {
                    try {
                      await NotificationService.instance
                          .scheduleAnnualReminders();
                    } catch (_) {}
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── 5. Privacy section ───────────────────────────────────────────
          const MapleSectionHeader(label: 'Privacy'),
          const SizedBox(height: 12),
          MapleSurface(
            level: MapleSurfaceLevel.minimal,
            radius: 18,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Material(
              type: MaterialType.transparency,
              child: _TweakToggle(
                label: 'Share anonymous usage stats',
                value: ref.watch(analyticsEnabledProvider),
                colors: colors,
                onChanged: (v) =>
                    ref.read(analyticsEnabledProvider.notifier).setEnabled(v),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text(
              'Helps us decide what to build next. Never your numbers, never your identity.',
              style: TextStyle(fontSize: 12, color: colors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile header
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.isPremium, required this.colors});

  final bool isPremium;
  final MapleColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF143029),
            border: Border.all(
              color: colors.accent.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              'M',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.accentHi,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Name + plan
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maya Chen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.text,
                letterSpacing: -0.02 * 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${isPremium ? 'Premium' : 'Free'} plan',
              style: TextStyle(
                fontSize: 12.5,
                color: colors.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MapleAlerts+ premium card
// ─────────────────────────────────────────────────────────────────────────────

const List<String> _kPerks = [
  'AI reminders & predictions',
  'Document & letter scanning',
  'CRA + ServiceCanada sync',
  'Family sharing',
  'Custom categories',
];

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.isPremium, required this.colors});

  final bool isPremium;
  final MapleColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123A34), Color(0xFF0C2230)],
        ),
        border: Border.all(
          color: colors.accent.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 44,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Radial glow blob top-right
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors.accent.withValues(alpha: 0.32),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge row: sparkle + "MAPLEALERTS+"
                  Row(
                    children: [
                      StrokeIcon(name: 'sparkle', size: 16, color: colors.accentHi),
                      const SizedBox(width: 7),
                      Text(
                        'MAPLEALERTS+',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.08 * 12,
                          color: colors.accentHi,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Headline
                  Text(
                    'Let it think a few steps ahead of you.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                      letterSpacing: -0.02 * 20,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Perks list
                  ..._kPerks.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        children: [
                          StrokeIcon(
                            name: 'check',
                            size: 15,
                            color: colors.accent,
                            strokeWidth: 2.0,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            p,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: colors.text.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // CTA area
                  if (!isPremium) ...[
                    _PremiumCta(colors: colors),
                  ] else ...[
                    _MemberBadge(colors: colors),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumCta extends StatelessWidget {
  const _PremiumCta({required this.colors});

  final MapleColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary CTA button
        GestureDetector(
          onTap: () => context.push('/paywall'),
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: colors.accent,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.26),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Try free for 14 days',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF06231C),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Fine print
        Center(
          child: Text(
            r'Then $4.99/mo · cancel anytime',
            style: TextStyle(
              fontSize: 11,
              color: colors.text.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberBadge extends StatelessWidget {
  const _MemberBadge({required this.colors});

  final MapleColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'You\'re a member ✨',
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: colors.accentHi,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Aurora swatch grid
// ─────────────────────────────────────────────────────────────────────────────

class _AuroraGrid extends StatelessWidget {
  const _AuroraGrid({
    required this.selectedId,
    required this.colors,
    required this.onSelect,
  });

  final String selectedId;
  final MapleColors colors;
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context) {
    final entries = kAuroras.entries.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 3.2, // wide tiles, ~52 px tall for default width
      ),
      itemBuilder: (context, i) {
        final key = entries[i].key;
        final aurora = entries[i].value;
        final selected = selectedId == key;

        return GestureDetector(
          onTap: () => onSelect(key),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: aurora.baseStops,
              ),
              border: Border.all(
                color: selected
                    ? colors.accent
                    : colors.line.withValues(alpha: 0.14),
                width: selected ? 2 : 2,
              ),
            ),
            child: Stack(
              children: [
                // Label gradient overlay at bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(11),
                        bottomRight: Radius.circular(11),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0x8C000000),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(6, 4, 6, 3),
                    child: Text(
                      aurora.label,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tweak toggle row
// ─────────────────────────────────────────────────────────────────────────────

class _TweakToggle extends StatelessWidget {
  const _TweakToggle({
    required this.label,
    required this.value,
    required this.colors,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final MapleColors colors;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: colors.text,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: colors.accent,
      dense: true,
    );
  }
}
