import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/admin_service.dart';
import 'admin_scaffold.dart';

class AdminUsersTab extends ConsumerWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminAsync<List<AdminUser>>(
      value: ref.watch(adminUsersProvider),
      onRetry: () => ref.invalidate(adminUsersProvider),
      builder: (users) {
        if (users.isEmpty) {
          return const Center(
            child: Text('No users yet.',
                style: TextStyle(color: AppColors.inkMuted)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: users.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _UserRow(user: users[i]),
        );
      },
    );
  }
}

class _UserRow extends ConsumerWidget {
  const _UserRow({required this.user});
  final AdminUser user;

  (String, Color) get _status => switch (user.status) {
        'banned' => ('Banned', AppColors.danger),
        'suspended' => ('Suspended', AppColors.warning),
        'verified' => ('Verified', AppColors.success),
        _ => ('Active', AppColors.inkMuted),
      };

  Future<void> _act(BuildContext context, WidgetRef ref, String action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminRepoProvider).moderateUser(user.uid, action);
      ref.invalidate(adminUsersProvider);
      messenger.showSnackBar(SnackBar(content: Text('User $action complete')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, color) = _status;

    return AdminCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surface,
            backgroundImage: (user.photoURL?.isNotEmpty ?? false)
                ? NetworkImage(user.photoURL!)
                : null,
            child: (user.photoURL?.isEmpty ?? true)
                ? const Icon(Icons.person_outline_rounded,
                    color: AppColors.inkMuted, size: 20)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (user.email != null)
                  Text(user.email!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.inkMuted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusPill(label: label, color: color),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.inkMuted),
            onSelected: (a) => _act(context, ref, a),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'verify', child: Text('Verify')),
              PopupMenuItem(value: 'suspend', child: Text('Suspend')),
              PopupMenuItem(value: 'ban', child: Text('Ban')),
              PopupMenuItem(value: 'reinstate', child: Text('Reinstate')),
            ],
          ),
        ],
      ),
    );
  }
}
