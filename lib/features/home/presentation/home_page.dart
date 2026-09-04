import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text('Hapa'),
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Text(
            'What is happening near you?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Discover recent reports and updates around your location.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          const _SectionHeader(),
          const SizedBox(height: 12),
          const _PreviewFlashCard(
            title: 'Traffic building up',
            location: 'Nearby',
            time: 'Recent',
            categoryIcon: Icons.directions_car_outlined,
          ),
          const SizedBox(height: 12),
          const _PreviewFlashCard(
            title: 'A new report will appear here',
            location: 'Your area',
            time: 'Live updates',
            categoryIcon: Icons.report_outlined,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Create report',
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Nearby', style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        IconButton(
          onPressed: () {},
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_outlined),
        ),
      ],
    );
  }
}

class _PreviewFlashCard extends StatelessWidget {
  const _PreviewFlashCard({
    required this.title,
    required this.location,
    required this.time,
    required this.categoryIcon,
  });

  final String title;
  final String location;
  final String time;
  final IconData categoryIcon;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(categoryIcon),
              const SizedBox(height: 14),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 17, color: muted),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(location, style: TextStyle(color: muted)),
                  ),
                  Icon(Icons.schedule_outlined, size: 17, color: muted),
                  const SizedBox(width: 5),
                  Text(time, style: TextStyle(color: muted)),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _Metric(icon: Icons.thumb_up_outlined, label: 'Helpful'),
                  const SizedBox(width: 20),
                  _Metric(icon: Icons.share_outlined, label: 'Share'),
                  const SizedBox(width: 20),
                  _Metric(icon: Icons.visibility_outlined, label: 'Views'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
