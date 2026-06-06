import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_section_header.dart';
import 'package:maple_alerts/engine/canadian_data_engine/data/rates_data.dart';
import 'package:maple_alerts/providers/analytics_provider.dart';
import 'package:maple_alerts/providers/data_pack_provider.dart';
import 'package:maple_alerts/utils/constants.dart';

// ─── Public API ───────────────────────────────────────────────────────────────

/// Maps an institution [id] to its affiliate URL.
/// Pure function — no Flutter dependencies.
String? urlForInstitution(String id, {bool isGic = false}) {
  if (isGic) {
    return switch (id) {
      'eq_bank' => kEqBankGicUrl,
      'tangerine' => kTangerineUrl,
      _ => kRatehubUrl,
    };
  }
  return switch (id) {
    'eq_bank' => kEqBankHisaUrl,
    'wealthsimple' => kWealthsimpleCashUrl,
    'neo' => kNeoFinancialUrl,
    'simplii' => kSimpliiHisaUrl,
    'tangerine' => kTangerineUrl,
    'koho' => kKohoUrl,
    'motive' => kMotiveUrl,
    'achieva' => kAchievaUrl,
    _ => kRatehubUrl,
  };
}

/// Shows the rates bottom sheet from any [ConsumerWidget] or [ConsumerState].
Future<void> showRatesSheet(
  BuildContext context,
  WidgetRef ref, {
  String source = 'unknown',
}) async {
  if (!context.mounted) return;

  try {
    ref.read(analyticsProvider).track('rates_sheet_opened', {'from': source});
  } catch (_) {
    // Analytics must never prevent the sheet from opening.
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => const _RatesSheetModal(),
  );
}

// ─── Modal wrapper (uses DraggableScrollableSheet) ────────────────────────────

class _RatesSheetModal extends ConsumerWidget {
  const _RatesSheetModal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rates = ref.watch(dataPackProvider).rates;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xF00D161F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0x2E9CB2C8), width: 1),
              left: BorderSide(color: Color(0x2E9CB2C8), width: 1),
              right: BorderSide(color: Color(0x2E9CB2C8), width: 1),
            ),
          ),
          child: RatesSheetContent(
            rates: rates,
            scrollController: scrollController,
          ),
        );
      },
    );
  }
}

// ─── Public sheet content widget ─────────────────────────────────────────────

/// Renders the scrollable body of the rates sheet.
///
/// Exposed publicly so widget tests can pump it directly without a modal
/// bottom sheet or [DraggableScrollableSheet] context.
class RatesSheetContent extends StatefulWidget {
  const RatesSheetContent({
    required this.rates,
    this.scrollController,
    super.key,
  });

  final RatesData rates;

  /// Scroll controller forwarded from [DraggableScrollableSheet] when used
  /// inside the modal. Tests may omit this.
  final ScrollController? scrollController;

  @override
  State<RatesSheetContent> createState() => _RatesSheetContentState();
}

class _RatesSheetContentState extends State<RatesSheetContent> {
  bool _showMoreHisa = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    final rates = widget.rates;

    // Sort HISA: tier-1 first (desc rate), tier-2 (desc rate), tier-3 last
    final tier1 = rates.hisa.where((r) => r.tier == 1).toList()
      ..sort((a, b) => b.rate.compareTo(a.rate));
    final tier2 = rates.hisa.where((r) => r.tier == 2).toList()
      ..sort((a, b) => b.rate.compareTo(a.rate));
    final tier3 = rates.hisa.where((r) => r.tier == 3).toList();

    // Show top 4 tier-1 entries initially
    final topHisa = tier1.take(4).toList();

