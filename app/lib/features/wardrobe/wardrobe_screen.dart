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
  String _query = '';

  // Optional filters (null = any). Set from the filter sheet.
  String? _season;
  String? _formality;
  String? _colorHex;

  static const _filters = ['All', ...WardrobeOptions.categories];

  int get _activeFilterCount =>
      (_season != null ? 1 : 0) +
      (_formality != null ? 1 : 0) +
      (_colorHex != null ? 1 : 0);

  /// Apply the current search + filters to the full list.
  List<WardrobeItem> _apply(List<WardrobeItem> all) {
    return all.where((w) {
      if (_category != 'All' && w.category != _category) return false;
      if (_season != null && w.season != _season) return false;
      if (_formality != null && w.formality != _formality) return false;
      if (_colorHex != null && w.colorHex != _colorHex) return false;
      if (_query.isNotEmpty) {
        final hay =
            '${w.name} ${w.category} ${w.fabric} ${w.season} ${w.formality}'
                .toLowerCase();
        if (!hay.contains(_query)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Widget section(String title, List<String> options, String? selected,
              ValueChanged<String?> onPick) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.inkMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final o in options)
                      ChoiceChip(
                        label: Text(o),
                        selected: selected == o,
                        showCheckmark: false,
                        onSelected: (_) {
                          setSheet(() => onPick(selected == o ? null : o));
                          setState(() {});
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Filters',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    TextButton(
                      onPressed: () {
                        setSheet(() {});
                        setState(() {
                          _season = null;
                          _formality = null;
                          _colorHex = null;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                section('Season', WardrobeOptions.seasons, _season,
                    (v) => _season = v),
                section('Formality', WardrobeOptions.formalities, _formality,
                    (v) => _formality = v),
                const Text('Color',
                    style: TextStyle(fontSize: 13, color: AppColors.inkMuted)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final c in WardrobeOptions.colors)
                      GestureDetector(
                        onTap: () {
                          setSheet(() {});
                          setState(() =>
                              _colorHex = _colorHex == c.hex ? null : c.hex);
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _hex(c.hex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _colorHex == c.hex
                                  ? AppColors.ink
                                  : AppColors.line,
                              width: _colorHex == c.hex ? 2.5 : 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Show results'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Color _hex(String hex) =>
      Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(wardrobeProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 12, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text('My Wardrobe',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  onPressed: () => context.push(Routes.wardrobeAnalytics),
                  icon: const Icon(Icons.insights_rounded),
                  tooltip: 'Wardrobe Analytics',
                ),
                IconButton(
                  onPressed: () => context.push(Routes.outfitCombos),
                  icon: const Icon(Icons.dashboard_customize_rounded),
                  tooltip: 'Outfit Sets',
                ),
                IconButton(
                  onPressed: () => context.push(Routes.addItem),
                  icon: const Icon(Icons.add_circle_rounded,
                      color: AppColors.ink),
                  tooltip: 'Add Item',
                ),
              ],
            ),
          ),
          Expanded(
            child: itemsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('Could not load wardrobe:\n$e',
                      textAlign: TextAlign.center)),
              data: (allItems) {
                if (allItems.isEmpty) return const _EmptyWardrobe();

                final items = _apply(allItems);

                return Column(
                  children: [
                    // Search + filter row.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (v) => setState(
                                  () => _query = v.trim().toLowerCase()),
                              decoration: const InputDecoration(
                                hintText: 'Search by name, color, category',
                                prefixIcon: Icon(Icons.search_rounded,
                                    size: 20, color: AppColors.inkMuted),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _FilterButton(
                            count: _activeFilterCount,
                            onTap: _openFilterSheet,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category chips.
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _filters.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final cat = _filters[i];
                          return ChoiceChip(
                            label: Text(cat),
                            selected: cat == _category,
                            showCheckmark: false,
                            onSelected: (_) =>
                                setState(() => _category = cat),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    Expanded(
                      child: items.isEmpty
                          ? const Center(
                              child: Text('No items match your filters.',
                                  style:
                                      TextStyle(color: AppColors.inkMuted)),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(24),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.72,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, i) => _WardrobeTile(
                                item: items[i],
                                onTap: () => context.push(
                                    Routes.itemDetails,
                                    extra: items[i]),
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
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(wardrobeRepoProvider).delete(uid, item.id);
    }
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        width: 54,
        decoration: BoxDecoration(
          color: active ? AppColors.ink : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? AppColors.ink : AppColors.line),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.tune_rounded,
                color: active ? AppColors.white : AppColors.ink, size: 22),
            if (active)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: Center(
                    child: Text('$count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                  color: AppColors.white, shape: BoxShape.circle),
              child: const Icon(Icons.checkroom_rounded,
                  size: 38, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 20),
            const Text('Your wardrobe is empty',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Add your clothes to build your digital closet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkMuted)),
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

class _WardrobeTile extends StatelessWidget {
  const _WardrobeTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });
  final WardrobeItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                image: item.photoURL != null
                    ? DecorationImage(
                        image: NetworkImage(item.photoURL!),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: item.photoURL != null
                  ? null
                  : Icon(Icons.checkroom_rounded,
                      color: item.color.computeLuminance() > 0.6
                          ? AppColors.inkMuted
                          : Colors.white70,
                      size: 28),
            ),
          ),
          const SizedBox(height: 6),
          Text(item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
          Text(item.season,
              style:
                  const TextStyle(fontSize: 10, color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}
