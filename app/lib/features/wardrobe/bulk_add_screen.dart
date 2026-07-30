import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/upload_service.dart';
import '../../core/theme/app_colors.dart';
import 'data/autotag_service.dart';
import 'data/wardrobe_models.dart';
import 'data/wardrobe_providers.dart';

/// Bulk upload (Module 2): pick many photos at once, AI-tag and save each.
class BulkAddScreen extends ConsumerStatefulWidget {
  const BulkAddScreen({super.key});

  @override
  ConsumerState<BulkAddScreen> createState() => _BulkAddScreenState();
}

enum _RowState { queued, working, done, failed }

class _Row {
  _Row(this.file, this.bytes);
  final XFile file;
  final Uint8List bytes;
  _RowState state = _RowState.queued;
  String label = 'Queued';
}

class _BulkAddScreenState extends ConsumerState<BulkAddScreen> {
  final List<_Row> _rows = [];
  bool _running = false;
  int _done = 0;

  Future<void> _pick() async {
    final files = await ref.read(uploadServiceProvider).pickMultiFromGallery();
    if (files.isEmpty) return;
    final rows = <_Row>[];
    for (final f in files) {
      rows.add(_Row(f, await f.readAsBytes()));
    }
    setState(() {
      _rows
        ..clear()
        ..addAll(rows);
      _done = 0;
    });
  }

  Future<void> _process() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final upload = ref.read(uploadServiceProvider);
    final tagger = ref.read(autotagServiceProvider);
    final repo = ref.read(wardrobeRepoProvider);

    setState(() => _running = true);

    // Sequential keeps us within the AI rate limit and shows clear progress.
    for (final row in _rows) {
      if (row.state == _RowState.done) continue;
      setState(() {
        row.state = _RowState.working;
        row.label = 'Tagging…';
      });
      try {
        final tags = await tagger.tag(row.file);
        setState(() => row.label = 'Uploading…');
        final url = await upload.uploadImage(row.file);
        await repo.add(
          uid,
          WardrobeItem(
            id: '',
            name: tags.name.isEmpty ? 'Wardrobe item' : tags.name,
            category: tags.category,
            colorHex: tags.colorHex,
            fabric: tags.fabric,
            season: tags.season,
            formality: tags.formality,
            photoURL: url,
          ),
        );
        setState(() {
          row.state = _RowState.done;
          row.label = '${tags.name} · ${tags.category}';
          _done++;
        });
      } catch (e) {
        setState(() {
          row.state = _RowState.failed;
          row.label = 'Failed — skipped';
        });
      }
    }

    if (mounted) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final allDone = _rows.isNotEmpty && _done == _rows.length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Bulk Add')),
      body: Column(
        children: [
          Expanded(
            child: _rows.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.burst_mode_outlined,
                              size: 56, color: AppColors.inkMuted),
                          const SizedBox(height: 16),
                          const Text('Add many at once',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          const Text(
                            'Pick several clothing photos — AI tags each one '
                            'and adds it to your wardrobe.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13, color: AppColors.inkMuted),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _pick,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Choose Photos'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _RowTile(row: _rows[i]),
                  ),
          ),
          if (_rows.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: allDone
                    ? ElevatedButton(
                        onPressed: () => context.pop(),
                        child: Text('Done — added $_done item'
                            '${_done == 1 ? '' : 's'}'),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _running ? null : _pick,
                              child: const Center(child: Text('Change')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _running ? null : _process,
                              child: Text(_running
                                  ? 'Adding… $_done/${_rows.length}'
                                  : 'Add ${_rows.length} Items'),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.row});
  final _Row row;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (row.state) {
      _RowState.queued => (Icons.schedule_rounded, AppColors.inkMuted),
      _RowState.working => (Icons.autorenew_rounded, AppColors.primary),
      _RowState.done => (Icons.check_circle_rounded, AppColors.success),
      _RowState.failed => (Icons.error_outline_rounded, AppColors.danger),
    };

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(row.bytes,
              width: 52, height: 52, fit: BoxFit.cover),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            row.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
          ),
        ),
        const SizedBox(width: 10),
        row.state == _RowState.working
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, color: color, size: 20),
      ],
    );
  }
}
