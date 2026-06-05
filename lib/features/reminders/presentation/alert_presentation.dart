import 'package:maple_alerts/models/alert.dart';
import 'package:maple_alerts/features/reminders/presentation/reminder_view.dart';

abstract class AlertPresentation {
  static ReminderView map(Alert a, DateTime now) {
    // --- category ---
    // Custom alerts carry the add-sheet's detected category in metadata so
    // they land under the right filter chip; built-ins map from their type.
    final categoryId = a.type == AlertType.custom
        ? (a.metadata['category'] as String? ?? 'custom')
        : _categoryId(a.type);

    // --- days (date-only diff, no time component) ---
    final deadlineDate = DateTime(a.deadline.year, a.deadline.month, a.deadline.day);
    final nowDate = DateTime(now.year, now.month, now.day);
    final days = deadlineDate.difference(nowDate).inDays;

    // --- section ---
    final section = days <= 0 ? 'Today' : days <= 7 ? 'This Week' : 'Upcoming';

    // --- status ---
    final status = days <= 2
        ? 'urgent'
        : days <= 7
            ? 'attention'
            : days <= 21
                ? 'upcoming'
                : days <= 60
                    ? 'info'
                    : 'planning';

    // --- whenLabel (computed inline; date_helpers.daysUntilLabel uses DateTime.now()
    //     which doesn't accept an injected 'now', so we replicate the same logic) ---
    final whenLabel = days == 0
        ? 'Today'
        : days == 1
            ? 'Tomorrow'
            : days > 1
                ? 'In $days days'
                : '${-days} days ago';

    // --- progress: 1 when deadline is today/past, 0 when 90+ days away ---
    final progress = (1 - days / 90).clamp(0.0, 1.0);

    // --- amount from metadata ---
    final amount = a.metadata['amount'] as String?;

    return ReminderView(
      id: a.id,
      title: a.title,
      description: a.description,
      categoryId: categoryId,
      status: status,
      section: section,
      whenLabel: whenLabel,
      progress: progress,
      amount: amount,
    );
  }

  static String _categoryId(AlertType type) {
    switch (type) {
      case AlertType.rrsp:
      case AlertType.tfsa:
      case AlertType.gic:
      case AlertType.mortgage:
      case AlertType.boc:
      case AlertType.osap:
      case AlertType.tax:
        return 'finance';
      case AlertType.ccb:
        return 'family';
      case AlertType.custom:
        return 'custom';
    }
  }
}
