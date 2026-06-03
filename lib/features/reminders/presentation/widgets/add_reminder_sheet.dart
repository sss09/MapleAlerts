import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/widgets/maple_surface.dart';
import 'package:maple_alerts/core/design/widgets/stroke_icon.dart';
import 'package:maple_alerts/features/reminders/domain/reminder_category.dart';
import 'package:maple_alerts/models/alert.dart';
import 'package:maple_alerts/providers/alerts_provider.dart';
import 'package:maple_alerts/providers/analytics_provider.dart';

// ── Natural-language smart categorization ─────────────────────────────────────
// Ported from RULES + detect() in docs/design/ux-design-1/sheets.jsx.

class _Rule {
  const _Rule(this.keywords, this.cat, this.when);
  final List<String> keywords;
  final String cat;
  final String when;
}

const List<_Rule> _kRules = [
  _Rule(['passport'], 'Government', 'Sep 2026'),
  _Rule(['health card', 'ohip'], 'Government', 'in 18 days'),
  _Rule(['snow tire', 'winter tire', 'tires'], 'Vehicle', 'by Nov 1'),
  _Rule(['insurance'], 'Vehicle', 'at renewal'),
  _Rule(['sticker', 'licence', 'license', 'plate'], 'Vehicle', 'on your birthday'),
  _Rule(['property tax', 'tax'], 'Finance', 'quarterly'),
  _Rule(['rrsp', 'tfsa', 'contribution'], 'Finance', 'by Mar 1'),
  _Rule(['mortgage'], 'Finance', 'at term end'),
  _Rule(['hydro', 'bill', 'rent', 'utility'], 'Bills', 'monthly'),
  _Rule(['prescription', 'refill', 'doctor', 'dentist'], 'Health', 'when ready'),
  _Rule(['school', 'kids', 'daycare'], 'Family', 'in September'),
];

_Rule? _detect(String text) {
  final low = text.toLowerCase();
  for (final rule in _kRules) {
    if (rule.keywords.any((kw) => low.contains(kw))) return rule;
  }
  return null;
}

// Design-cat name → registry id mapping (Government → 'government', etc.)
const Map<String, String> _kCatToRegistryId = {
  'Government': 'government',
  'Bills': 'bills',
  'Vehicle': 'vehicle',
  'Health': 'health',
  'Finance': 'finance',
  'Family': 'family',
};

const List<String> _kSuggest = [
  'Renew passport in September',
  'Snow tires by November',
  'Pay property tax quarterly',
  'RRSP top-up before March 1',
];

// ── Public entry point ────────────────────────────────────────────────────────

/// Shows the Aurora add-reminder modal bottom sheet.
///
/// Wraps [AddReminderSheetContent] in a transparent, scroll-controlled
/// [showModalBottomSheet] so it slides up from the bottom edge.
Future<void> showAddReminderSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => AddReminderSheetContent(ref: ref),
  );
}

// ── Sheet widget (exposed for testing) ───────────────────────────────────────

/// The visible content of the add-reminder sheet.
///
/// Exposed as a public class so widget tests can pump it directly without
/// going through [showModalBottomSheet].
class AddReminderSheetContent extends StatefulWidget {
  const AddReminderSheetContent({required this.ref, super.key});

  /// The [WidgetRef] from the calling screen — forwarded so the sheet can
  /// read [alertsProvider.notifier].
  final WidgetRef ref;

  @override
  State<AddReminderSheetContent> createState() =>
      _AddReminderSheetContentState();
}

