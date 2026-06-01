import 'package:flutter/material.dart';
import 'package:maple_alerts/core/design/tokens/maple_colors.dart';
import 'package:maple_alerts/core/design/tokens/maple_semantics.dart';
import 'package:maple_alerts/features/reminders/domain/reminder_category.dart';

/// Ordered list of category IDs shown as filter chips (excluding 'custom').
const _kChipOrder = [
  'government',
  'bills',
  'vehicle',
  'health',
  'finance',
  'home',
  'family',
  'seasonal',
];

// ── Category filter chips ─────────────────────────────────────────────────────

/// A horizontally scrolling row of filter chips for reminder categories.
///
/// The first chip is always "All"; the remaining 8 come from [kReminderCategories]
/// in the canonical order defined by [_kChipOrder] (custom is excluded).
///
/// [active] matches a category id or the string `'All'`.
/// Selecting a chip calls [onPick] with that id / `'All'`.
///
/// Ported from the `Chips` component in `docs/design/ux-design-1/home.jsx`.
class CategoryFilterChips extends StatelessWidget {
  const CategoryFilterChips({
    required this.active,
    required this.onPick,
    super.key,
  });

  /// Currently active chip id ('All' or a category id from [kReminderCategories]).
  final String active;

  /// Called when the user taps a chip; receives the chip's id.
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            id: 'All',
            label: 'All',
            tint: colors.accent,
            icon: null,
            active: active == 'All',
            onPick: onPick,
          ),
          ..._kChipOrder.map((id) {
            final cat = kReminderCategories[id]!;
            return _Chip(
              id: id,
              label: cat.label,
              tint: cat.color,
              icon: cat.icon,
              active: active == id,
              onPick: onPick,
            );
          }),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.id,
    required this.label,
    required this.tint,
    required this.icon,
    required this.active,
    required this.onPick,
  });

  final String id;
  final String label;
  final Color tint;
  final IconData? icon;
  final bool active;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<MapleColors>()!;

    final borderColor = active
        ? tint.withValues(alpha: 0.35)
        : colors.lineStrong;
    final bgColor = active
        ? tint.withValues(alpha: 0.12)
        : const Color(0x9E172430);
    final contentColor = active ? tint : colors.muted;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onPick(id),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: contentColor),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: contentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status legend ─────────────────────────────────────────────────────────────

/// A horizontal row of semantic-status pills shown below the filter chips.
///
/// Renders pills for the five named statuses: urgent, attention, upcoming,
/// info, planning — each tinted from [MapleSemantics].
///
/// Ported from the `Legend` component in `docs/design/ux-design-1/home.jsx`.
class StatusLegend extends StatelessWidget {
  const StatusLegend({super.key});

  static const _kStatuses = [
    'urgent',
    'attention',
    'upcoming',
    'info',
    'planning',
  ];

  @override
  Widget build(BuildContext context) {
    final sem = Theme.of(context).extension<MapleSemantics>()!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _kStatuses.map((name) {
          final s = sem.byName(name);
          return Padding(
            padding: const EdgeInsets.only(right: 7),
            child: Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: s.soft,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: s.color.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: s.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: s.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
