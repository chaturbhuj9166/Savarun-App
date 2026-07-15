import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import 'data/outfit_models.dart';
import 'data/outfit_providers.dart';
import 'data/wardrobe_models.dart';
import 'data/wardrobe_providers.dart';

class OutfitCombosScreen extends ConsumerWidget {
  const OutfitCombosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfitsAsync = ref.watch(outfitsProvider);
    final itemsAsync = ref.watch(wardrobeProvider);
    final itemsById = {for (final it in (itemsAsync.value ?? const <WardrobeItem>[])) it.id: it};

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface, title: const Text('Outfit Sets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.createOutfit),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Set', style: TextStyle(color: Colors.white)),
      ),
      body: outfitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load outfit sets:\n$e', textAlign: TextAlign.center)),
        data: (outfits) {
          if (outfits.isEmpty) return const _EmptyOutfits();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
            itemCount: outfits.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final outfit = outfits[i];
              final items = outfit.itemIds.map((id) => itemsById[id]).whereType<WardrobeItem>().toList();
              return _OutfitSetCard(
                outfit: outfit,
                items: items,
                onDelete: () => _confirmDelete(context, ref, outfit),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, OutfitSet outfit) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete outfit set?'),
        content: Text('Remove "${outfit.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) await ref.read(outfitRepoProvider).delete(uid, outfit.id);
  }
}

class _EmptyOutfits extends StatelessWidget {
  const _EmptyOutfits();

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
              child: const Icon(Icons.dashboard_customize_rounded, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text('No outfit sets yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Combine items from your wardrobe into named outfits.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.inkMuted)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push(Routes.createOutfit),
              icon: const Icon(Icons.add),
              label: const Text('Create First Set'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutfitSetCard extends StatelessWidget {
  const _OutfitSetCard({required this.outfit, required this.items, required this.onDelete});
  final OutfitSet outfit;
  final List<WardrobeItem> items;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.style_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(outfit.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              Text('${items.length} items', style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.inkMuted, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final item = items[i];
                return Container(
                  width: 60,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                    image: item.photoURL != null
                        ? DecorationImage(image: NetworkImage(item.photoURL!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: item.photoURL != null
                      ? null
                      : Icon(Icons.checkroom_rounded,
                          color: item.color.computeLuminance() > 0.6 ? AppColors.inkMuted : Colors.white70, size: 20),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
