import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../categories/presentation/category_providers.dart';
import '../../modes/presentation/mode_providers.dart';
import '../../flash/presentation/flash_providers.dart';
import '../../flash/presentation/flash_detail_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final modes = ref.watch(modesProvider);
    final flashes = ref.watch(nearbyFlashesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hapa'), actions: [IconButton(onPressed: () => ref.invalidate(nearbyFlashesProvider), icon: const Icon(Icons.refresh_outlined))]),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider); ref.invalidate(modesProvider); ref.invalidate(nearbyFlashesProvider);
          await Future.wait([ref.read(categoriesProvider.future), ref.read(modesProvider.future), ref.read(nearbyFlashesProvider.future)]);
        },
        child: ListView(padding: const EdgeInsets.fromLTRB(20,12,20,100), children: [
          Text('What is happening near you?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8), const Text('Recent community reports and updates around you.'),
          const SizedBox(height: 24), Text('Categories', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12),
          categories.when(data: (items) => Wrap(spacing: 8, runSpacing: 8, children: items.map((item) => Chip(avatar: const Icon(Icons.category_outlined, size: 18), label: Text(item.name))).toList()), loading: () => const LinearProgressIndicator(), error: (_, __) => const Text('Could not load categories.')),
          const SizedBox(height: 24), Text('Modes', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12),
          modes.when(data: (items) => Wrap(spacing: 8, runSpacing: 8, children: items.map((item) => Chip(avatar: const Icon(Icons.tune_outlined, size: 18), label: Text(item.name))).toList()), loading: () => const LinearProgressIndicator(), error: (_, __) => const Text('Could not load modes.')),
          const SizedBox(height: 28), Text('Nearby reports', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 12),
          flashes.when(
            data: (items) {
              if (items.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: Text('No nearby reports yet.')));
              return Column(children: items.map((flash) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FlashDetailPage(flash: flash))),
                  child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(flash.title, style: Theme.of(context).textTheme.titleMedium),
                    if (flash.description != null) ...[const SizedBox(height: 8), Text(flash.description!, maxLines: 2, overflow: TextOverflow.ellipsis)],
                    const SizedBox(height: 12),
                    Wrap(spacing: 16, runSpacing: 8, children: [
                      if (flash.location?.label != null) Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.location_on_outlined, size: 17), const SizedBox(width: 4), Text(flash.location!.label!)]),
                      Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.thumb_up_outlined, size: 17), const SizedBox(width: 4), Text(flash.engagement.helpful.toString())]),
                      Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.share_outlined, size: 17), const SizedBox(width: 4), Text(flash.engagement.shares.toString())]),
                    ]),
                  ])),
                )),
              )).toList());
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (_, __) => Center(child: Column(children: [const Text('Could not load nearby reports.'), TextButton.icon(onPressed: () => ref.invalidate(nearbyFlashesProvider), icon: const Icon(Icons.refresh_outlined), label: const Text('Retry'))])),
          ),
        ]),
      ),
    );
  }
}
