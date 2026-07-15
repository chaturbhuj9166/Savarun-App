import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/savarun_logo.dart';
import '../profile/data/profile_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(myProfileProvider).value?.name.split(' ').first ?? 'there';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SavarunLogo(fontSize: 24),
              Row(
                children: [
                  IconButton(onPressed: () => context.push(Routes.explore), icon: const Icon(Icons.search_rounded)),
                  IconButton(onPressed: () => context.push(Routes.chatList), icon: const Icon(Icons.chat_bubble_outline_rounded)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Hi $name 👋', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('What would you like to do today?', style: TextStyle(color: AppColors.inkMuted)),
          const SizedBox(height: 24),

          // Primary CTA — analyze an outfit
          _BigCta(
            title: 'Analyze an Outfit',
            subtitle: 'Snap a photo and get your Fit Score',
            icon: Icons.camera_alt_rounded,
            onTap: () => context.push(Routes.camera),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _MiniCta(title: 'Discover People', icon: Icons.groups_rounded, onTap: () => context.push(Routes.explore)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MiniCta(title: 'Messages', icon: Icons.chat_bubble_outline_rounded, onTap: () => context.push(Routes.chatList)),
              ),
            ],
          ),

          const SizedBox(height: 28),
          // Feed placeholder (real "share outfit" feed comes in a later phase).
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
            child: const Column(
              children: [
                Icon(Icons.dynamic_feed_rounded, size: 40, color: AppColors.inkMuted),
                SizedBox(height: 12),
                Text('Your feed is coming soon', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Follow people to see their outfit posts here.',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.inkMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BigCta extends StatelessWidget {
  const _BigCta({required this.title, required this.subtitle, required this.icon, required this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Icon(icon, color: Colors.white, size: 44),
          ],
        ),
      ),
    );
  }
}

class _MiniCta extends StatelessWidget {
  const _MiniCta({required this.title, required this.icon, required this.onTap});
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
