import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';

/// Follow edges live in a top-level `follows` collection with doc id
/// `${followerUid}_${followingUid}`. This keeps writes to the follower's own
/// data (secure, no cross-user writes) and lets us count via queries.
final followRepoProvider = Provider((ref) => FollowRepository());

class FollowRepository {
  final _db = FirebaseFirestore.instance;

  String _edgeId(String followerUid, String followingUid) => '${followerUid}_$followingUid';

  Future<void> follow(String me, String target) {
    return _db.collection('follows').doc(_edgeId(me, target)).set({
      'followerUid': me,
      'followingUid': target,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unfollow(String me, String target) {
    return _db.collection('follows').doc(_edgeId(me, target)).delete();
  }
}

/// Am I (the signed-in user) following [uid]? Live.
final isFollowingProvider = StreamProvider.family<bool, String>((ref, uid) {
  final me = ref.watch(authStateProvider).value?.uid;
  if (me == null) return Stream.value(false);
  return FirebaseFirestore.instance
      .collection('follows')
      .doc('${me}_$uid')
      .snapshots()
      .map((snap) => snap.exists);
});

/// Live follower count for [uid].
final followerCountProvider = StreamProvider.family<int, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('follows')
      .where('followingUid', isEqualTo: uid)
      .snapshots()
      .map((snap) => snap.size);
});

/// Live following count for [uid].
final followingCountProvider = StreamProvider.family<int, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('follows')
      .where('followerUid', isEqualTo: uid)
      .snapshots()
      .map((snap) => snap.size);
});
