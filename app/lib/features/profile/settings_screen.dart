import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../auth/data/auth_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface, title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _group('Account', [
            _tile(Icons.person_outline_rounded, 'Edit Profile'),
            _tile(Icons.lock_outline_rounded, 'Privacy'),
            _tile(Icons.notifications_none_rounded, 'Notifications'),
          ]),
          const SizedBox(height: 20),
          _group('Preferences', [
            _tile(Icons.style_outlined, 'Style Preferences'),
            _tile(Icons.language_rounded, 'Language'),
            _tile(Icons.dark_mode_outlined, 'Appearance'),
          ]),
          const SizedBox(height: 20),
          _group('Support', [
            _tile(Icons.help_outline_rounded, 'Help Center'),
            _tile(Icons.info_outline_rounded, 'About Savarun'),
          ]),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            // Router redirect sends us back to Login once signed out.
            onPressed: () => ref.read(authServiceProvider).signOut(),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log Out'),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('Savarun v1.0.0', style: TextStyle(color: AppColors.inkMuted, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _group(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.inkMuted, fontSize: 13)),
        ),
        Container(
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _tile(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
      onTap: () {},
    );
  }
}
