import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import 'outfit_models.dart';

final outfitRepoProvider = Provider((ref) => OutfitRepository());

class OutfitRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('outfits');

  Stream<List<OutfitSet>> watch(String uid) {
    return _col(uid).orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => OutfitSet.fromDoc(d.id, d.data())).toList(),
        );
  }

  Future<void> add(String uid, OutfitSet outfit) => _col(uid).add(outfit.toMap());

  Future<void> delete(String uid, String outfitId) => _col(uid).doc(outfitId).delete();
}

/// Live list of the signed-in user's saved outfit sets.
final outfitsProvider = StreamProvider<List<OutfitSet>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(outfitRepoProvider).watch(user.uid);
});