    // GIC sorted desc by rate
    final gicSorted = rates.gic1yr.toList()
      ..sort((a, b) => b.rate.compareTo(a.rate));

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ─────────────────────────────────────────────────
          Center(
            child: Container(
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0x3D9CB2C8),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ──────────────────────────────────────────────────────
          Text(
            'Best Canadian rates',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          if (rates.asOf.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              'As of ${rates.asOf}',
              style: TextStyle(fontSize: 12, color: colors.muted),
            ),
          ],

          // ── Disclaimer ──────────────────────────────────────────────────
          if (rates.disclaimer.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rates.disclaimer,
              style: TextStyle(
                fontSize: 11,
                color: colors.muted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 20),

          // ── HISA section ────────────────────────────────────────────────
          const MapleSectionHeader(label: 'High-Interest Savings'),
          const SizedBox(height: 8),
          ...topHisa.map((r) => _InstitutionRow(rate: r, isGic: false)),

          // "See more institutions" toggle for tier-2
          if (tier2.isNotEmpty) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: () =>
                  setState(() => _showMoreHisa = !_showMoreHisa),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _showMoreHisa
                    ? 'Show fewer institutions'
                    : 'See more institutions',
                style: TextStyle(fontSize: 13, color: colors.accent),
              ),
            ),
            if (_showMoreHisa) ...[
              const SizedBox(height: 4),
              ...tier2.map((r) => _InstitutionRow(rate: r, isGic: false)),
            ],
          ],

          // Big bank baseline (tier 3) — muted, no link
          if (tier3.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...tier3.map((r) => _InstitutionRow(
                  rate: r,
                  isGic: false,
                  isBigBank: true,
                )),
          ],
          const SizedBox(height: 20),

          // ── GIC section ─────────────────────────────────────────────────
          const MapleSectionHeader(label: '1-Year GIC Rates'),
          const SizedBox(height: 8),
          if (gicSorted.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'GIC rates unavailable — check back soon.',
                style: TextStyle(fontSize: 13, color: colors.muted),
              ),
            )
          else
            ...gicSorted.map((r) => _InstitutionRow(rate: r, isGic: true)),
          const SizedBox(height: 20),

          // ── Footer ──────────────────────────────────────────────────────
          Text(
            'Rates update weekly. Always verify with institution before opening an account.',
            style: TextStyle(fontSize: 11, color: colors.faint),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Institution row ──────────────────────────────────────────────────────────

class _InstitutionRow extends ConsumerWidget {
  const _InstitutionRow({
    required this.rate,
    required this.isGic,
    this.isBigBank = false,
  });

  final InstitutionRate rate;
  final bool isGic;
  final bool isBigBank;

  void _handleTap(BuildContext context, WidgetRef ref) {
    final url = isBigBank ? null : urlForInstitution(rate.id, isGic: isGic);
    if (url == null) return;

    try {
      ref.read(analyticsProvider).track('affiliate_tapped', {
        'institution': rate.id,
        'from': 'rates_sheet',
        'type': isGic ? 'gic' : 'hisa',
      });
    } catch (_) {}

    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    final r = rate;

    return GestureDetector(
      onTap: isBigBank ? null : () => _handleTap(context, ref),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Name + rate row ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isBigBank ? colors.muted : colors.text,
                    ),
                  ),
                ),
                Text(
                  '${r.rate}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isBigBank ? colors.muted : colors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ── Insurance badge + optional note ───────────────────────────
            Row(
              children: [
                _InsuranceBadge(insurance: r.insurance),
                if (r.note != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.note!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFFA726),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),

            // ── Big bank comparison label ─────────────────────────────────
            if (isBigBank) ...[
              const SizedBox(height: 3),
              Text(
                'For comparison only',
                style: TextStyle(fontSize: 11, color: colors.faint),
              ),
            ],

            // ── CTA link ──────────────────────────────────────────────────
            if (!isBigBank) ...[
              const SizedBox(height: 4),
              if (r.hasAffiliate)
                GestureDetector(
                  onTap: () => _handleTap(context, ref),
                  child: Text(
                    'Open account →',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.accent,
                      decoration: TextDecoration.underline,
                      decorationColor: colors.accent,
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    try {
                      ref.read(analyticsProvider).track('affiliate_tapped', {
                        'institution': r.id,
                        'from': 'rates_sheet',
                        'type': isGic ? 'gic' : 'hisa',
                      });
                    } catch (_) {}
                    launchUrl(
                      Uri.parse(kRatehubUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  child: Text(
                    'Compare at Ratehub →',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.muted,
                      decoration: TextDecoration.underline,
                      decorationColor: colors.muted,
                    ),
                  ),
                ),
            ],

            // ── Divider ───────────────────────────────────────────────────
            const SizedBox(height: 8),
            Container(height: 1, color: const Color(0x0D9CB2C8)),
          ],
        ),
      ),
    );
  }
}

// ─── Insurance badge chip ─────────────────────────────────────────────────────

class _InsuranceBadge extends StatelessWidget {
  const _InsuranceBadge({required this.insurance});

  final String insurance;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    if (insurance.contains('CDIC')) {
      bg = const Color(0x1A4CAF50);
      fg = const Color(0xFF4CAF50);
    } else if (insurance.contains('CIPF')) {
      bg = const Color(0x1A2196F3);
      fg = const Color(0xFF2196F3);
    } else if (insurance.contains('DGCM')) {
      bg = const Color(0x1AFFA726);
      fg = const Color(0xFFFFA726);
    } else {
      // Default: green (treat as CDIC-class deposit insurance)
      bg = const Color(0x1A4CAF50);
      fg = const Color(0xFF4CAF50);
    }

    // Abbreviate to first word when full string exceeds 8 characters
    final label =
        insurance.length > 8 ? insurance.split(' ').first : insurance;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
