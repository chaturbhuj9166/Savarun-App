import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../auth/data/auth_providers.dart';
import 'data/profile_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).value;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          _Group(
            title: 'Account',
            children: [
              _Tile(
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
                onTap: () => context.push(Routes.editProfile),
              ),
              _Tile(
                icon: Icons.style_outlined,
                label: 'Style Preferences',
                value: profile?.style,
                onTap: () => context.push(Routes.editProfile),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Group(
            title: 'Privacy',
            children: [
              // The one privacy control the spec defines: public vs private
              // wardrobe. Kept here as well as on the profile.
              SwitchListTile(
                value: profile?.wardrobePublic ?? true,
                activeThumbColor: AppColors.ink,
                onChanged: profile == null
                    ? null
                    : (v) => ref
                        .read(profileRepoProvider)
                        .setWardrobePublic(profile.uid, v),
                secondary: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.inkMuted),
                title: const Text('Public Wardrobe',
                    style: TextStyle(fontSize: 14)),
                subtitle: Text(
                  (profile?.wardrobePublic ?? true)
                      ? 'Anyone can view your closet and past scores'
                      : 'Only you can see your closet and past scores',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Group(
            title: 'Your Data',
            children: [
              _Tile(
                icon: Icons.history_rounded,
                label: 'Outfit History',
                onTap: () => context.push(Routes.outfitHistory),
              ),
              _Tile(
                icon: Icons.insights_rounded,
                label: 'Wardrobe Analytics',
                onTap: () => context.push(Routes.wardrobeAnalytics),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Group(
            title: 'About',
            children: [
              _Tile(
                icon: Icons.info_outline_rounded,
                label: 'About Savarun',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Savarun',
                  applicationVersion: '1.0.0',
                  applicationLegalese:
                      'AI-powered fashion & style platform.\n\n'
                      'Analyze your outfits, organize your wardrobe, connect '
                      'with other fashion lovers and discover brands.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            // Router redirect sends us back to Login once signed out.
            onPressed: () => ref.read(authServiceProvider).signOut(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Log Out'),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Savarun v1.0.0',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
              fontSize: 12.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.inkMuted),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null && value!.isNotEmpty)
            Text(
              value!,
              style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
            ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
        ],
      ),
      onTap: onTap,
    );
  }
}
