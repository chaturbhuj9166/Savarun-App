import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/feed_providers.dart';

/// The home feed of outfit posts from people you follow (Module 3).
/// Renders nothing until there's at least one post, so an empty feed doesn't
/// clutter the analyzer-focused home screen.
class FeedSection extends ConsumerWidget {
  const FeedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(homeFeedProvider);

    return feed.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (posts) {
        if (posts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'From People You Follow',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            for (final post in posts) _PostCard(post: post),
          ],
        );
      },
    );
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post});
  final OutfitPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row.
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      context.push(Routes.otherProfile, extra: post.authorUid),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.surface,
                    backgroundImage: post.authorPhoto.isNotEmpty
                        ? NetworkImage(post.authorPhoto)
                        : null,
                    child: post.authorPhoto.isEmpty
                        ? const Icon(Icons.person_outline_rounded,
                            size: 18, color: AppColors.inkMuted)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    post.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (post.fitScore != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${post.fitScore}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Photo.
          if (post.imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                post.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surface,
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppColors.inkMuted),
                ),
              ),
            ),
          // Like row + caption.
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LikeButton(post: post),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      post.caption,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Heart toggle showing the live like count (popularity).
class _LikeButton extends ConsumerWidget {
  const _LikeButton({required this.post});
  final OutfitPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(hasLikedProvider(post.id)).value ?? false;

    return TextButton.icon(
      onPressed: () => ref.read(feedRepoProvider).toggleLike(post.id, !liked),
      style: TextButton.styleFrom(
        foregroundColor: liked ? AppColors.danger : AppColors.inkMuted,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 36),
      ),
      icon: Icon(
        liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: 18,
      ),
      label: Text(
        '${post.likes}',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
