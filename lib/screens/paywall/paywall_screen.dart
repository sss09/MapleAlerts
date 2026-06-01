import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens/maple_colors.dart';
import '../../core/design/widgets/aurora_background.dart';
import '../../core/design/widgets/maple_surface.dart';
import '../../core/design/widgets/stroke_icon.dart';
import '../../providers/subscription_provider.dart';

/// Aurora-styled paywall screen — Day 4 task D4-3.
///
/// Layout: transparent Scaffold → Stack → AuroraBackground fill + SafeArea
/// scrollable content.  Visual style mirrors the MapleAlerts+ premium card
/// in [ProfileScreenV2].
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

// Plan identifiers used for selection state.
enum _Plan { monthly, yearly }

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  _Plan _selected = _Plan.yearly;
  bool _loading = false;

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _purchase() async {
    setState(() => _loading = true);
    try {
      final ok = await ref.read(subscriptionProvider.notifier).purchase();
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Purchases aren't available yet — check back soon."),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    try {
      final ok = await ref.read(subscriptionProvider.notifier).restore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Purchases restored!'
              : 'No active purchases found to restore.'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Aurora atmosphere background
          const Positioned.fill(child: AuroraBackground()),

          // Scrollable content inside SafeArea
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Close button ──────────────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.close, color: colors.muted),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Hero section ──────────────────────────────────────────
                  _HeroSection(colors: colors),
                  const SizedBox(height: 28),

                  // ── Perks list ────────────────────────────────────────────
                  _PerksList(colors: colors),
                  const SizedBox(height: 28),

                  // ── Plan selector ─────────────────────────────────────────
                  _PlanSelector(
                    selected: _selected,
                    colors: colors,
                    onSelect: (p) => setState(() => _selected = p),
                  ),
                  const SizedBox(height: 28),

                  // ── Primary CTA ───────────────────────────────────────────
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    _TrialButton(colors: colors, onTap: _purchase),
                    const SizedBox(height: 14),

                    // ── Restore ───────────────────────────────────────────
                    Center(
                      child: TextButton(
                        onPressed: _restore,
                        child: Text(
                          'Restore purchases',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: colors.muted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Fine print ────────────────────────────────────────
                    Text(
                      'Cancel anytime. Billed through the App Store / Google Play.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.faint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero: sparkle badge + headline + subtext
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.colors});

  final MapleColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Badge row: sparkle icon + "MAPLEALERTS+"
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
        const SizedBox(height: 16),

        // Headline
        Text(
          'Let it think a few steps ahead of you.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: colors.text,
            letterSpacing: -0.02 * 26,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 10),

        // Subtext
        Text(
          'Smart alerts, calendar sync and family sharing — everything you need to stay ahead of every deadline.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: colors.muted,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Perks list
// ─────────────────────────────────────────────────────────────────────────────

const List<String> _kPerks = [
  'All categories & personalized trackers',
  'Calendar export & home-screen widget',
  'Smart, multi-stage reminders',
  'Family sharing',
  'No ads — ever',
];

class _PerksList extends StatelessWidget {
  const _PerksList({required this.colors});

  final MapleColors colors;

  @override
  Widget build(BuildContext context) {
    return MapleSurface(
      level: MapleSurfaceLevel.minimal,
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        children: _kPerks
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StrokeIcon(
                      name: 'check',
                      size: 16,
                      color: colors.accent,
                      strokeWidth: 2.0,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: colors.text.withValues(alpha: 0.9),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan selector: two MapleSurface cards (monthly / yearly)
// ─────────────────────────────────────────────────────────────────────────────

class _PlanSelector extends StatelessWidget {
  const _PlanSelector({
    required this.selected,
    required this.colors,
    required this.onSelect,
  });

  final _Plan selected;
  final MapleColors colors;
  final void Function(_Plan) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PlanCard(
            plan: _Plan.monthly,
            label: 'Monthly',
            price: r'$4.99',
            unit: '/mo',
            tag: null,
            selected: selected == _Plan.monthly,
            colors: colors,
            onTap: () => onSelect(_Plan.monthly),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PlanCard(
            plan: _Plan.yearly,
            label: 'Yearly',
            price: r'$34.99',
            unit: '/yr',
            tag: 'Save 40%',
            selected: selected == _Plan.yearly,
            colors: colors,
            onTap: () => onSelect(_Plan.yearly),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.label,
    required this.price,
    required this.unit,
    required this.tag,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final _Plan plan;
  final String label;
  final String price;
  final String unit;
  final String? tag;
  final bool selected;
  final MapleColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MapleSurface(
        level: MapleSurfaceLevel.bordered,
        active: selected,
        status: selected ? 'active' : null,
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan label
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? colors.accentHi : colors.muted,
                letterSpacing: 0.04 * 12,
              ),
            ),
            const SizedBox(height: 8),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                    letterSpacing: -0.02 * 22,
                  ),
                ),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.muted,
                  ),
                ),
              ],
            ),

            // "Save" tag
            if (tag != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag!,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: colors.accentHi,
                  ),
                ),
              ),
            ],

            // Selected indicator dot
            if (selected) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accent,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primary CTA button — green gradient, dark text
// ─────────────────────────────────────────────────────────────────────────────

class _TrialButton extends StatelessWidget {
  const _TrialButton({required this.colors, required this.onTap});

  final MapleColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.accentHi, colors.accent],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.accent.withValues(alpha: 0.30),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Start 14-day free trial',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF06231C),
              letterSpacing: -0.01 * 15,
            ),
          ),
        ),
      ),
    );
  }
}
