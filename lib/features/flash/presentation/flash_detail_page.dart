import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/presentation/category_providers.dart';
import '../../engagement/data/engagement_repository.dart';
import '../domain/flash.dart';

class FlashDetailPage extends ConsumerStatefulWidget {
  const FlashDetailPage({super.key, required this.flash});
  final Flash flash;

  @override
  ConsumerState<FlashDetailPage> createState() => _FlashDetailPageState();
}

class _FlashDetailPageState extends ConsumerState<FlashDetailPage> {
  bool _helpful = false;
  bool _busy = false;

  Future<void> _react({required bool share}) async {
    setState(() => _busy = true);
    try {
      final repository = EngagementRepository(ref.read(apiClientProvider));
      if (share) {
        await repository.recordShare(widget.flash.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Share engagement recorded.')),
          );
        }
      } else {
        if (_helpful) {
          await repository.removeHelpful(widget.flash.id);
        } else {
          await repository.markHelpful(widget.flash.id);
        }
        if (mounted) setState(() => _helpful = !_helpful);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action could not be completed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flash = widget.flash;
    return Scaffold(
      appBar: AppBar(title: const Text('Report')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            flash.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (flash.category != null) ...[
            const SizedBox(height: 10),
            Chip(label: Text(flash.category!)),
          ],
          if (flash.description != null) ...[
            const SizedBox(height: 18),
            Text(flash.description!),
          ],
          if (flash.location?.label != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.location_on_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(flash.location!.label!)),
              ],
            ),
          ],
          const SizedBox(height: 28),
          Row(
            children: [
              _Stat(icon: Icons.thumb_up_outlined, value: flash.engagement.helpful.toString()),
              _Stat(icon: Icons.share_outlined, value: flash.engagement.shares.toString()),
              _Stat(icon: Icons.visibility_outlined, value: flash.engagement.views.toString()),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _react(share: false),
                  icon: Icon(_helpful ? Icons.thumb_up : Icons.thumb_up_outlined),
                  label: Text(_helpful ? 'Helpful' : 'Helpful'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _react(share: true),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 6),
            Text(value),
          ],
        ),
      );
}
