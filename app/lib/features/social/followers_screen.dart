import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../auth/data/auth_providers.dart';
import '../profile/data/profile_providers.dart';
import 'data/follow_providers.dart';

/// Followers / Following lists for any user, as two tabs.
class FollowersScreen extends ConsumerStatefulWidget {
  const FollowersScreen({
    super.key,
    required this.uid,
    this.initialTab = 0,
  });

  final String uid;

  /// 0 = Followers, 1 = Following.
  final int initialTab;

  @override
  ConsumerState<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends ConsumerState<FollowersScreen> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final uids = _tab == 0
        ? ref.watch(followerUidsProvider(widget.uid))
        : ref.watch(followingUidsProvider(widget.uid));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Followers')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: 'Followers',
                      selected: _tab == 0,
                      onTap: () => setState(() => _tab = 0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TabButton(
                      label: 'Following',
                      selected: _tab == 1,
                      onTap: () => setState(() => _tab = 1),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: uids.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Could not load list',
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        _tab == 0 ? 'No followers yet' : 'Not following anyone yet',
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _UserRow(uid: list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// One person in the list, with a live Follow / Following toggle.
class _UserRow extends ConsumerWidget {
  const _UserRow({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userByUidProvider(uid)).value;
    final me = ref.watch(authStateProvider).value?.uid;
    final isFollowing = ref.watch(isFollowingProvider(uid)).value ?? false;
    final isMe = me == uid;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push(Routes.otherProfile, extra: uid),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.white,
              backgroundImage: (profile?.photoURL?.isNotEmpty ?? false)
                  ? NetworkImage(profile!.photoURL!)
                  : null,
              child: (profile?.photoURL?.isEmpty ?? true)
                  ? const Icon(Icons.person_outline_rounded,
                      size: 20, color: AppColors.inkMuted)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(Routes.otherProfile, extra: uid),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.name ?? 'Savarun User',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  if (profile?.handle.isNotEmpty ?? false)
                    Text(
                      profile!.handle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!isMe && me != null)
            TextButton(
              onPressed: () {
                final repo = ref.read(followRepoProvider);
                isFollowing ? repo.unfollow(me, uid) : repo.follow(me, uid);
              },
              style: TextButton.styleFrom(
                backgroundColor:
                    isFollowing ? AppColors.surface : AppColors.lilac,
                foregroundColor: AppColors.ink,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(isFollowing ? 'Following' : 'Follow'),
            ),
        ],
      ),
    );
  }
}
