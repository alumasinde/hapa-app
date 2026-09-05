import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/home/presentation/home_page.dart';
import '../features/explore/presentation/explore_page.dart';
import '../features/activity/presentation/activity_page.dart';
import '../features/flash/presentation/flash_providers.dart';

class HapaNavigationShell extends ConsumerStatefulWidget {
  const HapaNavigationShell({super.key});

  @override
  ConsumerState<HapaNavigationShell> createState() => _HapaNavigationShellState();
}

class _HapaNavigationShellState extends ConsumerState<HapaNavigationShell> {
  int _index = 0;

  static const _titles = ['Hapa', 'Explore', 'Activity', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const ExplorePage(),
      const ActivityPage(),
      const _ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          if (_index == 0)
            IconButton(
              tooltip: 'Refresh nearby reports',
              onPressed: () => ref.invalidate(nearbyFlashesProvider),
              icon: const Icon(Icons.refresh_rounded),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCreateAlert(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Report'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _HapaBottomBar(
        currentIndex: _index,
        onSelected: (index) => setState(() => _index = index),
      ),
    );
  }
}

class _HapaBottomBar extends StatelessWidget {
  const _HapaBottomBar({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget item({
      required int index,
      required IconData icon,
      required IconData activeIcon,
      required String label,
    }) {
      final selected = currentIndex == index;
      return Expanded(
        child: InkWell(
          onTap: () => onSelected(index),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
        child: Row(
          children: [
            item(index: 0, icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Feed'),
            item(index: 1, icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: 'Explore'),
            const SizedBox(width: 84),
            item(index: 2, icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded, label: 'Activity'),
            item(index: 3, icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _ProfilePage extends ConsumerWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final name = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName.trim()
        : '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                child: Text(
                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'H',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isEmpty ? 'Hapa member' : name, style: Theme.of(context).textTheme.titleLarge),
                    if (user?.email?.trim().isNotEmpty == true)
                      Text(user!.email!, style: Theme.of(context).textTheme.bodyMedium)
                    else if (user?.phone?.trim().isNotEmpty == true)
                      Text(user!.phone!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _ProfileSection(icon: Icons.article_outlined, title: 'My reports', subtitle: 'View reports you have shared'),
        const SizedBox(height: 10),
        const _ProfileSection(icon: Icons.settings_outlined, title: 'Account settings', subtitle: 'Profile and security controls'),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      );
}

class _PhaseOnePlaceholder extends StatelessWidget {
  const _PhaseOnePlaceholder({required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45)),
              ],
            ),
          ),
        ),
      );
}
