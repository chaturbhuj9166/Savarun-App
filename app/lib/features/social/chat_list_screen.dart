import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../auth/data/auth_providers.dart';
import '../profile/data/profile_providers.dart';
import 'data/chat_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authStateProvider).value?.uid;
    final threadsAsync = ref.watch(chatThreadsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Messages')),
      body: threadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('$e', textAlign: TextAlign.center))),
        data: (threads) {
          if (threads.isEmpty || me == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No conversations yet.\nFind people in Explore and say hi.',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.inkMuted)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: threads.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 82, color: AppColors.line),
            itemBuilder: (context, i) => _ThreadTile(thread: threads[i], me: me),
          );
        },
      ),
    );
  }
}

class _ThreadTile extends ConsumerWidget {
  const _ThreadTile({required this.thread, required this.me});
  final ChatThread thread;
  final String me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUid = thread.otherUid(me);
    final other = ref.watch(userByUidProvider(otherUid)).value;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      onTap: () => context.push(Routes.chat, extra: otherUid),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primary,
        backgroundImage: (other?.photoURL != null && other!.photoURL!.isNotEmpty) ? NetworkImage(other.photoURL!) : null,
        child: (other?.photoURL == null || other!.photoURL!.isEmpty)
            ? Text(other?.initial ?? '?', style: const TextStyle(color: Colors.white, fontSize: 20))
            : null,
      ),
      title: Text(other?.name ?? 'Loading…', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(_preview(), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: thread.awaitingMyDecision(me)
          // A request waiting on me is more useful than a timestamp.
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Request',
                  style: TextStyle(fontSize: 11, color: AppColors.white)),
            )
          : thread.lastTime != null
              ? Text(_shortTime(thread.lastTime!), style: const TextStyle(fontSize: 11, color: AppColors.inkMuted))
              : null,
    );
  }

  String _preview() {
    if (thread.status == ChatStatus.pending) {
      return thread.awaitingMyDecision(me)
          ? 'Wants to chat with you'
          : 'Chat request sent';
    }
    return thread.lastMessage;
  }

  String _shortTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
