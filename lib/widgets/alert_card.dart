import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../utils/date_helpers.dart';
import '../utils/constants.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback onToggleReminder;
  final VoidCallback? onDelete;

  const AlertCard({
    super.key,
    required this.alert,
    required this.onToggleReminder,
    this.onDelete,
  });

  IconData _typeIcon(AlertType type) {
    switch (type) {
      case AlertType.rrsp:
        return Icons.notifications_active;
      case AlertType.tfsa:
        return Icons.account_balance_wallet;
      case AlertType.gic:
        return Icons.savings;
      case AlertType.mortgage:
        return Icons.home;
      case AlertType.boc:
        return Icons.percent;
      case AlertType.ccb:
        return Icons.family_restroom;
      case AlertType.osap:
        return Icons.school;
      case AlertType.tax:
        return Icons.receipt_long;
      case AlertType.custom:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = daysUntil(alert.deadline);
    final urgency = urgencyColor(days);
    final daysLabel = daysUntilLabel(days);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: urgency,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: urgency.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_typeIcon(alert.type), color: urgency, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  alert.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (alert.isPremium)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kAccentGold,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'PRO',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                formatDate(alert.deadline),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: urgency.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  daysLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: urgency,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          onPressed: onToggleReminder,
                          icon: Icon(
                            alert.reminderEnabled
                                ? Icons.notifications
                                : Icons.notifications_off_outlined,
                            color: alert.reminderEnabled
                                ? kSecondaryColor
                                : Colors.grey,
                          ),
                          tooltip: alert.reminderEnabled
                              ? 'Disable reminder'
                              : 'Enable reminder',
                        ),
                        if (onDelete != null)
                          IconButton(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.grey),
                            tooltip: 'Delete',
                          ),
                      ],
                    ),
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
