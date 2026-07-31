import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../../profile/data/profile_providers.dart';

/// Users for the Explore screen, filtered by [style] ('All' = no filter).
///
/// Only the style filter runs server-side (a single equality filter, no
/// composite index needed). The text search is applied on the client — this
/// avoids the orderBy + range query that could stall the listener, and lets us
/// match anywhere in the username OR name, not just a prefix.
final exploreUsersProvider =
    StreamProvider.family<List<UserProfile>, String>((ref, style) {
  final me = ref.watch(authStateProvider).value?.uid;

  Query<Map<String, dynamic>> query =
      FirebaseFirestore.instance.collection('users');
  if (style != 'All') {
    query = query.where('style', isEqualTo: style);
  }

  return query.limit(100).snapshots().map((snap) => snap.docs
      .where((d) => d.id != me)
      .map((d) => UserProfile.fromDoc(d.id, d.data()))
      .toList());
});

/// Client-side text match over username + name (case-insensitive, substring).
List<UserProfile> filterUsersByText(List<UserProfile> users, String text) {
  final t = text.trim().toLowerCase();
  if (t.isEmpty) return users;
  return users.where((u) {
    final username = (u.username ?? '').toLowerCase();
    final name = u.name.toLowerCase();
    return username.contains(t) || name.contains(t);
  }).toList();
}
