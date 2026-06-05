import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/format/maple_money.dart';
import 'package:maple_alerts/providers/analytics_provider.dart';
import 'package:maple_alerts/providers/data_pack_provider.dart';
import 'package:maple_alerts/providers/money_profile_provider.dart';

/// Shows a "rate gap" summary — how much the user could earn by moving their
/// savings to the best available HISA versus their current big-bank account.
///
/// State A (no balance set): capture form.
/// State B (balance set + rates available): annual gap figure + CTAs.
/// State C (balance set + no rate data): gentle fallback, no crash.
///
/// [showRatesSheet] is a top-level helper that will be replaced in A4.
Future<void> showRatesSheet(BuildContext context, WidgetRef ref) async {
  // Stub: A4 will replace this with the full HISA/GIC rates bottom sheet.
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Rates sheet coming soon')),
  );
}

class RateGapCard extends ConsumerStatefulWidget {
  const RateGapCard({super.key});

  @override
  ConsumerState<RateGapCard> createState() => _RateGapCardState();
}

class _RateGapCardState extends ConsumerState<RateGapCard> {
  final _controller = TextEditingController();
  String? _inputError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCalculate() {
    final raw = _controller.text.trim().replaceAll(',', '');
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      setState(() => _inputError = 'Enter a positive dollar amount');
      return;
    }
    setState(() => _inputError = null);
    ref.read(moneyProfileProvider.notifier).setSavingsBalance(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    final profile = ref.watch(moneyProfileProvider);
    final rates = ref.watch(dataPackProvider).rates;
    final balance = profile.savingsBalance;

    if (balance == null) {
      return _StateA(
        colors: colors,
        controller: _controller,
        inputError: _inputError,
        onCalculate: _onCalculate,
      );
    }

    final best = rates.bestHisa;
    if (rates.hisa.isEmpty || best == null) {
      return _StateC(colors: colors);
    }

    final annualGap = balance * (best.rate - rates.bigBankRate) / 100;

    try {
      ref.read(analyticsProvider).track(
        'rate_gap_shown',
        {'gap_annual': annualGap.round()},
      );
    } catch (_) {
      // Analytics must never crash the widget.
    }

    return _StateB(
      colors: colors,
      balance: balance,
      annualGap: annualGap,
      best: best,
      bigBankRate: rates.bigBankRate,
      asOf: rates.asOf,
      onSeeRates: () => showRatesSheet(context, ref),
      onUpdateBalance: () {
        ref.read(moneyProfileProvider.notifier).setSavingsBalance(null);
        _controller.clear();
      },
    );
  }
}

// ─── State A ──────────────────────────────────────────────────────────────────

class _StateA extends StatelessWidget {
  const _StateA({
    required this.colors,
    required this.controller,
    required this.inputError,
    required this.onCalculate,
  });

  final MapleColors colors;
  final TextEditingController controller;
  final String? inputError;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    return MapleSurface(
      level: MapleSurfaceLevel.minimal,
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you losing money at your bank?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your savings balance and we\'ll show you what you could be earning.',
            style: TextStyle(fontSize: 13, color: colors.muted),
          ),
          const SizedBox(height: 14),
          // Input field mimicking a MapleSurface-style bordered look.
          Container(
            decoration: BoxDecoration(
              color: colors.surface1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.lineStrong),
            ),
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              style: TextStyle(fontSize: 15, color: colors.text),
              decoration: InputDecoration(
                hintText: 'e.g. 10000',
                hintStyle: TextStyle(color: colors.faint),
                prefixText: '\$ ',
                prefixStyle: TextStyle(
                  fontSize: 15,
                  color: colors.muted,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                errorText: null, // shown below separately
              ),
            ),
          ),
          if (inputError != null) ...[
            const SizedBox(height: 4),
            Text(
              inputError!,
              style: TextStyle(fontSize: 11.5, color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCalculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Calculate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── State B ──────────────────────────────────────────────────────────────────

class _StateB extends StatelessWidget {
  const _StateB({
    required this.colors,
    required this.balance,
    required this.annualGap,
    required this.best,
    required this.bigBankRate,
    required this.asOf,
    required this.onSeeRates,
    required this.onUpdateBalance,
  });

  final MapleColors colors;
  final double balance;
  final double annualGap;
  final dynamic best; // InstitutionRate
  final double bigBankRate;
  final String asOf;
  final VoidCallback onSeeRates;
  final VoidCallback onUpdateBalance;

  @override
  Widget build(BuildContext context) {
    return MapleSurface(
      level: MapleSurfaceLevel.minimal,
      status: 'upcoming',
      active: true,
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'RATE GAP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: colors.muted,
            ),
          ),
          const SizedBox(height: 6),
          // Big number
          Text(
            '+${MapleMoney.cadAuto(annualGap)}/yr',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colors.accent,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          // Body copy
          Text(
            'You could earn ${MapleMoney.cadAuto(annualGap)} more per year moving '
            '${MapleMoney.cadAuto(balance)} to ${best.name} '
            '(${best.rate}% vs typical '
            '${bigBankRate % 1 == 0 ? bigBankRate.toInt() : bigBankRate}% big bank).',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 8),
          // Insurance chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: colors.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.line),
            ),
            child: Text(
              '${best.insurance} insured',
              style: TextStyle(
                fontSize: 11,
                color: colors.muted,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Primary CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSeeRates,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'See best rates →',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Secondary link
          GestureDetector(
            onTap: onUpdateBalance,
            behavior: HitTestBehavior.opaque,
            child: Text(
              'Update balance',
              style: TextStyle(
                fontSize: 12,
                color: colors.muted,
                decorationColor: colors.muted,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // As-of disclaimer
          Text(
            asOf.isNotEmpty
                ? 'Rates as of $asOf — verify with institution'
                : 'Verify rates with institution',
            style: TextStyle(
              fontSize: 10.5,
              color: colors.faint,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── State C ──────────────────────────────────────────────────────────────────

class _StateC extends StatelessWidget {
  const _StateC({required this.colors});
  final MapleColors colors;

  @override
  Widget build(BuildContext context) {
    return MapleSurface(
      level: MapleSurfaceLevel.minimal,
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Text(
        'Rate comparison unavailable — check back soon.',
        style: TextStyle(fontSize: 13, color: colors.muted),
      ),
    );
  }
}
