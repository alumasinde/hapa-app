import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../categories/domain/category.dart';
import '../../categories/presentation/category_providers.dart';
import '../../engagement/data/engagement_repository.dart';
import '../../flash/data/flash_repository.dart';
import '../../flash/domain/flash.dart';
import '../../flash/presentation/flash_detail_page.dart';
import '../../flash/presentation/flash_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(nearbyFlashesProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hapa'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(nearbyFlashesProvider);
          await ref.read(nearbyFlashesProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Text(
              'What is happening near you?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover recent reports and updates around your location.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Text(
                  'Nearby',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh nearby reports',
                  onPressed: () => ref.invalidate(nearbyFlashesProvider),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            feed.when(
              data: (result) {
                if (result.flashes.isEmpty) {
                  return _EmptyFeed(categories: categories);
                }

                return Column(
                  children: result.flashes
                      .map(
                        (flash) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _FlashCard(flash: flash),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => _FeedError(
                onRetry: () => ref.invalidate(nearbyFlashesProvider),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => _showCreateAlert(context, ref),
        tooltip: 'Create alert',
        child: const Icon(Icons.add_rounded, size: 32),
      ),
    );
  }
}

class _FlashCard extends ConsumerStatefulWidget {
  const _FlashCard({required this.flash});
  final Flash flash;

  @override
  ConsumerState<_FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends ConsumerState<_FlashCard> {
  late Flash _flash = widget.flash;
  bool _busy = false;

  Future<void> _toggleHelpful() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final repository = EngagementRepository(ref.read(apiClientProvider));
      final result = _flash.engagement.markedHelpful
          ? await repository.removeHelpful(_flash.id)
          : await repository.markHelpful(_flash.id);

      if (!mounted) return;
      final engagement = EngagementStatistics.fromJson(result.engagement);
      setState(() => _flash = _flash.copyWith(engagement: engagement));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update Helpful right now.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final location = _flash.location?.label;
      final message = [
        'Hapa alert: ${_flash.title}',
        if (_flash.description != null && _flash.description!.trim().isNotEmpty)
          _flash.description!.trim(),
        if (location != null && location.trim().isNotEmpty)
          'Location: ${location.trim()}',
      ].join('\n');

      await Share.share(message, subject: _flash.title);

      final result = await EngagementRepository(ref.read(apiClientProvider))
          .recordShare(_flash.id);
      if (!mounted) return;
      setState(() {
        _flash = _flash.copyWith(
          engagement: EngagementStatistics.fromJson(result.engagement),
        );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share this report.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FlashDetailPage(flash: _flash)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final category = _flash.category?.trim();
    final location = _flash.location?.label?.trim();
    final distance = _flash.distanceKm;
    final status = _flash.status == null ? null : _flash.status!.replaceAll('_', ' ');

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: _openDetails,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.report_problem_outlined,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (category != null && category.isNotEmpty)
                            Text(
                              category,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const SizedBox(height: 3),
                          Text(
                            _flash.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Open report',
                      onPressed: _openDetails,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                if (_flash.description != null &&
                    _flash.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    _flash.description!.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    if (location != null && location.isNotEmpty)
                      _MetaItem(
                        icon: Icons.location_on_outlined,
                        label: location,
                      ),
                    if (distance != null)
                      _MetaItem(
                        icon: Icons.near_me_outlined,
                        label: '${distance.toStringAsFixed(1)} km',
                      ),
                    if (status != null)
                      _MetaItem(
                        icon: Icons.access_time_rounded,
                        label: status,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _busy ? null : _toggleHelpful,
                        icon: Icon(
                          _flash.engagement.markedHelpful
                              ? Icons.thumb_up_rounded
                              : Icons.thumb_up_outlined,
                        ),
                        label: Text('${_flash.engagement.helpful} Helpful'),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _busy ? null : _share,
                        icon: const Icon(Icons.share_outlined),
                        label: Text('${_flash.engagement.shares} Share'),
                      ),
                    ),
                    Expanded(
                      child: _MetaItem(
                        icon: Icons.visibility_outlined,
                        label: '${_flash.engagement.views} Views',
                        center: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    this.center = false,
  });

  final IconData icon;
  final String label;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Align(
      alignment: center ? Alignment.center : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.categories});
  final AsyncValue<List<Category>> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52),
      child: Column(
        children: [
          Icon(Icons.near_me_outlined, size: 42, color: theme.colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            'Nothing nearby yet',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Be the first person to report what is happening around you.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40),
          const SizedBox(height: 12),
          const Text('Could not load nearby reports.'),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

Future<void> _showCreateAlert(BuildContext context, WidgetRef ref) async {
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const CreateAlertPage()),
  );
  ref.invalidate(nearbyFlashesProvider);
}

class CreateAlertPage extends ConsumerStatefulWidget {
  const CreateAlertPage({super.key});

  @override
  ConsumerState<CreateAlertPage> createState() => _CreateAlertPageState();
}

class _CreateAlertPageState extends ConsumerState<CreateAlertPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _areaController = TextEditingController();

  String? _category;
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;

    setState(() => _submitting = true);
    try {
      await ref.read(flashRepositoryProvider).create(
            category: _category!,
            description: _descriptionController.text.trim(),
            areaName: _areaController.text.trim().isEmpty
                ? null
                : _areaController.text.trim(),
            latitude: -1.286389,
            longitude: 36.817223,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert created successfully.')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create the alert. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create alert')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'What is happening?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share a clear report so people nearby can act on it.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              categories.when(
                data: (items) => DropdownButtonFormField<String>(
                  value: _category,
                  items: items
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.key,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _category = value),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  validator: (value) => value == null ? 'Select a category' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Could not load categories.'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Describe what is happening';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Area name (optional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_submitting ? 'Posting…' : 'Post alert'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
