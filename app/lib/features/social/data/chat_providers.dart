import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';

/// Where a conversation stands. Per the spec you must send a Chat Request
/// first; the thread only opens once the other person accepts.
enum ChatStatus { none, pending, accepted }

/// A 1-on-1 chat thread (the `chats/{chatId}` doc).
class ChatThread {
  const ChatThread({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastTime,
    required this.status,
    required this.requestedBy,
  });

  final String chatId;
  final List<String> participants;
  final String lastMessage;
  final DateTime? lastTime;
  final ChatStatus status;

  /// Who sent the chat request (null on legacy threads).
  final String? requestedBy;

  String otherUid(String me) =>
      participants.firstWhere((p) => p != me, orElse: () => me);

  /// True when [me] is the one who must accept or decline.
  bool awaitingMyDecision(String me) =>
      status == ChatStatus.pending && requestedBy != null && requestedBy != me;

  factory ChatThread.fromDoc(String id, Map<String, dynamic> d) {
    return ChatThread(
      chatId: id,
      participants: List<String>.from(d['participants'] ?? const []),
      lastMessage: d['lastMessage'] ?? '',
      lastTime: (d['lastTime'] as Timestamp?)?.toDate(),
      // Threads created before the request flow existed have no status; treat
      // them as already accepted so nobody loses an open conversation.
      status: _statusFrom(d['status'] as String?),
      requestedBy: d['requestedBy'] as String?,
    );
  }

  static ChatStatus _statusFrom(String? raw) {
    switch (raw) {
      case 'pending':
        return ChatStatus.pending;
      case 'accepted':
      case null:
        return ChatStatus.accepted;
      default:
        return ChatStatus.accepted;
    }
  }
}

class ChatMessage {
  const ChatMessage({
    required this.senderId,
    required this.text,
    required this.imageUrl,
    required this.createdAt,
  });

  final String senderId;
  final String text;

  /// Set when the message is a shared outfit photo.
  final String? imageUrl;
  final DateTime? createdAt;

  bool get isImage => imageUrl != null && imageUrl!.isNotEmpty;

  factory ChatMessage.fromDoc(Map<String, dynamic> d) {
    return ChatMessage(
      senderId: d['senderId'] ?? '',
      text: d['text'] ?? '',
      imageUrl: d['imageUrl'] as String?,
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

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  /// Open a thread in `pending` state. The recipient must accept before
  /// either side can carry on messaging.
  Future<void> sendRequest(String me, String other) {
    return _chats.doc(chatIdFor(me, other)).set({
      'participants': [me, other]..sort(),
      'status': 'pending',
      'requestedBy': me,
      'lastMessage': '',
      'lastTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> acceptRequest(String me, String other) {
    return _chats.doc(chatIdFor(me, other)).update({'status': 'accepted'});
  }

  /// Declining removes the thread so the sender can try again later.
  Future<void> declineRequest(String me, String other) {
    return _chats.doc(chatIdFor(me, other)).delete();
  }

  Future<void> sendMessage(
    String me,
    String other, {
    String text = '',
    String? imageUrl,
  }) async {
    final trimmed = text.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    if (trimmed.isEmpty && !hasImage) return;

    final chatRef = _chats.doc(chatIdFor(me, other));

    await chatRef.set({
      'participants': [me, other]..sort(),
      'lastMessage': hasImage && trimmed.isEmpty ? '📷 Photo' : trimmed,
      'lastTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add({
      'senderId': me,
      'text': trimmed,
      if (hasImage) 'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ChatMessage>> messages(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatMessage.fromDoc(d.data())).toList());
  }

  Stream<ChatThread?> thread(String chatId) {
    return _chats.doc(chatId).snapshots().map(
        (snap) => snap.exists ? ChatThread.fromDoc(snap.id, snap.data()!) : null);
  }

  Stream<List<ChatThread>> threads(String me) {
    return _chats
        .where('participants', arrayContains: me)
        .orderBy('lastTime', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatThread.fromDoc(d.id, d.data())).toList());
  }
}

/// The signed-in user's chat threads (most recent first).
final chatThreadsProvider = StreamProvider<List<ChatThread>>((ref) {
  final me = ref.watch(authStateProvider).value?.uid;
  if (me == null) return Stream.value(const []);
  return ref.watch(chatRepoProvider).threads(me);
});

/// The thread with [otherUid], or null if no request has been sent yet.
final chatThreadProvider =
    StreamProvider.family<ChatThread?, String>((ref, otherUid) {
  final me = ref.watch(authStateProvider).value?.uid;
  if (me == null) return Stream.value(null);
  final repo = ref.watch(chatRepoProvider);
  return repo.thread(repo.chatIdFor(me, otherUid));
});

/// Messages in a chat with [otherUid].
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, otherUid) {
  final me = ref.watch(authStateProvider).value?.uid;
  if (me == null) return Stream.value(const []);
  final repo = ref.watch(chatRepoProvider);
  return repo.messages(repo.chatIdFor(me, otherUid));
});
