import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import 'follow_providers.dart';

/// A shared outfit post in the home feed (Module 3) — also the source for the
/// Outfit Inspiration Grid (Module 1, Step 7).
class OutfitPost {
  const OutfitPost({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.authorPhoto,
    required this.imageUrl,
    required this.caption,
    required this.fitScore,
    required this.style,
    required this.likes,
    required this.createdAt,
  });

  final String id;
  final String authorUid;
  final String authorName;
  final String authorPhoto;
  final String imageUrl;
  final String caption;
  final int? fitScore;

  /// Dominant style category (e.g. "Streetwear"), used to find similar looks.
  final String? style;

  /// Popularity — number of likes.
  final int likes;
  final DateTime? createdAt;

  factory OutfitPost.fromDoc(String id, Map<String, dynamic> d) => OutfitPost(
        id: id,
        authorUid: d['authorUid'] ?? '',
        authorName: d['authorName'] ?? 'Savarun User',
        authorPhoto: d['authorPhoto'] ?? '',
        imageUrl: d['imageUrl'] ?? '',
        caption: d['caption'] ?? '',
        fitScore: d['fitScore'] as int?,
        style: d['style'] as String?,
        likes: (d['likes'] ?? 0) as int,
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
    String? style,
  }) {
    return _posts.add({
      'authorUid': authorUid,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'imageUrl': imageUrl,
      'caption': caption,
      'fitScore': fitScore,
      'style': style,
      'likes': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String id) => _posts.doc(id).delete();

  /// Toggle a like via the backend, which atomically updates the post's count.
  Future<void> toggleLike(String postId, bool like) async {
    await const ApiClient()
        .post('${AppConfig.backendBaseUrl}/api/posts/$postId/like', {'like': like});
  }
}

/// Whether the signed-in user has liked [postId] — drives the like button.
final hasLikedProvider =
    StreamProvider.family<bool, String>((ref, postId) {
  final me = FirebaseAuth.instance.currentUser?.uid;
  if (me == null) return Stream.value(false);
  return FirebaseFirestore.instance
      .collection('postLikes')
      .doc('${postId}_$me')
      .snapshots()
      .map((s) => s.exists);
});

/// The Outfit Inspiration Grid (Module 1, Step 7): other users' shared outfits
/// in the same dominant style, most popular first. Excludes the viewer's own.
final inspirationByStyleProvider =
    StreamProvider.family<List<OutfitPost>, String>((ref, style) {
  final me = FirebaseAuth.instance.currentUser?.uid;
  return FirebaseFirestore.instance
      .collection('posts')
      .where('style', isEqualTo: style)
      .orderBy('likes', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => OutfitPost.fromDoc(d.id, d.data()))
          .where((p) => p.authorUid != me)
          .toList());
});

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
