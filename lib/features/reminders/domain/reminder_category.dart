import 'package:flutter/material.dart';

/// Metadata describing a reminder category. The registry ([kReminderCategories])
/// is the single source of truth — adding a category is one entry here.
class ReminderCategory {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final List<Duration> defaultLeadTimes;
  final bool premiumByDefault;
  final String? learnMoreUrl;

  const ReminderCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    this.defaultLeadTimes = const [Duration(days: 7), Duration(days: 1)],
    this.premiumByDefault = false,
    this.learnMoreUrl,
  });
}

const Map<String, ReminderCategory> kReminderCategories = {
  'rrsp': ReminderCategory(
    id: 'rrsp',
    label: 'RRSP',
    icon: Icons.savings,
    color: Color(0xFFD32F2F),
    defaultLeadTimes: [Duration(days: 60), Duration(days: 30), Duration(days: 7), Duration(days: 1)],
  ),
  'tfsa': ReminderCategory(
    id: 'tfsa',
    label: 'TFSA',
    icon: Icons.account_balance_wallet,
    color: Color(0xFF388E3C),
  ),
  'tax': ReminderCategory(
    id: 'tax',
    label: 'Tax Filing',
    icon: Icons.receipt_long,
    color: Color(0xFF1976D2),
    defaultLeadTimes: [Duration(days: 60), Duration(days: 30), Duration(days: 7), Duration(days: 1)],
  ),
  'boc': ReminderCategory(
    id: 'boc',
    label: 'Bank of Canada',
    icon: Icons.account_balance,
    color: Color(0xFF512DA8),
    defaultLeadTimes: [Duration(days: 1)],
  ),
  'ccb': ReminderCategory(
    id: 'ccb',
    label: 'Canada Child Benefit',
    icon: Icons.child_care,
    color: Color(0xFFF57C00),
    defaultLeadTimes: [Duration(days: 1)],
  ),
  'gic': ReminderCategory(
    id: 'gic',
    label: 'GIC Maturity',
    icon: Icons.lock_clock,
    color: Color(0xFF00796B),
    defaultLeadTimes: [Duration(days: 60), Duration(days: 30), Duration(days: 7)],
    premiumByDefault: true,
  ),
  'mortgage': ReminderCategory(
    id: 'mortgage',
    label: 'Mortgage Renewal',
    icon: Icons.home,
    color: Color(0xFF5D4037),
    defaultLeadTimes: [Duration(days: 120), Duration(days: 90), Duration(days: 30)],
    premiumByDefault: true,
  ),
  'osap': ReminderCategory(
    id: 'osap',
    label: 'OSAP',
    icon: Icons.school,
    color: Color(0xFFC2185B),
    defaultLeadTimes: [Duration(days: 30), Duration(days: 7)],
    premiumByDefault: true,
  ),
  'custom': ReminderCategory(
    id: 'custom',
    label: 'Custom',
    icon: Icons.notifications,
    color: Color(0xFF455A64),
  ),
};

/// Resolves a category by id, falling back to `custom` for unknown ids.
/// `custom` is guaranteed to exist in [kReminderCategories] (covered by a test).
ReminderCategory categoryFor(String id) =>
    kReminderCategories[id] ?? kReminderCategories['custom']!;
