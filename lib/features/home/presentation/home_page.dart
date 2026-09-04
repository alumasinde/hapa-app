import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/presentation/category_providers.dart';
import '../../modes/presentation/mode_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final modes = ref.watch(modesProvider);

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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(modesProvider);
          await Future.wait([
            ref.read(categoriesProvider.future),
            ref.read(modesProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Text('What is happening near you?',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Discover recent reports and updates around your location.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text('Categories', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            categories.when(
              data: (items) => _CategoryList(items: items),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _LoadError(
                message: 'Could not load categories',
                onRetry: () => ref.invalidate(categoriesProvider),
              ),
            ),
            const SizedBox(height: 24),
            Text('Modes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            modes.when(
              data: (items) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items
                    .map((mode) => Chip(
                          avatar: const Icon(Icons.tune_outlined, size: 18),
                          label: Text(mode.name),
                        ))
                    .toList(),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => _LoadError(
                message: 'Could not load modes',
                onRetry: () => ref.invalidate(modesProvider),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Text('Nearby', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _PreviewFlashCard(
              title: 'Your live reports will appear here',
              location: 'Nearby',
              time: 'Waiting for feed',
              categoryIcon: Icons.location_searching_outlined,
            ),
          ],
        ),
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

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.items});

  final List items;

  IconData _iconFor(String? value) {
    switch (value?.toLowerCase()) {
      case 'traffic':
      case 'car':
        return Icons.directions_car_outlined;
      case 'security':
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'weather':
        return Icons.cloud_outlined;
      case 'fire':
        return Icons.local_fire_department_outlined;
      default:
        return Icons.report_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('No categories are currently available.');
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (category) => ActionChip(
              avatar: Icon(_iconFor(category.icon)),
              label: Text(category.name),
              onPressed: () {},
            ),
          )
          .toList(),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
        IconButton(
          onPressed: onRetry,
          tooltip: 'Retry',
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
                Expanded(child: Text(location, style: TextStyle(color: muted))),
                Icon(Icons.schedule_outlined, size: 17, color: muted),
                const SizedBox(width: 5),
                Text(time, style: TextStyle(color: muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
