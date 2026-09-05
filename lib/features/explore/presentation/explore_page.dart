import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/location_providers.dart';
import '../../../core/location/location_service.dart';
import '../../flash/domain/flash.dart';
import '../../flash/presentation/flash_detail_page.dart';
import '../../flash/presentation/flash_providers.dart';

class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(currentLocationProvider);
    ref.invalidate(nearbyFlashesProvider);
    await ref.read(nearbyFlashesProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(currentLocationProvider);
    final feed = ref.watch(nearbyFlashesProvider);
    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: location.when(
        data: (current) => feed.when(
          data: (result) => _ExploreContent(
            current: current,
            flashes: result.flashes,
            onRefresh: () => _refresh(ref),
          ),
          loading: () => const _Loading(),
          error: (_, __) => _ErrorState(
            message: 'We could not load nearby reports for the map.',
            onRetry: () => _refresh(ref),
          ),
        ),
        loading: () => const _Loading(),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => _refresh(ref),
        ),
      ),
    );
  }
}

class _ExploreContent extends StatelessWidget {
  const _ExploreContent({
    required this.current,
    required this.flashes,
    required this.onRefresh,
  });

  final AppLocation current;
  final List<Flash> flashes;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(current.latitude, current.longitude);
    final markers = <Marker>[
      Marker(
        point: center,
        width: 52,
        height: 52,
        child: const _CurrentMarker(),
      ),
      ...flashes.where((flash) {
        return flash.location?.latitude != null &&
            flash.location?.longitude != null;
      }).map((flash) {
        return Marker(
          point: LatLng(
            flash.location!.latitude!,
            flash.location!.longitude!,
          ),
          width: 52,
          height: 52,
          child: _FlashMarker(flash: flash),
        );
      }),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
      children: [
        Text(
          'Explore what is happening',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'See live community reports around your current location.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Container(
          height: 330,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 13),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.hapa_app',
              ),
              MarkerLayer(markers: markers),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Summary(count: flashes.length, onRefresh: onRefresh),
        const SizedBox(height: 24),
        Text(
          flashes.isEmpty ? 'Nothing pinned nearby' : 'Reports on this map',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (flashes.isEmpty)
          const _EmptyState()
        else
          ...flashes.map(
            (flash) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReportRow(flash: flash),
            ),
          ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.count, required this.onRefresh});
  final int count;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final noun = count == 1 ? 'report' : 'reports';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.my_location_rounded, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              count.toString() + ' nearby ' + noun + ' within your feed radius',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          IconButton(
            tooltip: 'Refresh map',
            onPressed: () => onRefresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _CurrentMarker extends StatelessWidget {
  const _CurrentMarker();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: colors.surface, width: 4),
          boxShadow: const [BoxShadow(blurRadius: 8)],
        ),
      ),
    );
  }
}

class _FlashMarker extends StatelessWidget {
  const _FlashMarker({required this.flash});
  final Flash flash;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(flash.category);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FlashDetailPage(flash: flash)),
      ),
      child: Center(
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.surface,
              width: 3,
            ),
          ),
          child: Icon(
            _categoryIcon(flash.category),
            color: Colors.white,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.flash});
  final Flash flash;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final category = flash.category?.trim().isNotEmpty == true
        ? flash.category!.trim()
        : 'Report';
    final location = flash.location?.label?.trim().isNotEmpty == true
        ? flash.location!.label!.trim()
        : 'Location available on map';

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FlashDetailPage(flash: flash)),
        ),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                _categoryIcon(category),
                color: _categoryColor(category),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category, style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 3),
                    Text(
                      flash.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.radar_rounded,
              size: 46,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Your area is quiet right now',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'New community reports will appear here when they are available near you.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 26,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 330,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.location_off_outlined,
            size: 52,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            'Explore needs your location',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      );
}

IconData _categoryIcon(String? category) {
  switch (category?.toLowerCase()) {
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

Color _categoryColor(String? category) {
  switch (category?.toLowerCase()) {
    case 'traffic':
      return const Color(0xFFB54708);
    case 'security':
      return const Color(0xFF175CD3);
    case 'weather':
      return const Color(0xFF1570EF);
    case 'water':
      return const Color(0xFF027A48);
    case 'power':
      return const Color(0xFF7A5AF8);
    case 'emergency':
      return const Color(0xFFD92D20);
    default:
      return const Color(0xFF475467);
  }
}
