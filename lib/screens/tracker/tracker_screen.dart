import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../../utils/date_helpers.dart';

class TrackerScreen extends ConsumerStatefulWidget {
  const TrackerScreen({super.key});

  @override
  ConsumerState<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends ConsumerState<TrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tfsaContribCtrl = TextEditingController();
  final _rrspContribCtrl = TextEditingController();
  final _incomeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final settings = ref.read(settingsProvider);
    _tfsaContribCtrl.text = settings.rrspContribution > 0
        ? settings.rrspContribution.toStringAsFixed(0)
        : '';
    _rrspContribCtrl.text = settings.rrspContribution > 0
        ? settings.rrspContribution.toStringAsFixed(0)
        : '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tfsaContribCtrl.dispose();
    _rrspContribCtrl.dispose();
    _incomeCtrl.dispose();
    super.dispose();
  }

  int _calculateCumulativeRoom(int birthYear) {
    final currentYear = DateTime.now().year;
    final startYear =
        birthYear + 18 < kTfsaStartYear ? kTfsaStartYear : birthYear + 18;
    int total = 0;
    for (int y = startYear; y <= currentYear; y++) {
      total += kTfsaAnnualLimits[y] ?? 7000;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracker'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'TFSA'),
            Tab(text: 'RRSP'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TfsaTab(
            contribCtrl: _tfsaContribCtrl,
            calculateRoom: _calculateCumulativeRoom,
          ),
          _RrspTab(
            contribCtrl: _rrspContribCtrl,
            incomeCtrl: _incomeCtrl,
          ),
        ],
      ),
    );
  }
}

class _TfsaTab extends ConsumerWidget {
  final TextEditingController contribCtrl;
  final int Function(int) calculateRoom;

  const _TfsaTab({
    required this.contribCtrl,
    required this.calculateRoom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final birthYear = settings.tfsaBirthYear;

    final currentYear = DateTime.now().year;
    final years = List.generate(
      currentYear - 1991 + 1,
      (i) => 1991 + i,
    ).reversed.toList();

    final contributions = double.tryParse(contribCtrl.text) ?? 0.0;
    final totalRoom = birthYear != null ? calculateRoom(birthYear) : 0;
    final available = (totalRoom - contributions).clamp(0.0, double.infinity);
    final fraction = totalRoom > 0 ? (contributions / totalRoom).clamp(0.0, 1.0) : 0.0;
    final nextYearRoom = kTfsaAnnualLimits[currentYear + 1] ?? 7000;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Birth Year',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: birthYear,
                  decoration: const InputDecoration(
                    labelText: 'Birth Year',
                    hintText: 'Select your birth year',
                  ),
                  items: years
                      .map((y) => DropdownMenuItem(
                            value: y,
                            child: Text(y.toString()),
                          ))
                      .toList(),
                  onChanged: (y) =>
                      ref.read(settingsProvider.notifier).setTfsaBirthYear(y),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (birthYear != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cumulative TFSA Room',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${_formatMoney(totalRoom)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Since ${birthYear + 18 < kTfsaStartYear ? kTfsaStartYear : birthYear + 18}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your TFSA Contributions',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contribCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Contributions to date (\$)',
                      prefixText: '\$ ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    onChanged: (_) {
                      final val =
                          double.tryParse(contribCtrl.text) ?? 0.0;
                      ref
                          .read(settingsProvider.notifier)
                          .setRrspContribution(val);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Available Room',
                          style: theme.textTheme.bodyMedium),
                      Text(
                        '\$${_formatMoney(available.toInt())}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(fraction * 100).toStringAsFixed(0)}% used',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: kPrimaryColor.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: kPrimaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Room adds \$${_formatMoney(nextYearRoom)} on Jan 1, ${currentYear + 1}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: kPrimaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatMoney(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _RrspTab extends ConsumerWidget {
  final TextEditingController contribCtrl;
  final TextEditingController incomeCtrl;

  const _RrspTab({
    required this.contribCtrl,
    required this.incomeCtrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final deadline = rrspDeadline(now.year);
    final daysLeft = daysUntil(deadline);
    const maxRoom = 31560;

    final income = double.tryParse(incomeCtrl.text) ?? 0.0;
    final estimatedRoom = (income * 0.18).clamp(0, maxRoom).toInt();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event, color: kSecondaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'RRSP Deadline',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formatDate(deadline),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: urgencyColor(daysLeft),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  daysUntilLabel(daysLeft),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: urgencyColor(daysLeft),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last day to contribute to your RRSP for the ${now.year - 1} tax year.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RRSP Contributions This Year',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contribCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contributions so far (\$)',
                    prefixText: '\$ ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: (v) {
                    final val = double.tryParse(v) ?? 0.0;
                    ref
                        .read(settingsProvider.notifier)
                        .setRrspContribution(val);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimate New RRSP Room',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '18% of prior year income (max \$31,560 for 2024)',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: incomeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Last year income (\$)',
                    prefixText: '\$ ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onChanged: (_) {},
                ),
                if (income > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Estimated new room:',
                          style: theme.textTheme.bodyMedium),
                      Text(
                        '~\$${_fmtMoney(estimatedRoom)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (estimatedRoom == maxRoom)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '(Capped at the annual maximum)',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: kSecondaryColor.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RRSP Quick Facts',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const _Bullet(
                    'Contributions reduce your taxable income dollar-for-dollar'),
                const _Bullet(
                    'Growth inside RRSP is tax-deferred until withdrawal'),
                const _Bullet(
                    'Converts to RRIF by end of year you turn 71'),
                const _Bullet(
                    'Unused room carries forward indefinitely'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmtMoney(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
