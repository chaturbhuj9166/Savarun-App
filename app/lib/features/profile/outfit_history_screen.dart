import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../analysis/data/history_providers.dart';

/// Outfit History (spec screen 17) — every saved analysis with its Fit Score.
class OutfitHistoryScreen extends ConsumerWidget {
  const OutfitHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(outfitHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Outfit History')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const _Empty(
          icon: Icons.error_outline_rounded,
          title: 'Could not load history',
          subtitle: 'Check your connection and try again.',
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _Empty(
              icon: Icons.history_rounded,
              title: 'No analyses yet',
              subtitle:
                  'Your analyzed outfits and Fit Scores will appear here.',
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.72,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => _HistoryCard(entry: items[i]),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});
  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final a = entry.analysis;
    final url = a.imageUrl;
    final dominant = a.styleDna.isNotEmpty ? a.styleDna.first.style : null;

    return GestureDetector(
      onTap: () => context.push(Routes.analysisResult, extra: a),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: AppColors.surface,
              child: (url != null && url.isNotEmpty)
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.checkroom_rounded,
                        color: AppColors.inkMuted,
                      ),
                    )
                  : const Icon(Icons.checkroom_rounded,
                      color: AppColors.inkMuted),
            ),
            // Bottom scrim so the score and style stay readable.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x99000000)],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${a.fitScore}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (dominant != null)
                    Expanded(
                      child: Text(
                        dominant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

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
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
