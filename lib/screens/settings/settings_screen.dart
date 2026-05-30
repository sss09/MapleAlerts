import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/settings_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/section_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final subscriptionAsync = ref.watch(subscriptionProvider);
    final isPremium = subscriptionAsync.valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Notifications section
          const SectionHeader(title: 'Notifications'),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive reminders before deadlines'),
            value: settings.notificationsEnabled,
            activeColor: kSecondaryColor,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setNotificationsEnabled(v),
          ),
          const Divider(height: 1),

          // Premium section
          const SectionHeader(title: 'Premium'),
          if (isPremium)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: kPrimaryColor.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: kPrimaryColor),
                    const SizedBox(width: 12),
                    Text(
                      'Pro Active',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    const Text('🍁'),
                  ],
                ),
              ),
            )
          else
            ListTile(
              leading: const Icon(Icons.star, color: kAccentGold),
              title: const Text('Upgrade to Pro'),
              subtitle: const Text('\$2.99/month'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/paywall'),
            ),
          const Divider(height: 1),

          // Canadian Partners section
          const SectionHeader(title: 'Canadian Partners'),
          ListTile(
            leading: const Icon(Icons.account_balance, color: Color(0xFF1565C0)),
            title: const Text('EQ Bank'),
            subtitle: const Text('High-interest savings & GICs'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launch(kEqBankUrl),
          ),
          ListTile(
            leading:
                const Icon(Icons.show_chart, color: Color(0xFF00897B)),
            title: const Text('Wealthsimple'),
            subtitle: const Text('Invest, save & file taxes'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launch(kWealthsimpleUrl),
          ),
          ListTile(
            leading: const Icon(Icons.percent, color: Color(0xFFE65100)),
            title: const Text('Ratehub'),
            subtitle: const Text('Compare mortgage rates'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launch(kRatehubUrl),
          ),
          const Divider(height: 1),

          // App section
          const SectionHeader(title: 'App'),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Rate MapleAlerts'),
            onTap: () async {
              final review = InAppReview.instance;
              if (await review.isAvailable()) {
                await review.requestReview();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share MapleAlerts'),
            onTap: () {
              Share.share(
                'Stay on top of Canadian financial deadlines with MapleAlerts! '
                'RRSP, TFSA, GIC, mortgage reminders and more. '
                'Download now: https://maplealerts.app',
                subject: 'MapleAlerts — Canadian Financial Reminders',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Purchases'),
            onTap: () async {
              final success =
                  await ref.read(subscriptionProvider.notifier).restore();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Purchases restored!' : 'No purchases found.',
                    ),
                  ),
                );
              }
            },
          ),
          const Divider(height: 1),

          // About section
          const SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            trailing: const Text('1.0.0',
                style: TextStyle(color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _launch('https://maplealerts.app/privacy'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
