import 'package:flutter/material.dart';

void main() {
  runApp(const MapleAlertsApp());
}

class MapleAlertsApp extends StatelessWidget {
  const MapleAlertsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MapleAlerts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD52B1E), // Canadian red
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class DeadlineCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<Deadline> deadlines;

  const DeadlineCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.deadlines,
  });
}

class Deadline {
  final String title;
  final String description;
  final DateTime date;
  final bool isRecurring;

  const Deadline({
    required this.title,
    required this.description,
    required this.date,
    this.isRecurring = false,
  });

  bool get isUpcoming => date.isAfter(DateTime.now());

  int get daysUntil => date.difference(DateTime.now()).inDays;
}

final List<DeadlineCategory> sampleCategories = [
  DeadlineCategory(
    name: 'Tax',
    icon: Icons.receipt_long,
    color: const Color(0xFFD52B1E),
    deadlines: [
      Deadline(
        title: 'Personal Income Tax Filing',
        description: 'CRA T1 return due for most Canadians',
        date: DateTime(DateTime.now().year, 4, 30),
        isRecurring: true,
      ),
      Deadline(
        title: 'Self-Employed Tax Filing',
        description: 'Extended deadline for self-employed individuals',
        date: DateTime(DateTime.now().year, 6, 15),
        isRecurring: true,
      ),
      Deadline(
        title: 'RRSP Contribution Deadline',
        description: 'Last day to contribute for previous tax year',
        date: DateTime(DateTime.now().year, 3, 3),
        isRecurring: true,
      ),
    ],
  ),
  DeadlineCategory(
    name: 'Benefits',
    icon: Icons.health_and_safety,
    color: const Color(0xFF1B5E20),
    deadlines: [
      Deadline(
        title: 'GST/HST Credit Application',
        description: 'Apply when filing your tax return',
        date: DateTime(DateTime.now().year, 4, 30),
        isRecurring: true,
      ),
      Deadline(
        title: 'Canada Child Benefit Review',
        description: 'Annual income information update',
        date: DateTime(DateTime.now().year, 7, 20),
        isRecurring: true,
      ),
    ],
  ),
  DeadlineCategory(
    name: 'Voting',
    icon: Icons.how_to_vote,
    color: const Color(0xFF1565C0),
    deadlines: [
      Deadline(
        title: 'Federal Voter Registration',
        description: 'Register or update your address on the voters list',
        date: DateTime(DateTime.now().year, 10, 1),
      ),
    ],
  ),
  DeadlineCategory(
    name: 'Immigration',
    icon: Icons.flight_land,
    color: const Color(0xFF6A1B9A),
    deadlines: [
      Deadline(
        title: 'PR Card Renewal',
        description: 'Permanent Resident card renewal (5-year cycle)',
        date: DateTime(DateTime.now().year + 1, 1, 15),
      ),
      Deadline(
        title: 'Citizenship Application Window',
        description: 'Check if you meet the 1095-day physical presence',
        date: DateTime(DateTime.now().year, 9, 1),
        isRecurring: true,
      ),
    ],
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final upcomingDeadlines = sampleCategories
        .expand((c) => c.deadlines)
        .where((d) => d.isUpcoming && d.daysUntil <= 90)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD52B1E),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Text('🍁', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            const Text(
              'MapleAlerts',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (upcomingDeadlines.isNotEmpty) ...[
              _SectionHeader(
                title: 'Coming Up',
                subtitle: 'Next 90 days',
                icon: Icons.access_time,
              ),
              const SizedBox(height: 12),
              ...upcomingDeadlines
                  .take(3)
                  .map((d) => _UpcomingDeadlineCard(deadline: d)),
              const SizedBox(height: 24),
            ],
            _SectionHeader(
              title: 'Categories',
              subtitle: 'Browse all deadlines',
              icon: Icons.category,
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: sampleCategories
                  .map((c) => _CategoryCard(category: c))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }
}

class _UpcomingDeadlineCard extends StatelessWidget {
  final Deadline deadline;

  const _UpcomingDeadlineCard({required this.deadline});

  Color get _urgencyColor {
    final days = deadline.daysUntil;
    if (days <= 7) return const Color(0xFFD52B1E);
    if (days <= 30) return const Color(0xFFE65100);
    return const Color(0xFF1B5E20);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _urgencyColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _urgencyColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${deadline.daysUntil}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _urgencyColor,
                    ),
                  ),
                  Text(
                    'days',
                    style: TextStyle(fontSize: 10, color: _urgencyColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deadline.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    deadline.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (deadline.isRecurring)
              Tooltip(
                message: 'Recurring',
                child: Icon(Icons.repeat, size: 16, color: Colors.grey[400]),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final DeadlineCategory category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final upcoming =
        category.deadlines.where((d) => d.isUpcoming).length;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(category.icon, color: category.color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '$upcoming upcoming',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
