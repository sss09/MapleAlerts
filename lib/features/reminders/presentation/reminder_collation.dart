import 'package:maple_alerts/models/alert.dart';

/// AlertTypes that recur many times within a year — collapse to next only.
const Set<AlertType> kRecurringSeriesTypes = {AlertType.boc, AlertType.ccb};

/// Collapses repeating built-in series (CCB, BoC) to a single entry — the
/// earliest one due on/after [now]. All other alerts pass through unchanged.
/// Preserves input order for non-collapsed items; collapsed survivors are
/// included in place of the series.
List<Alert> collapseRecurringSeries(List<Alert> alerts, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  bool isPast(Alert a) =>
      DateTime(a.deadline.year, a.deadline.month, a.deadline.day).isBefore(today);

  // Find the earliest future alert per recurring type.
  final nextPerType = <AlertType, Alert>{};
  for (final a in alerts) {
    if (!kRecurringSeriesTypes.contains(a.type)) continue;
    if (isPast(a)) continue;
    final cur = nextPerType[a.type];
    if (cur == null || a.deadline.isBefore(cur.deadline)) nextPerType[a.type] = a;
  }

  final result = <Alert>[];
  final emitted = <AlertType>{};
  for (final a in alerts) {
    if (kRecurringSeriesTypes.contains(a.type)) {
      // Emit only the chosen "next" survivor, once, at the position of the
      // first series member encountered.
      if (emitted.contains(a.type)) continue;
      emitted.add(a.type);
      final survivor = nextPerType[a.type];
      if (survivor != null) result.add(survivor);
      // if no future occurrence, drop the series entirely
    } else {
      result.add(a);
    }
  }
  return result;
}
