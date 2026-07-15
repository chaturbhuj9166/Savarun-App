import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/upload_service.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../social/data/follow_providers.dart';
import '../wardrobe/data/wardrobe_providers.dart';
import 'data/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return SafeArea(
      child: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load profile:\n$e', textAlign: TextAlign.center)),
        data: (profile) {
          if (profile == null) return const Center(child: Text('Not signed in'));

          final followers = ref.watch(followerCountProvider(profile.uid)).value ?? 0;
          final following = ref.watch(followingCountProvider(profile.uid)).value ?? 0;
          final items = ref.watch(wardrobeProvider).value?.length ?? 0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => context.push(Routes.settings),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),

              Center(
                child: Column(
                  children: [
                    _Avatar(
                      photoURL: profile.photoURL,
                      initial: profile.initial,
                      onTap: () => _changePhoto(context, ref, profile.uid),
                    ),
                    const SizedBox(height: 12),
                    Text(profile.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    Text(profile.handle, style: const TextStyle(color: AppColors.inkMuted)),
                    if (profile.style != null) ...[
                      const SizedBox(height: 6),
                      _StylePill(style: profile.style!),
                    ],
                    const SizedBox(height: 8),
                    Text(profile.bio, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.ink)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Stat(value: '$followers', label: 'Followers'),
                  _divider(),
                  _Stat(value: '$following', label: 'Following'),
                  _divider(),
                  _Stat(value: '$items', label: 'Items'),
                ],
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () => context.push(Routes.editProfile),
                child: const Text('Edit Profile'),
              ),
              const SizedBox(height: 24),

              // Public/private toggle — persisted to Firestore.
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: profile.wardrobePublic,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => ref.read(profileRepoProvider).setWardrobePublic(profile.uid, v),
                    title: const Text('Public Wardrobe', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      profile.wardrobePublic ? 'Anyone can view your closet' : 'Only you can see your closet',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 30, color: AppColors.line);

  /// Pick a photo from the gallery, upload it to the backend, and save the
  /// returned URL to the user's Firestore doc (the profile updates live).
  Future<void> _changePhoto(BuildContext context, WidgetRef ref, String uid) async {
    final uploader = ref.read(uploadServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await uploader.pickFromGallery();
      if (file == null) return;
      messenger.showSnackBar(const SnackBar(content: Text('Uploading photo…')));
      final url = await uploader.uploadImage(file);
      await ref.read(profileRepoProvider).setPhotoURL(uid, url);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Profile photo updated ✨')));
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.danger));
    }
  }
}

class _StylePill extends StatelessWidget {
  const _StylePill({required this.style});
  final String style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(style, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

/// Shows the user's profile photo with a tappable camera badge to change it.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoURL, required this.initial, required this.onTap});
  final String? photoURL;
  final String initial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = (photoURL != null && photoURL!.isNotEmpty)
        ? CircleAvatar(radius: 44, backgroundColor: AppColors.surface, backgroundImage: NetworkImage(photoURL!))
        : CircleAvatar(radius: 44, backgroundColor: AppColors.primary, child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 32)));

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
      ],
    );
  }
}
