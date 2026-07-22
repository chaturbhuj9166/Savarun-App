import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import 'wardrobe_models.dart';

final wardrobeRepoProvider = Provider((ref) => WardrobeRepository());

class WardrobeRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('wardrobe');

  Stream<List<WardrobeItem>> watch(String uid) {
    return _col(uid).orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => WardrobeItem.fromDoc(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> add(String uid, WardrobeItem item) {
    return _col(uid).add(item.toMap());
  }

  /// Patch an existing item — used by the Item Details screen.
  Future<void> update(String uid, String itemId, Map<String, dynamic> data) {
    return _col(uid).doc(itemId).update(data);
  }

  Future<void> delete(String uid, String itemId) {
    return _col(uid).doc(itemId).delete();
  }
}

/// Live list of the signed-in user's wardrobe items.
final wardrobeProvider = StreamProvider<List<WardrobeItem>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(wardrobeRepoProvider).watch(user.uid);
});

/// Convenience: the current uid (or null).
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid ?? FirebaseAuth.instance.currentUser?.uid;
});

/// Any user's wardrobe (used when viewing a public profile).
final userWardrobeProvider = StreamProvider.family<List<WardrobeItem>, String>((ref, uid) {
  return ref.watch(wardrobeRepoProvider).watch(uid);
});
