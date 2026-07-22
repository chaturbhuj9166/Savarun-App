import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/outfit_analysis.dart';

/// One saved analysis, plus its document id and timestamp.
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.analysis,
    required this.createdAt,
  });

  final String id;
  final OutfitAnalysis analysis;
  final DateTime? createdAt;
}

/// Live Outfit History for any user.
///
/// The backend writes each analysis to `users/{uid}/outfitHistory` in the same
/// shape the API returns, so [OutfitAnalysis.fromJson] parses it as-is.
/// Firestore rules only let others read this when the profile is public.
final userOutfitHistoryProvider =
    StreamProvider.family<List<HistoryEntry>, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('outfitHistory')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map((d) {
            final data = d.data();
            return HistoryEntry(
              id: d.id,
              analysis: OutfitAnalysis.fromJson(data),
              createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
            );
          }).toList());
});

/// Outfit History for the signed-in user — a thin alias over the family so
/// screens don't each have to look up the current uid.
final outfitHistoryProvider =
    Provider<AsyncValue<List<HistoryEntry>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const AsyncValue.data([]);
  return ref.watch(userOutfitHistoryProvider(uid));
});
