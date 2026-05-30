import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../models/alert.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/empty_state.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    final subscriptionAsync = ref.watch(subscriptionProvider);
    final isPremium = subscriptionAsync.valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        child: const Icon(Icons.add),
      ),
      body: alertsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          message: 'Could not load alerts',
          submessage: e.toString(),
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none,
              message: 'No alerts yet',
              submessage:
                  'Tap + to add GIC or mortgage reminders',
            );
          }
          return _AlertsList(
            alerts: alerts,
            isPremium: isPremium,
          );
        },
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.savings),
              title: const Text('Add GIC'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/alerts/add-gic');
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Add Mortgage'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/alerts/add-mortgage');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertsList extends ConsumerWidget {
  final List<Alert> alerts;
  final bool isPremium;

  const _AlertsList({required this.alerts, required this.isPremium});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group by type
    final grouped = <AlertType, List<Alert>>{};
    for (final alert in alerts) {
      grouped.putIfAbsent(alert.type, () => []).add(alert);
    }

    final sections = grouped.entries.toList();
    final items = <Widget>[];

    for (final entry in sections) {
      items.add(SectionHeader(title: _typeSectionTitle(entry.key)));
      for (final alert in entry.value) {
        final locked = alert.isPremium && !isPremium;
        items.add(
          Stack(
            children: [
              AlertCard(
                alert: alert,
                onToggleReminder: locked
                    ? () => _showLockedSnackbar(context)
                    : () => ref
                        .read(alertsProvider.notifier)
                        .toggleReminder(alert),
                onDelete: alert.type == AlertType.gic ||
                        alert.type == AlertType.mortgage ||
                        alert.type == AlertType.custom
                    ? () => _confirmDelete(context, ref, alert)
                    : null,
              ),
              if (locked)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => _showLockedSnackbar(context),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: items,
    );
  }

  void _showLockedSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Upgrade to Pro to enable this alert'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Alert alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Alert'),
        content: Text('Delete "${alert.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(alertsProvider.notifier).deleteAlert(alert.id);
    }
  }

  String _typeSectionTitle(AlertType type) {
    switch (type) {
      case AlertType.rrsp:
        return 'RRSP';
      case AlertType.tfsa:
        return 'TFSA';
      case AlertType.gic:
        return 'GIC Investments';
      case AlertType.mortgage:
        return 'Mortgages';
      case AlertType.boc:
        return 'Bank of Canada';
      case AlertType.ccb:
        return 'Canada Child Benefit';
      case AlertType.osap:
        return 'OSAP';
      case AlertType.custom:
        return 'Custom';
    }
  }
}
