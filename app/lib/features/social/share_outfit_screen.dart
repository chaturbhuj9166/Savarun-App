import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/upload_service.dart';
import '../../core/theme/app_colors.dart';
import '../profile/data/profile_providers.dart';
import 'data/feed_providers.dart';

/// Share an outfit to the home feed (Module 3). Optionally seeded with an
/// analysed photo + Fit Score coming from the result screen.
class ShareOutfitScreen extends ConsumerStatefulWidget {
  const ShareOutfitScreen({super.key, this.seedImageUrl, this.seedFitScore});

  final String? seedImageUrl;
  final int? seedFitScore;

  @override
  ConsumerState<ShareOutfitScreen> createState() => _ShareOutfitScreenState();
}

class _ShareOutfitScreenState extends ConsumerState<ShareOutfitScreen> {
  final _caption = TextEditingController();

  XFile? _picked;
  Uint8List? _preview;
  bool _posting = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await ref.read(uploadServiceProvider).pickFromGallery();
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _picked = file;
      _preview = bytes;
    });
  }

  Future<void> _post() async {
    final me = ref.read(myProfileProvider).value;
    if (me == null) return;

    // Need either a freshly picked photo or a seeded analysis image.
    if (_picked == null && (widget.seedImageUrl ?? '').isEmpty) {
      _toast('Add a photo to share');
      return;
    }

    setState(() => _posting = true);
    try {
      final imageUrl = _picked != null
          ? await ref.read(uploadServiceProvider).uploadImage(_picked!)
          : widget.seedImageUrl!;

      await ref.read(feedRepoProvider).createPost(
            authorUid: me.uid,
            authorName: me.name,
            authorPhoto: me.photoURL ?? '',
            imageUrl: imageUrl,
            caption: _caption.text.trim(),
            fitScore: widget.seedFitScore,
          );

      if (!mounted) return;
      _toast('Shared to your feed ✨');
      context.pop();
    } catch (e) {
      _toast('Could not share: $e');
    } finally {
      if (mounted) setState(() => _posting = false);
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
    final seeded = (widget.seedImageUrl ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Share Outfit')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              GestureDetector(
                onTap: seeded ? null : _pick,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: _preview != null
                        ? Image.memory(_preview!, fit: BoxFit.cover)
                        : seeded
                            ? Image.network(widget.seedImageUrl!,
                                fit: BoxFit.cover)
                            : Container(
                                color: AppColors.white,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_rounded,
                                        size: 40, color: AppColors.inkMuted),
                                    SizedBox(height: 10),
                                    Text('Add a photo',
                                        style: TextStyle(
                                            color: AppColors.inkMuted)),
                                  ],
                                ),
                              ),
                  ),
                ),
              ),
              if (widget.seedFitScore != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Fit Score ${widget.seedFitScore}',
                          style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _caption,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Say something about this look…',
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _posting ? null : _post,
                child: const Text('Share'),
              ),
            ],
          ),
          if (_posting)
            const ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
