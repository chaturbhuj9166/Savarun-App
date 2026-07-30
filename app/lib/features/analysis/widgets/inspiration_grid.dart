import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../social/data/feed_providers.dart';

/// Outfit Inspiration Grid (Module 1, Step 7): a Pinterest-style grid of other
/// users' shared outfits in the same dominant [style], most popular first.
/// Each card shows the style category and its popularity (likes).
///
/// Renders nothing until there is at least one similar outfit, so it never
/// shows an empty box while the community is still small.
class InspirationGrid extends ConsumerWidget {
  const InspirationGrid({super.key, required this.style});

  final String style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspo = ref.watch(inspirationByStyleProvider(style));

    return inspo.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (posts) {
        if (posts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'More $style Inspiration',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Popular looks from the community',
              style: TextStyle(fontSize: 12.5, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: posts.length,
              itemBuilder: (context, i) => _InspoCard(post: posts[i]),
            ),
          ],
        );
      },
    );
  }
}

class _InspoCard extends StatelessWidget {
  const _InspoCard({required this.post});
  final OutfitPost post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tapping opens the author's profile to explore more of their looks.
      onTap: () => context.push(Routes.otherProfile, extra: post.authorUid),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: AppColors.surface,
              child: post.imageUrl.isEmpty
                  ? const Icon(Icons.checkroom_rounded,
                      color: AppColors.inkMuted)
                  : Image.network(
                      post.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.inkMuted),
                    ),
            ),
            // Bottom scrim + labels.
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
              left: 10,
              right: 10,
              bottom: 10,
              child: Row(
                children: [
                  if (post.style != null)
                    Expanded(
                      child: Text(
                        post.style!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  const Icon(Icons.favorite_rounded,
                      size: 13, color: AppColors.white),
                  const SizedBox(width: 3),
                  Text(
                    '${post.likes}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
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
