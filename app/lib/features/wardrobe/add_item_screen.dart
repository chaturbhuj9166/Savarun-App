import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/upload_service.dart';
import '../../core/theme/app_colors.dart';
import 'data/wardrobe_models.dart';
import 'data/wardrobe_providers.dart';

/// Real "Add Item to Wardrobe" form.
/// (AI auto-tagging comes later when the OpenAI key is available; for now the
/// user fills the fields manually.)
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
      // Upload the photo first (optional).
      String? photoURL;
      if (_pickedFile != null) {
        photoURL = await ref.read(uploadServiceProvider).uploadImage(_pickedFile!);
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
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface, title: const Text('Add Item')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Photo
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line, width: 1.5),
                    image: _preview != null
                        ? DecorationImage(image: MemoryImage(_preview!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _preview != null
                      ? null
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded, size: 44, color: AppColors.primary),
                            SizedBox(height: 8),
                            Text('Add a photo (optional)', style: TextStyle(color: AppColors.inkMuted)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              _label('Name'),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'e.g. Black Oversized Hoodie'),
              ),
              const SizedBox(height: 18),

              _label('Category'),
              _dropdown(_category, WardrobeOptions.categories, (v) => setState(() => _category = v)),
              const SizedBox(height: 18),

              _label('Color'),
              _colorPicker(),
              const SizedBox(height: 18),

              _label('Fabric'),
              _dropdown(_fabric, WardrobeOptions.fabrics, (v) => setState(() => _fabric = v)),
              const SizedBox(height: 18),

              _label('Season'),
              _dropdown(_season, WardrobeOptions.seasons, (v) => setState(() => _season = v)),
              const SizedBox(height: 18),

              _label('Formality'),
              _dropdown(_formality, WardrobeOptions.formalities, (v) => setState(() => _formality = v)),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: const Text('Save to Wardrobe'),
              ),
            ],
          ),
          if (_saving)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.inkMuted, fontSize: 13)),
      );

  Widget _dropdown(String value, List<String> items, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
        final hex = c.hex.replaceFirst('#', '');
        final color = Color(int.parse('FF$hex', radix: 16));
        return GestureDetector(
          onTap: () => setState(() => _colorHex = c.hex),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.line,
                width: selected ? 3 : 1,
              ),
            ),
            child: selected
                ? Icon(Icons.check_rounded,
                    size: 18, color: color.computeLuminance() > 0.6 ? Colors.black54 : Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
