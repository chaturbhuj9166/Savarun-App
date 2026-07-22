import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/history_providers.dart';

/// "Past outfit analysis scores displayed on the profile" (spec, Module 3).
///
/// Shows the user's most recent Fit Scores as a horizontal strip. Reading
/// another person's history only succeeds when their profile is public, so a
/// permission error is treated as "nothing to show" rather than an error.
class PastScoresStrip extends ConsumerWidget {
  const PastScoresStrip({super.key, required this.uid, this.isMe = false});

  final String uid;
  final bool isMe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(userOutfitHistoryProvider(uid));

    return history.when(
      loading: () => const SizedBox(height: 110),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final shown = items.take(10).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Past Scores',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (isMe)
                  TextButton(
                    onPressed: () => context.push(Routes.outfitHistory),
                    child: const Text('See all'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: shown.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final entry = shown[i];
                  final url = entry.analysis.imageUrl;

                  return GestureDetector(
                    onTap: () => context.push(Routes.analysisResult,
                        extra: entry.analysis),
                    child: SizedBox(
                      width: 82,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 82,
                              height: 110,
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
                          ),
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${entry.analysis.fitScore}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
