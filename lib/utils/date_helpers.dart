import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatDate(DateTime d) => DateFormat('MMM d, yyyy').format(d);

String formatDateShort(DateTime d) => DateFormat('MMM d').format(d);

int daysUntil(DateTime d) => d.difference(DateTime.now()).inDays;

String daysUntilLabel(int days) {
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  if (days > 0) return 'In $days days';
  final abs = days.abs();
  return '$abs days ago';
}

Color urgencyColor(int days) {
  if (days < 7) return const Color(0xFFD32F2F);
  if (days < 30) return const Color(0xFFE64A19);
  if (days < 60) return const Color(0xFFFFA000);
  return const Color(0xFF388E3C);
}

DateTime rrspDeadline(int year) {
  // RRSP deadline is March 1 of the following year for the prior tax year
  // If March 1 falls on a weekend, CRA moves it to the next business day,
  // but for simplicity we return March 1.
  return DateTime(year, 3, 1);
}

bool isLeapYear(int year) {
  return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
}

List<DateTime> bocAnnouncementDates(int year) {
  if (year == 2025) {
    // Hardcoded 2025 BoC announcement dates
    return [
      DateTime(2025, 1, 29),
      DateTime(2025, 3, 12),
      DateTime(2025, 4, 16),
      DateTime(2025, 6, 4),
      DateTime(2025, 7, 30),
      DateTime(2025, 9, 17),
      DateTime(2025, 10, 29),
      DateTime(2025, 12, 10),
    ];
  }

  // Approximate dates for other years: BoC meets roughly every 6-7 weeks
  // Generate 8 approximate dates spread through the year
  return [
    DateTime(year, 1, 28),
    DateTime(year, 3, 11),
    DateTime(year, 4, 15),
    DateTime(year, 6, 3),
    DateTime(year, 7, 29),
    DateTime(year, 9, 16),
    DateTime(year, 10, 28),
    DateTime(year, 12, 9),
  ];
}

List<DateTime> ccbPaymentDates(int year) {
  // CCB is paid on the 20th of each month, skipping January
  // Returns Feb through Dec of 'year' + January of year+1
  final dates = <DateTime>[];
  for (int month = 2; month <= 12; month++) {
    dates.add(DateTime(year, month, 20));
  }
  // Next January
  dates.add(DateTime(year + 1, 1, 20));
  return dates;
}

DateTime nextTfsaRoomDate() {
  final now = DateTime.now();
  final thisYearJan1 = DateTime(now.year, 1, 1);
  if (now.isBefore(thisYearJan1) || now.isAtSameMomentAs(thisYearJan1)) {
    return thisYearJan1;
  }
  // Already passed Jan 1 of this year, return Jan 1 of next year
  return DateTime(now.year + 1, 1, 1);
}
