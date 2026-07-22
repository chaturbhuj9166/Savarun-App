import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import 'data/wardrobe_models.dart';
import 'data/wardrobe_providers.dart';

/// Item Details — the full AI-tagged record for one wardrobe item, with the
/// design's delete / save actions.
class ItemDetailsScreen extends ConsumerStatefulWidget {
  const ItemDetailsScreen({super.key, required this.item});
  final WardrobeItem item;

  @override
  ConsumerState<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends ConsumerState<ItemDetailsScreen> {
  late String _category = widget.item.category;
  late String _fabric = widget.item.fabric;
  late String _season = widget.item.season;
  late String _formality = widget.item.formality;
  late String _colorHex = widget.item.colorHex;
  bool _busy = false;

  bool get _dirty =>
      _category != widget.item.category ||
      _fabric != widget.item.fabric ||
      _season != widget.item.season ||
      _formality != widget.item.formality ||
      _colorHex != widget.item.colorHex;

  Future<void> _save() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(wardrobeRepoProvider).update(uid, widget.item.id, {
        'category': _category,
        'fabric': _fabric,
        'season': _season,
        'formality': _formality,
        'colorHex': _colorHex,
      });
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${widget.item.name}" from your wardrobe?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await ref.read(wardrobeRepoProvider).delete(uid, widget.item.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Item Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 260,
              width: double.infinity,
              color: item.photoURL == null ? item.color : AppColors.white,
              child: item.photoURL != null
                  ? Image.network(
                      item.photoURL!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.checkroom_rounded,
                        size: 48,
                        color: AppColors.inkMuted,
                      ),
                    )
                  : const Icon(Icons.checkroom_rounded,
                      size: 48, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 24),

          // Colour swatch row, as in the design.
          const Text('Color',
              style: TextStyle(fontSize: 13, color: AppColors.inkMuted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in WardrobeOptions.colors)
                GestureDetector(
                  onTap: () => setState(() => _colorHex = c.hex),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _hexToColor(c.hex),
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
          const SizedBox(height: 28),

          _PickerRow(
            label: 'Category',
            value: _category,
            options: WardrobeOptions.categories,
            onChanged: (v) => setState(() => _category = v),
          ),
          _PickerRow(
            label: 'Fabric',
            value: _fabric,
            options: WardrobeOptions.fabrics,
            onChanged: (v) => setState(() => _fabric = v),
          ),
          _PickerRow(
            label: 'Season',
            value: _season,
            options: WardrobeOptions.seasons,
            onChanged: (v) => setState(() => _season = v),
          ),
          _PickerRow(
            label: 'Formality',
            value: _formality,
            options: WardrobeOptions.formalities,
            onChanged: (v) => setState(() => _formality = v),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              SizedBox(
                width: 56,
                height: 54,
                child: OutlinedButton(
                  onPressed: _busy ? null : _delete,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.danger,
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_busy || !_dirty) ? null : _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    return Color(int.tryParse('FF$clean', radix: 16) ?? 0xFF9E9E9E);
  }
}

/// Label on the left, tappable value on the right — the design's detail rows.
class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () async {
          final picked = await showModalBottomSheet<String>(
            context: context,
            backgroundColor: AppColors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  for (final o in options)
                    ListTile(
                      title: Text(o),
                      trailing: o == value
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.ink)
                          : null,
                      onTap: () => Navigator.pop(ctx, o),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
          if (picked != null) onChanged(picked);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
