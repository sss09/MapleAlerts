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
  'government': ReminderCategory(id: 'government', label: 'Government', icon: Icons.account_balance, color: Color(0xFF74C2A4), defaultLeadTimes: [Duration(days: 30), Duration(days: 7), Duration(days: 1)]),
  'bills':      ReminderCategory(id: 'bills',      label: 'Bills',      icon: Icons.bolt,            color: Color(0xFF8FC2D4), defaultLeadTimes: [Duration(days: 7), Duration(days: 1)]),
  'vehicle':    ReminderCategory(id: 'vehicle',    label: 'Vehicle',    icon: Icons.directions_car, color: Color(0xFF90B0D2), defaultLeadTimes: [Duration(days: 14), Duration(days: 3)]),
  'health':     ReminderCategory(id: 'health',     label: 'Health',     icon: Icons.favorite_border, color: Color(0xFF78C8AC), defaultLeadTimes: [Duration(days: 7), Duration(days: 1)]),
  'finance':    ReminderCategory(id: 'finance',    label: 'Finance',    icon: Icons.savings,         color: Color(0xFFDCC289), defaultLeadTimes: [Duration(days: 60), Duration(days: 30), Duration(days: 7), Duration(days: 1)]),
  // Label 'Household' (not 'Home') so the chip never collides with the Home
  // nav tab; the id stays 'home' for persisted-data compatibility.
  'home':       ReminderCategory(id: 'home',       label: 'Household',  icon: Icons.home_outlined,   color: Color(0xFFAAB8D4), defaultLeadTimes: [Duration(days: 30), Duration(days: 7)]),
  'family':     ReminderCategory(id: 'family',     label: 'Family',     icon: Icons.people_outline,  color: Color(0xFFC2AEE0), defaultLeadTimes: [Duration(days: 7), Duration(days: 1)]),
  'seasonal':   ReminderCategory(id: 'seasonal',   label: 'Seasonal',   icon: Icons.ac_unit,         color: Color(0xFF9CCEDC), defaultLeadTimes: [Duration(days: 14), Duration(days: 3)]),
  'custom':     ReminderCategory(id: 'custom',     label: 'Custom',     icon: Icons.notifications_none, color: Color(0xFF8A99AC)),
};

/// Resolves a category by id, falling back to `custom` for unknown ids.
/// `custom` is guaranteed to exist in [kReminderCategories] (covered by a test).
ReminderCategory categoryFor(String id) =>
    kReminderCategories[id] ?? kReminderCategories['custom']!;