class _AddReminderSheetContentState extends State<AddReminderSheetContent> {
  final TextEditingController _ctrl = TextEditingController();
  String _text = '';
  DateTime _due = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) => setState(() => _text = value);

  void _fillSuggestion(String suggestion) {
    _ctrl.text = suggestion;
    _ctrl.selection =
        TextSelection.collapsed(offset: suggestion.length);
    setState(() => _text = suggestion);
  }

  Future<void> _submit() async {
    final trimmed = _text.trim();
    if (trimmed.isEmpty) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final alert = Alert(
      id: id,
      title: trimmed,
      description: '',
      type: AlertType.custom,
      deadline: DateTime(_due.year, _due.month, _due.day, 9),
    );

    widget.ref
        .read(analyticsProvider)
        .track('reminder_added', {'category': alert.type.name});
    await widget.ref.read(alertsProvider.notifier).addCustom(alert);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;
    final hit = _detect(_text);
    final hasText = _text.trim().isNotEmpty;

    // Colors
    const sheetBg = Color(0xF00D161F);
    const handleColor = Color(0x3D9CB2C8); // rgba(156,178,200,0.24)
    const topBorderColor = Color(0x249CB2C8); // rgba(156,178,200,0.14)
    const accent = Color(0xFF5BC6A0);

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: sheetBg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          border: Border(
            top: BorderSide(color: topBorderColor, width: 1),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 30,
        ),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ─────────────────────────────────────────────────
            Center(
              child: Container(
                width: 38,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // ── Header: sparkle + label ──────────────────────────────────────
            Row(
              children: [
                const StrokeIcon(name: 'sparkle', size: 16, color: accent),
                const SizedBox(width: 7),
                Text(
                  "Add anything — we'll sort it out",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Text field inside a solid MapleSurface ────────────────────────
            MapleSurface(
              level: MapleSurfaceLevel.solid,
              radius: 18,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                maxLines: 3,
                minLines: 2,
                onChanged: _onChanged,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: colors.text,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Renew my passport in September…',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: colors.faint,
                  ),
                ),
              ),
            ),

            // ── Smart categorization preview (animated) ───────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 400),
              firstCurve: Curves.easeInOut,
              secondCurve: Curves.easeInOut,
              sizeCurve: Curves.easeInOut,
              crossFadeState: hit != null
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: hit != null
                  ? _CategorizationRow(hit: hit, colors: colors)
                  : const SizedBox.shrink(),
              secondChild: const SizedBox.shrink(),
            ),

            // ── Suggestion chips (shown when field is empty) ──────────────────
            if (!hasText)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kSuggest
                      .map(
                        (s) => GestureDetector(
                          onTap: () => _fillSuggestion(s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x80111E28),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: colors.line,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: colors.muted,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

            // ── Date picker row ───────────────────────────────────────────────
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _due,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) setState(() => _due = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0x80111E28),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.line, width: 1),
                ),
                child: Row(
                  children: [
                    const StrokeIcon(name: 'calendar', size: 18, color: accent),
                    const SizedBox(width: 10),
                    Text(
                      'When?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.muted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM d, yyyy').format(_due),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Primary action button ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: GestureDetector(
                onTap: hasText ? _submit : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: hasText
                        ? accent
                        : const Color(0x149CB2C8), // rgba(156,178,200,0.08)
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: hasText
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.26),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      hasText ? 'Add reminder' : 'Type something to begin',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.01 * 15.5,
                        color: hasText
                            ? const Color(0xFF06231C)
                            : colors.faint,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

// ── Categorization preview row ────────────────────────────────────────────────

class _CategorizationRow extends StatelessWidget {
  const _CategorizationRow({required this.hit, required this.colors});

  final _Rule hit;
  final MapleColors colors;

  @override
  Widget build(BuildContext context) {
    final registryId = _kCatToRegistryId[hit.cat] ?? 'custom';
    final category = categoryFor(registryId);
    final tint = category.color;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.09), // ~18/255 ≈ 0x12 → use 0.09
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: tint.withValues(alpha: 0.20),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Category icon chip
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Icon(category.icon, size: 16, color: tint),
              ),
            ),
            const SizedBox(width: 10),
            // "Filed under <cat> · I'll remind you <when>"
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: colors.text,
                  ),
                  children: [
                    const TextSpan(text: 'Filed under '),
                    TextSpan(
                      text: hit.cat,
                      style: TextStyle(
                        color: tint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: ' · I\'ll remind you '),
                    TextSpan(
                      text: hit.when,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

