import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../../profile/data/profile_providers.dart';

/// Search filter for the Explore screen.
class ExploreQuery {
  const ExploreQuery({this.style = 'All', this.text = ''});
  final String style;
  final String text;
}

/// Real user search over the `users` collection.
/// - style: equality filter (or 'All')
/// - text : prefix match on the (lowercased) username
/// Excludes the signed-in user from results.
final exploreResultsProvider =
    StreamProvider.family<List<UserProfile>, ExploreQuery>((ref, q) {
  final me = ref.watch(authStateProvider).value?.uid;
  Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('users');

  if (q.style != 'All') {
    query = query.where('style', isEqualTo: q.style);
  }

  final text = q.text.trim().toLowerCase();
  if (text.isNotEmpty) {
    // Prefix match: [text, text + high-code-point).
    final upper = text + String.fromCharCode(0xf8ff);
    query = query
        .orderBy('username')
        .where('username', isGreaterThanOrEqualTo: text)
        .where('username', isLessThanOrEqualTo: upper);
  }

  return query.limit(50).snapshots().map((snap) => snap.docs
      .where((d) => d.id != me)
      .map((d) => UserProfile.fromDoc(d.id, d.data()))
      .toList());
});
