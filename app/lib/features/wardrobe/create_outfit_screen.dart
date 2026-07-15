import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import 'data/outfit_models.dart';
import 'data/outfit_providers.dart';
import 'data/wardrobe_models.dart';
import 'data/wardrobe_providers.dart';

class CreateOutfitScreen extends ConsumerStatefulWidget {
  const CreateOutfitScreen({super.key});

  @override
  ConsumerState<CreateOutfitScreen> createState() => _CreateOutfitScreenState();
}

class _CreateOutfitScreenState extends ConsumerState<CreateOutfitScreen> {
  final _nameController = TextEditingController();
  final _selected = <String>{};
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    if (_nameController.text.trim().isEmpty) {
      _toast('Name your outfit set');
      return;
    }
    if (_selected.isEmpty) {
      _toast('Select at least one item');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(outfitRepoProvider).add(
            uid,
            OutfitSet(id: '', name: _nameController.text.trim(), itemIds: _selected.toList()),
          );
      if (!mounted) return;
      _toast('Outfit set saved ✨');
      context.pop();
    } catch (e) {
      _toast('Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(wardrobeProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface, title: const Text('New Outfit Set')),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Outfit name — e.g. Office Monday Look',
                    prefixIcon: Icon(Icons.style_rounded),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Text('Select items  (${_selected.length} chosen)',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.inkMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: itemsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Add items to your wardrobe first,\nthen combine them into outfits.',
                              textAlign: TextAlign.center, style: TextStyle(color: AppColors.inkMuted)),
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        final selected = _selected.contains(item.id);
                        return _SelectableTile(
                          item: item,
                          selected: selected,
                          onTap: () => setState(() {
                            selected ? _selected.remove(item.id) : _selected.add(item.id);
                          }),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Outfit Set'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({required this.item, required this.selected, required this.onTap});
  final WardrobeItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: selected ? AppColors.primary : AppColors.line, width: selected ? 3 : 1),
                    image: item.photoURL != null
                        ? DecorationImage(image: NetworkImage(item.photoURL!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: item.photoURL != null
                      ? null
                      : Icon(Icons.checkroom_rounded,
                          color: item.color.computeLuminance() > 0.6 ? AppColors.inkMuted : Colors.white70),
                ),
                if (selected)
                  const Positioned(
                    right: 6,
                    top: 6,
                    child: CircleAvatar(radius: 12, backgroundColor: AppColors.primary, child: Icon(Icons.check, size: 14, color: Colors.white)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
