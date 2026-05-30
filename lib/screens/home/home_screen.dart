import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_helpers.dart';
import '../../widgets/deadline_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/affiliate_card.dart';
import '../../widgets/empty_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    final subscriptionAsync = ref.watch(subscriptionProvider);
    final settings = ref.watch(settingsProvider);
    final isPremium = subscriptionAsync.valueOrNull ?? false;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('MapleAlerts 🍁'),
          backgroundColor: kSecondaryColor,
          foregroundColor: Colors.white,
          pinned: true,
          automaticallyImplyLeading: false,
        ),
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (!isPremium) ...[
                _ProBannerCard(onTap: () => context.push('/paywall')),
              ],

              // Upcoming deadlines
              const SectionHeader(title: 'Upcoming Deadlines'),
              alertsAsync.when(
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => EmptyState(
                  icon: Icons.error_outline,
                  message: 'Could not load alerts',
                  submessage: e.toString(),
                ),
                data: (alerts) {
                  final upcoming = alerts
                      .where((a) => daysUntil(a.deadline) >= 0)
                      .take(5)
                      .toList();
                  if (upcoming.isEmpty) {
                    return const EmptyState(
                      icon: Icons.check_circle_outline,
                      message: 'All caught up!',
                      submessage: 'No upcoming deadlines right now.',
                    );
                  }
                  return SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: upcoming.length,
                      itemBuilder: (context, index) =>
                          DeadlineCard(alert: upcoming[index]),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // TFSA Room card
              _TfsaRoomCard(settings: settings),

              const SizedBox(height: 8),

              // BoC Next Announcement
              const _BocCard(),

              const SizedBox(height: 8),

              // Canadian Partners
              const SectionHeader(
                title: 'Canadian Partners',
                subtitle: 'Trusted financial services',
              ),
              AffiliateCard(
                name: 'EQ Bank',
                description: 'High-interest savings, GICs, and more',
                url: kEqBankUrl,
                icon: Icons.account_balance,
                color: const Color(0xFF1565C0),
              ),
              AffiliateCard(
                name: 'Wealthsimple',
                description: 'Invest, save, and file taxes in Canada',
                url: kWealthsimpleUrl,
                icon: Icons.show_chart,
                color: const Color(0xFF00897B),
              ),
              AffiliateCard(
                name: 'Ratehub',
                description: 'Compare mortgage rates and financial products',
                url: kRatehubUrl,
                icon: Icons.percent,
                color: const Color(0xFFE65100),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ProBannerCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ProBannerCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: kSecondaryColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unlock Pro Features',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'BoC dates, CCB payments & more',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

class _TfsaRoomCard extends StatelessWidget {
  final SettingsState settings;

  const _TfsaRoomCard({required this.settings});

  int _calculateCumulativeRoom(int birthYear) {
    final startYear = birthYear + 18 < kTfsaStartYear
        ? kTfsaStartYear
        : birthYear + 18;
    final currentYear = DateTime.now().year;
    int total = 0;
    for (int y = startYear; y <= currentYear; y++) {
      total += kTfsaAnnualLimits[y] ?? 7000;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: kPrimaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'TFSA Room',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (settings.tfsaBirthYear == null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Set your birth year to calculate TFSA room',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Set up in Tracker →'),
                  ),
                ],
              ),
            ] else ...[
              Builder(builder: (context) {
                final total =
                    _calculateCumulativeRoom(settings.tfsaBirthYear!);
                final used = (settings.rrspContribution).clamp(0, total);
                final remaining = total - used.toInt();
                final fraction = total > 0 ? used / total : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cumulative room: \$${_fmt(total)}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Available: \$${_fmt(remaining)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: kPrimaryColor),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction.toDouble(),
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        color: kPrimaryColor,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(0)},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return n.toString();
  }
}

class _BocCard extends StatelessWidget {
  const _BocCard();

  DateTime? _nextBocDate() {
    final now = DateTime.now();
    final dates = bocAnnouncementDates(now.year);
    for (final d in dates) {
      if (d.isAfter(now)) return d;
    }
    // Try next year
    final next = bocAnnouncementDates(now.year + 1);
    return next.isNotEmpty ? next.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextDate = _nextBocDate();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.percent,
                  color: Color(0xFF1565C0), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bank of Canada — Next Decision',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextDate != null
                        ? formatDate(nextDate)
                        : 'No upcoming dates',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: nextDate != null
                          ? urgencyColor(daysUntil(nextDate))
                          : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (nextDate != null) ...[
                    Text(
                      daysUntilLabel(daysUntil(nextDate)),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
