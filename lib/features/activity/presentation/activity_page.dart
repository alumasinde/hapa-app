import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_providers.dart';
import '../../flash/domain/flash.dart';
import '../../flash/presentation/flash_detail_page.dart';
import '../../flash/presentation/flash_providers.dart';

class ActivityPage extends ConsumerWidget {
  const ActivityPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(currentLocationProvider);
    ref.invalidate(nearbyFlashesProvider);
    await ref.read(nearbyFlashesProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(nearbyFlashesProvider);

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: feed.when(
        data: (result) {
          final flashes = [...result.flashes]
            ..sort((a, b) {
              final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
            children: [
              Text(
                'Community activity',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Recent reports and changes happening around you.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              _ActivitySummary(count: flashes.length),
              const SizedBox(height: 24),
              if (flashes.isEmpty)
                const _ActivityEmpty()
              else
                ...flashes.map(
                  (flash) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ActivityItem(flash: flash),
                  ),
                ),
            ],
          );
        },
        loading: () => const _ActivityLoading(),
        error: (_, __) => _ActivityError(
          onRetry: () => _refresh(ref),
        ),
      ),
    );
  }
}

class _ActivitySummary extends StatelessWidget {
  const _ActivitySummary({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.notifications_active_outlined, color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString() + ' nearby updates',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                const Text(
                  'Pull down to refresh the latest activity.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.flash});
  final Flash flash;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final time = _relativeTime(flash.createdAt);
    final category = flash.category?.trim().isNotEmpty == true
        ? flash.category!.trim()
        : 'Community report';
    final location = flash.location?.label?.trim().isNotEmpty == true
        ? flash.location!.label!.trim()
        : 'Nearby area';

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FlashDetailPage(flash: flash)),
        ),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _categoryIcon(category),
                  color: colors.primary,
                ),
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
                            category,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        Text(
                          time,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      flash.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (flash.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        flash.description!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityEmpty extends StatelessWidget {
  const _ActivityEmpty();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 50,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'No activity yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'When reports are shared near you, the latest activity will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

class _ActivityLoading extends StatelessWidget {
  const _ActivityLoading();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 100),
          Center(child: CircularProgressIndicator()),
        ],
      );
}

class _ActivityError extends StatelessWidget {
  const _ActivityError({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.cloud_off_outlined,
            size: 52,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            'Could not load activity',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      );
}

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'traffic':
      return Icons.traffic_outlined;
    case 'security':
      return Icons.shield_outlined;
    case 'weather':
      return Icons.cloud_outlined;
    case 'water':
      return Icons.water_drop_outlined;
    case 'power':
      return Icons.bolt_outlined;
    case 'emergency':
      return Icons.emergency_outlined;
    default:
      return Icons.report_problem_outlined;
  }
}

String _relativeTime(DateTime? value) {
  if (value == null) return 'Recent';
  final difference = DateTime.now().difference(value.toLocal());
  if (difference.isNegative || difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return difference.inMinutes.toString() + 'm ago';
  if (difference.inHours < 24) return difference.inHours.toString() + 'h ago';
  if (difference.inDays < 7) return difference.inDays.toString() + 'd ago';
  return value.day.toString() + '/' + value.month.toString();
}
