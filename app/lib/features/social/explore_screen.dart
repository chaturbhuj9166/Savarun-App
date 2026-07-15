import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../profile/data/profile_providers.dart';
import 'data/explore_providers.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  String _style = 'All';
  String _text = '';

  static const _styleFilters = ['All', ...kStyles];

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(exploreResultsProvider(ExploreQuery(style: _style, text: _text)));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Explore')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _text = v),
              decoration: const InputDecoration(
                hintText: 'Search users by username…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _styleFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final s = _styleFilters[i];
                final selected = s == _style;
                return ChoiceChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (_) => setState(() => _style = s),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600),
                  backgroundColor: AppColors.surface,
                  side: BorderSide.none,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not search:\n$e', textAlign: TextAlign.center))),
              data: (users) {
                if (users.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No users found.\nInvite friends or try a different search.',
                          textAlign: TextAlign.center, style: TextStyle(color: AppColors.inkMuted)),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const Divider(height: 24, color: AppColors.line),
                  itemBuilder: (context, i) => _UserRow(user: users[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user});
  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(Routes.otherProfile, extra: user.uid),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary,
            backgroundImage: (user.photoURL != null && user.photoURL!.isNotEmpty) ? NetworkImage(user.photoURL!) : null,
            child: (user.photoURL == null || user.photoURL!.isEmpty)
                ? Text(user.initial, style: const TextStyle(color: Colors.white, fontSize: 20))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${user.handle}${user.style != null ? ' · ${user.style}' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}
