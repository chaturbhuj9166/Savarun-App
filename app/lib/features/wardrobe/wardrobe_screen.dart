import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import 'data/wardrobe_models.dart';
import 'data/wardrobe_providers.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  String _category = 'All';

  static const _filters = ['All', ...WardrobeOptions.categories];

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(wardrobeProvider);

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('My Wardrobe', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  onPressed: () => context.push(Routes.outfitCombos),
                  icon: const Icon(Icons.dashboard_customize_rounded),
                  tooltip: 'Outfit Sets',
                ),
                IconButton(
                  onPressed: () => context.push(Routes.addItem),
                  icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                  tooltip: 'Add Item',
                ),
              ],
            ),
          ),

          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Could not load wardrobe:\n$e', textAlign: TextAlign.center)),
              data: (allItems) {
                if (allItems.isEmpty) return const _EmptyWardrobe();

                final items = _category == 'All'
                    ? allItems
                    : allItems.where((w) => w.category == _category).toList();

                return Column(
                  children: [
                    // Stats
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _StatCard(label: 'Items', value: '${allItems.length}'),
                          const SizedBox(width: 12),
                          _StatCard(label: 'Categories', value: '${allItems.map((e) => e.category).toSet().length}'),
                          const SizedBox(width: 12),
                          _StatCard(label: 'Showing', value: '${items.length}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category filter
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filters.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final cat = _filters[i];
                          final selected = cat == _category;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: selected,
                            onSelected: (_) => setState(() => _category = cat),
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600),
                            backgroundColor: AppColors.surface,
                            side: BorderSide.none,
                          );
                        },
                      ),
                    ),

                    // Grid
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, i) => _WardrobeTile(
                          item: items[i],
                          onDelete: () => _confirmDelete(items[i]),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(WardrobeItem item) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.name}" from your wardrobe?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(wardrobeRepoProvider).delete(uid, item.id);
    }
  }
}

class _EmptyWardrobe extends StatelessWidget {
  const _EmptyWardrobe();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.checkroom_rounded, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text('Your wardrobe is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Add your clothes to build your digital closet.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.inkMuted)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push(Routes.addItem),
              icon: const Icon(Icons.add),
              label: const Text('Add First Item'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.inkMuted)),
          ],
        ),
      ),
    );
  }
}

class _WardrobeTile extends StatelessWidget {
  const _WardrobeTile({required this.item, required this.onDelete});
  final WardrobeItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onDelete,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
                image: item.photoURL != null
                    ? DecorationImage(image: NetworkImage(item.photoURL!), fit: BoxFit.cover)
                    : null,
              ),
              child: item.photoURL != null
                  ? null
                  : Icon(Icons.checkroom_rounded,
                      color: item.color.computeLuminance() > 0.6 ? AppColors.inkMuted : Colors.white70, size: 28),
            ),
          ),
          const SizedBox(height: 6),
          Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Text(item.season, style: const TextStyle(fontSize: 10, color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}
