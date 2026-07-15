import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';

/// A 1-on-1 chat thread (the `chats/{chatId}` doc).
class ChatThread {
  const ChatThread({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastTime,
  });

  final String chatId;
  final List<String> participants;
  final String lastMessage;
  final DateTime? lastTime;

  String otherUid(String me) => participants.firstWhere((p) => p != me, orElse: () => me);

  factory ChatThread.fromDoc(String id, Map<String, dynamic> d) {
    return ChatThread(
      chatId: id,
      participants: List<String>.from(d['participants'] ?? const []),
      lastMessage: d['lastMessage'] ?? '',
      lastTime: (d['lastTime'] as Timestamp?)?.toDate(),
    );
  }
}

class ChatMessage {
  const ChatMessage({required this.senderId, required this.text, required this.createdAt});
  final String senderId;
  final String text;
  final DateTime? createdAt;

  factory ChatMessage.fromDoc(Map<String, dynamic> d) {
    return ChatMessage(
      senderId: d['senderId'] ?? '',
      text: d['text'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

final chatRepoProvider = Provider((ref) => ChatRepository());

class ChatRepository {
  final _db = FirebaseFirestore.instance;

  /// Deterministic chat id from the two uids (sorted so both sides agree).
  String chatIdFor(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  CollectionReference<Map<String, dynamic>> get _chats => _db.collection('chats');

  Future<void> sendMessage(String me, String other, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final chatId = chatIdFor(me, other);
    final chatRef = _chats.doc(chatId);

    await chatRef.set({
      'participants': [me, other]..sort(),
      'lastMessage': trimmed,
      'lastTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add({
      'senderId': me,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ChatMessage>> messages(String chatId) {
    return _chats.doc(chatId).collection('messages').orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => ChatMessage.fromDoc(d.data())).toList(),
        );
  }

  Stream<List<ChatThread>> threads(String me) {
    return _chats
        .where('participants', arrayContains: me)
        .orderBy('lastTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatThread.fromDoc(d.id, d.data())).toList());
  }
}

/// The signed-in user's chat threads (most recent first).
final chatThreadsProvider = StreamProvider<List<ChatThread>>((ref) {
  final me = ref.watch(authStateProvider).value?.uid;
  if (me == null) return Stream.value(const []);
  return ref.watch(chatRepoProvider).threads(me);
});

/// Messages in a chat with [otherUid].
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, otherUid) {
  final me = ref.watch(authStateProvider).value?.uid;
  if (me == null) return Stream.value(const []);
  final chatId = ref.watch(chatRepoProvider).chatIdFor(me, otherUid);
  return ref.watch(chatRepoProvider).messages(chatId);
});
