import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/upload_service.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import 'data/autotag_service.dart';
import 'data/wardrobe_models.dart';
import 'data/wardrobe_providers.dart';

/// Add Item to Wardrobe. Pick a photo and let AI auto-tag it (Module 2), or
/// fill the fields by hand. Bulk upload is available from the top action.
class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _nameController = TextEditingController();

  String _category = WardrobeOptions.categories.first;
  String _fabric = WardrobeOptions.fabrics.first;
  String _season = WardrobeOptions.seasons.last;
  String _formality = WardrobeOptions.formalities.first;
  String _colorHex = WardrobeOptions.colors.first.hex;

  XFile? _pickedFile;
  Uint8List? _preview;
  bool _saving = false;
  bool _tagging = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ref.read(uploadServiceProvider).pickFromGallery();
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedFile = file;
      _preview = bytes;
    });
    // Auto-tag straight away — the whole point of the feature.
    _autoTag();
  }

  Future<void> _autoTag() async {
    if (_pickedFile == null) return;
    setState(() => _tagging = true);
    try {
      final tags = await ref.read(autotagServiceProvider).tag(_pickedFile!);
      if (!mounted) return;
      setState(() {
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = tags.name;
        }
        _category = _match(tags.category, WardrobeOptions.categories, _category);
        _fabric = _match(tags.fabric, WardrobeOptions.fabrics, _fabric);
        _season = _match(tags.season, WardrobeOptions.seasons, _season);
        _formality =
            _match(tags.formality, WardrobeOptions.formalities, _formality);
        _colorHex = _nearestSwatch(tags.colorHex);
      });
      _toast('Tagged with AI ✨ — tweak anything if needed');
    } catch (e) {
      _toast('Could not auto-tag: fill the fields manually');
    } finally {
      if (mounted) setState(() => _tagging = false);
    }
  }

  /// Match a free-text AI value to one of the allowed options (case-insensitive).
  String _match(String value, List<String> options, String fallback) {
    final v = value.trim().toLowerCase();
    for (final o in options) {
      if (o.toLowerCase() == v) return o;
    }
    return fallback;
  }

  /// Snap an arbitrary AI hex to the closest preset swatch.
  String _nearestSwatch(String hex) {
    final target = _rgb(hex);
    String best = WardrobeOptions.colors.first.hex;
    double bestDist = double.infinity;
    for (final c in WardrobeOptions.colors) {
      final rgb = _rgb(c.hex);
      final d = _dist(target, rgb);
      if (d < bestDist) {
        bestDist = d;
        best = c.hex;
      }
    }
    return best;
  }

  List<int> _rgb(String hex) {
    final h = hex.replaceFirst('#', '').padRight(6, '0');
    return [
      int.tryParse(h.substring(0, 2), radix: 16) ?? 0,
      int.tryParse(h.substring(2, 4), radix: 16) ?? 0,
      int.tryParse(h.substring(4, 6), radix: 16) ?? 0,
    ];
  }

  double _dist(List<int> a, List<int> b) {
    final dr = a[0] - b[0], dg = a[1] - b[1], db = a[2] - b[2];
    return (dr * dr + dg * dg + db * db).toDouble();
  }

  Future<void> _save() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) {
      _toast('Not signed in');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _toast('Give the item a name');
      return;
    }

    setState(() => _saving = true);
    try {
      String? photoURL;
      if (_pickedFile != null) {
        photoURL =
            await ref.read(uploadServiceProvider).uploadImage(_pickedFile!);
      }

      final item = WardrobeItem(
        id: '',
        name: _nameController.text.trim(),
        category: _category,
        colorHex: _colorHex,
        fabric: _fabric,
        season: _season,
        formality: _formality,
        photoURL: photoURL,
      );
      await ref.read(wardrobeRepoProvider).add(uid, item);

      if (!mounted) return;
      _toast('Added to wardrobe ✨');
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
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Add New Item'),
        actions: [
          TextButton.icon(
            onPressed: () => context.pushReplacement(Routes.bulkAdd),
            icon: const Icon(Icons.burst_mode_outlined, size: 18),
            label: const Text('Bulk'),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    image: _preview != null
                        ? DecorationImage(
                            image: MemoryImage(_preview!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _preview != null
                      ? null
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded,
                                size: 40, color: AppColors.inkMuted),
                            SizedBox(height: 10),
                            Text('Take a Photo',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink)),
                            SizedBox(height: 2),
                            Text('or upload from gallery',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.inkMuted)),
                          ],
                        ),
                ),
              ),
              if (_preview != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _tagging ? null : _autoTag,
                  icon: _tagging
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(_tagging ? 'Tagging…' : 'Re-tag with AI'),
                ),
              ],
              const SizedBox(height: 24),

              _label('Name'),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration:
                    const InputDecoration(hintText: 'e.g. Black Oversized Hoodie'),
              ),
              const SizedBox(height: 18),

              _label('Category'),
              _dropdown(_category, WardrobeOptions.categories,
                  (v) => setState(() => _category = v)),
              const SizedBox(height: 18),

              _label('Color'),
              _colorPicker(),
              const SizedBox(height: 18),

              _label('Fabric'),
              _dropdown(_fabric, WardrobeOptions.fabrics,
                  (v) => setState(() => _fabric = v)),
              const SizedBox(height: 18),

              _label('Season'),
              _dropdown(_season, WardrobeOptions.seasons,
                  (v) => setState(() => _season = v)),
              const SizedBox(height: 18),

              _label('Formality'),
              _dropdown(_formality, WardrobeOptions.formalities,
                  (v) => setState(() => _formality = v)),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: const Text('Add Item'),
              ),
            ],
          ),
          if (_saving)
            const ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.inkMuted,
                fontSize: 13)),
      );

  Widget _dropdown(
      String value, List<String> items, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => v == null ? null : onChanged(v),
        ),
      ),
    );
  }

  Widget _colorPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: WardrobeOptions.colors.map((c) {
        final selected = c.hex == _colorHex;
        final color =
            Color(int.parse('FF${c.hex.replaceFirst('#', '')}', radix: 16));
        return GestureDetector(
          onTap: () => setState(() => _colorHex = c.hex),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.ink : AppColors.line,
                width: selected ? 3 : 1,
              ),
            ),
            child: selected
                ? Icon(Icons.check_rounded,
                    size: 18,
                    color: color.computeLuminance() > 0.6
                        ? Colors.black54
                        : Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
