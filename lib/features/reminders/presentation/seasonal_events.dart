import 'package:flutter/foundation.dart';

/// A recurring Canadian seasonal event, resolved to its next occurrence.
@immutable
class SeasonalEvent {
  const SeasonalEvent({
    required this.icon,
    required this.title,
    required this.sub,
    required this.date,
  });

  final String icon;
  final String title;
  final String sub;

  /// The next upcoming occurrence (date-only).
  final DateTime date;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Next occurrence of an annual (month, day) on/after today.
DateTime _nextAnnual(DateTime now, int month, int day) {
  final today = _dateOnly(now);
  var d = DateTime(now.year, month, day);
  if (d.isBefore(today)) d = DateTime(now.year + 1, month, day);
  return d;
}

/// Soonest next occurrence among several annual (month, day) anchors —
/// used for quarterly events.
DateTime _nextAmong(DateTime now, List<List<int>> monthDays) {
  DateTime? best;
  for (final md in monthDays) {
    final d = _nextAnnual(now, md[0], md[1]);
    if (best == null || d.isBefore(best)) best = d;
  }
  return best!;
}

/// First Sunday of November (DST ends in Canada), on/after today.
DateTime _firstSundayOfNov(DateTime now) {
  DateTime compute(int year) {
    final first = DateTime(year, 11, 1);
    final offset = (DateTime.sunday - first.weekday) % 7;
    return first.add(Duration(days: offset));
  }

  final today = _dateOnly(now);
  var d = compute(now.year);
  if (d.isBefore(today)) d = compute(now.year + 1);
  return d;
}

/// Returns the Canadian seasonal events whose next occurrence falls within the
/// look-ahead window, soonest first. Never returns past events.
List<SeasonalEvent> upcomingSeasonalEvents(
  DateTime now, {
  int withinDays = 75,
  int max = 5,
}) {
  final today = _dateOnly(now);
  final all = <SeasonalEvent>[
    SeasonalEvent(
      icon: 'finance',
      title: 'CRA tax filing deadline',
      sub: 'File your return to avoid penalties',
      date: _nextAnnual(now, 4, 30),
    ),
    // NOTE: the Canada Carbon Rebate for individuals is DISCONTINUED (final
    // payment Apr 2025; fuel charge ended Apr 1 2025). Deliberately omitted —
    // showing it would surface money that no longer exists.
    SeasonalEvent(
      icon: 'finance',
      title: 'GST/HST credit',
      sub: 'Quarterly credit payment',
      date: _nextAmong(now, const [
        [1, 5],
        [4, 5],
        [7, 5],
        [10, 5],
      ]),
    ),
    SeasonalEvent(
      icon: 'wallet',
      title: 'RRSP contribution deadline',
      sub: 'Last day to contribute for the tax year',
      date: _nextAnnual(now, 3, 1),
    ),
    SeasonalEvent(
      icon: 'wallet',
      title: 'New TFSA room opens',
      sub: 'Fresh contribution room for the year',
      date: _nextAnnual(now, 1, 1),
    ),
    SeasonalEvent(
      icon: 'finance',
      title: 'Self-employed tax filing',
      sub: 'Filing due Jun 15 (balance owing still due Apr 30)',
      date: _nextAnnual(now, 6, 15),
    ),
    SeasonalEvent(
      icon: 'family',
      title: 'RESP contribution cutoff',
      sub: 'Contribute by Dec 31 for this year’s CESG grant',
      date: _nextAnnual(now, 12, 31),
    ),
    SeasonalEvent(
      icon: 'home',
      title: 'FHSA room opens',
      sub: 'New \$8,000 first-home savings room on Jan 1',
      date: _nextAnnual(now, 1, 1),
    ),
    SeasonalEvent(
      icon: 'finance',
      title: 'Charitable donation cutoff',
      sub: 'Donate by Dec 31 to claim on this year’s return',
      date: _nextAnnual(now, 12, 31),
    ),
    SeasonalEvent(
      icon: 'finance',
      title: 'Tax instalment due',
      sub: 'Quarterly CRA instalment (self-employed / investors)',
      date: _nextAmong(now, const [
        [3, 15],
        [6, 15],
        [9, 15],
        [12, 15],
      ]),
    ),
    SeasonalEvent(
      icon: 'seasonal',
      title: 'Daylight saving ends',
      sub: 'Clocks go back one hour',
      date: _firstSundayOfNov(now),
    ),
  ];

  final limit = today.add(Duration(days: withinDays));
  final upcoming = all
      .where((e) => !e.date.isBefore(today) && !e.date.isAfter(limit))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  return upcoming.take(max).toList();
}
