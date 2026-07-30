import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'follow_providers.dart';

/// A shared outfit post in the home feed (Module 3).
class OutfitPost {
  const OutfitPost({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.authorPhoto,
    required this.imageUrl,
    required this.caption,
    required this.fitScore,
    required this.createdAt,
  });

  final String id;
  final String authorUid;
  final String authorName;
  final String authorPhoto;
  final String imageUrl;
  final String caption;
  final int? fitScore;
  final DateTime? createdAt;

  factory OutfitPost.fromDoc(String id, Map<String, dynamic> d) => OutfitPost(
        id: id,
        authorUid: d['authorUid'] ?? '',
        authorName: d['authorName'] ?? 'Savarun User',
        authorPhoto: d['authorPhoto'] ?? '',
        imageUrl: d['imageUrl'] ?? '',
        caption: d['caption'] ?? '',
        fitScore: d['fitScore'] as int?,
        createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      );
}

final feedRepoProvider = Provider((ref) => FeedRepository());

class FeedRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posts');

  Future<void> createPost({
    required String authorUid,
    required String authorName,
    required String authorPhoto,
    required String imageUrl,
    required String caption,
    int? fitScore,
  }) {
    return _posts.add({
      'authorUid': authorUid,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'imageUrl': imageUrl,
      'caption': caption,
      'fitScore': fitScore,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String id) => _posts.doc(id).delete();
}

/// The signed-in user's home feed: posts by people they follow, plus their
/// own. Firestore `whereIn` caps at 30 ids, which is plenty for this stage;
/// beyond that we'd page, but the feed stays correct for the first 30 follows.
final homeFeedProvider = StreamProvider<List<OutfitPost>>((ref) {
  final me = FirebaseAuth.instance.currentUser?.uid;
  if (me == null) return Stream.value(const []);

  // Rebuild the feed whenever the following list changes.
  final following = ref.watch(followingUidsProvider(me)).value ?? const [];
  final authors = <String>{me, ...following}.take(30).toList();

  return FirebaseFirestore.instance
      .collection('posts')
      .where('authorUid', whereIn: authors)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => OutfitPost.fromDoc(d.id, d.data())).toList());
});

/// A single user's own posts — used on their profile grid.
final userPostsProvider =
    StreamProvider.family<List<OutfitPost>, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('posts')
      .where('authorUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => OutfitPost.fromDoc(d.id, d.data())).toList());
});
