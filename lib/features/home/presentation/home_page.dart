import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/location/location_providers.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_providers.dart';
import '../../engagement/data/engagement_repository.dart';
import '../../flash/domain/flash.dart';
import '../../flash/presentation/flash_detail_page.dart';
import '../../flash/presentation/flash_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(currentLocationProvider);
    ref.invalidate(nearbyFlashesProvider);
    await ref.read(nearbyFlashesProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(nearbyFlashesProvider);
    final location = ref.watch(currentLocationProvider);
    final categories = ref.watch(categoriesProvider);

    return RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
          children: [
            _HeroHeader(location: location, onRefresh: () => _refresh(ref)),
            const SizedBox(height: 26),
            Row(
              children: [
                Text('Nearby reports', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                feed.when(
                  data: (result) => _CountBadge(count: result.flashes.length),
                  loading: () => const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            feed.when(
              data: (result) {
                if (result.flashes.isEmpty) return _EmptyFeed(categories: categories);
                return Column(
                  children: result.flashes.map(
                    (flash) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _FlashCard(key: ValueKey(flash.id), flash: flash),
                    ),
                  ).toList(),
                );
              },
              loading: () => const _FeedLoading(),
              error: (error, _) => _FeedError(
                message: error is LocationException
                    ? error.message
                    : 'We could not load reports near your current location.',
                onRetry: () => _refresh(ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.location, required this.onRefresh});
  final AsyncValue<AppLocation> location;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What is happening\nnear you?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(height: 1.12)),
          const SizedBox(height: 10),
          Text(
            'Live reports based on your phone\'s current location.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 18),
          location.when(
            data: (_) => _LocationPill(
              label: 'Using your current location',
              detail: 'Nearby within 10 km',
              onRefresh: onRefresh,
            ),
            loading: () => const _LocationPill(
              label: 'Finding your location…',
              detail: 'Allow location access to see nearby reports',
            ),
            error: (_, __) => _LocationPill(
              label: 'Location needed',
              detail: 'Tap refresh after allowing location access',
              onRefresh: onRefresh,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.label, required this.detail, this.onRefresh});
  final String label;
  final String detail;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.my_location_rounded, size: 19, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 1),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              tooltip: 'Refresh location',
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final noun = count == 1 ? 'report' : 'reports';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count.toString() + ' ' + noun,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FlashCard extends ConsumerStatefulWidget {
  const _FlashCard({super.key, required this.flash});
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
      setState(() {
        _flash = _flash.copyWith(
          engagement: EngagementStatistics.fromJson(result.engagement),
        );
      });
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
        'Hapa alert: ' + _flash.title,
        if (_flash.description?.trim().isNotEmpty == true) _flash.description!.trim(),
        if (location?.trim().isNotEmpty == true) 'Location: ' + location!.trim(),
      ].join('\n');

      await Share.share(message, subject: _flash.title);
      final result = await EngagementRepository(ref.read(apiClientProvider)).recordShare(_flash.id);
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
    final status = _flash.status?.replaceAll('_', ' ');
    final accent = _categoryColor(category);
    final icon = _categoryIcon(category);
    final repeatsTitle = _flash.description?.trim() == _flash.title.trim();

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _openDetails,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icon, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (category?.isNotEmpty == true)
                                Expanded(
                                  child: Text(
                                    category!,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: accent,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              Text(
                                _relativeTime(_flash.createdAt),
                                style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _flash.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
                          ),
                          if (_flash.reporterName?.trim().isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Reported by ' + _flash.reporterName!.trim(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                if (_flash.description?.trim().isNotEmpty == true && !repeatsTitle) ...[
                  const SizedBox(height: 14),
                  Text(
                    _flash.description!.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (location?.isNotEmpty == true)
                      _InfoChip(icon: Icons.location_on_outlined, label: location!),
                    if (_flash.distanceKm != null)
                      _InfoChip(
                        icon: Icons.near_me_outlined,
                        label: _flash.distanceKm!.toStringAsFixed(1) + ' km away',
                      ),
                    if (status?.isNotEmpty == true)
                      _InfoChip(icon: Icons.bolt_outlined, label: status!),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: colors.outlineVariant, height: 1),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: _flash.engagement.markedHelpful ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                        label: _flash.engagement.helpful.toString(),
                        active: _flash.engagement.markedHelpful,
                        onPressed: _busy ? null : _toggleHelpful,
                      ),
                    ),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.share_outlined,
                        label: _flash.engagement.shares.toString(),
                        onPressed: _busy ? null : _share,
                      ),
                    ),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.visibility_outlined,
                        label: _flash.engagement.views.toString(),
                        onPressed: null,
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: active ? colors.primary : colors.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          height: 210,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 42),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.radar_rounded, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('Nothing nearby yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'No reports were found around your current location. Be the first to report something useful.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          const Icon(Icons.location_searching_rounded, size: 42),
          const SizedBox(height: 14),
          Text('Could not load nearby reports', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 18),
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

Future<void> showCreateAlert(BuildContext context, WidgetRef ref) async {
  final created = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const CreateAlertPage()),
  );
  if (created == true) ref.invalidate(nearbyFlashesProvider);
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
  AppLocation? _location;
  String? _locationError;
  bool _submitting = false;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      final value = await ref.read(locationServiceProvider).getCurrentLocation();
      if (!mounted) return;
      setState(() => _location = value);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationError = error is LocationException
            ? error.message
            : 'Could not get your location.';
      });
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use your current location before posting this report.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(flashRepositoryProvider).create(
        category: _category!,
        description: _descriptionController.text.trim(),
        areaName: _areaController.text.trim().isEmpty
            ? 'Current location'
            : _areaController.text.trim(),
        latitude: _location!.latitude,
        longitude: _location!.longitude,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert created successfully.')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      final message = error.code == 'DUPLICATE_FLASH'
          ? 'A matching report was already posted nearby. We did not create another one.'
          : error.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('New report')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text('Share what is happening', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Your report is shown to people nearby based on the location you choose below.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.my_location_rounded, color: colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _loadingLocation
                          ? const Text('Finding your current location…')
                          : _location != null
                              ? const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Current location ready', style: TextStyle(fontWeight: FontWeight.w800)),
                                    SizedBox(height: 3),
                                    Text('This location will be used for nearby matching.'),
                                  ],
                                )
                              : Text(_locationError ?? 'Location unavailable'),
                    ),
                    TextButton(
                      onPressed: _loadingLocation ? null : _loadLocation,
                      child: const Text('Update'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              categories.when(
                data: (items) => DropdownButtonFormField<String>(
                  initialValue: _category,
                  items: items.map(
                    (item) => DropdownMenuItem<String>(
                      value: item.key,
                      child: Text(item.name),
                    ),
                  ).toList(),
                  onChanged: _submitting ? null : (value) => setState(() => _category = value),
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
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'What is happening?',
                  hintText: 'Describe the situation clearly so people nearby understand it.',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Describe what is happening';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Area or landmark (optional)',
                  hintText: 'For example, Nairobi CBD or Tom Mboya Street',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submitting || _loadingLocation ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_submitting ? 'Posting…' : 'Post report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _categoryIcon(String? category) {
  switch (category?.toLowerCase()) {
    case 'traffic':
      return Icons.traffic_outlined;
    case 'security':
      return Icons.shield_outlined;
    case 'weather':
      return Icons.cloud_outlined;
    case 'emergency':
      return Icons.emergency_outlined;
    default:
      return Icons.report_problem_outlined;
  }
}

Color _categoryColor(String? category) {
  switch (category?.toLowerCase()) {
    case 'traffic':
      return const Color(0xFFB54708);
    case 'security':
      return const Color(0xFF175CD3);
    case 'weather':
      return const Color(0xFF1570EF);
    case 'emergency':
      return const Color(0xFFD92D20);
    default:
      return const Color(0xFF475467);
  }
}

String _relativeTime(DateTime? value) {
  if (value == null) return 'Recent';
  final difference = DateTime.now().difference(value.toLocal());
  if (difference.isNegative || difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return difference.inMinutes.toString() + 'm ago';
  if (difference.inHours < 24) return difference.inHours.toString() + 'h ago';
  if (difference.inDays < 7) return difference.inDays.toString() + 'd ago';
  return value.day.toString() + '/' + value.month.toString() + '/' + value.year.toString();
}
