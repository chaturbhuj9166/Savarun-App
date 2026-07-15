import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';

/// Style options a user can pick as their aesthetic (spec: Streetwear, etc.).
const kStyles = ['Streetwear', 'Minimalist', 'Classic', 'Athleisure', 'Formal', 'Casual'];

/// A Savarun user profile. Built either from the current Firebase Auth user
/// (merged with their Firestore doc) or from any user's Firestore doc.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.username,
    required this.handle,
    required this.email,
    required this.phone,
    required this.photoURL,
    required this.bio,
    required this.style,
    required this.wardrobePublic,
  });

  final String uid;
  final String name;
  final String? username;
  final String handle; // display handle, e.g. @username
  final String? email;
  final String? phone;
  final String? photoURL;
  final String bio;
  final String? style;
  final bool wardrobePublic;

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : 'S';

  static String _handle({String? username, String? email, String? phone, required String uid}) {
    if (username != null && username.isNotEmpty) return '@$username';
    if (email != null && email.contains('@')) return '@${email.split('@').first}';
    if (phone != null && phone.length >= 4) return '@user${phone.substring(phone.length - 4)}';
    return '@${uid.substring(0, uid.length < 6 ? uid.length : 6)}';
  }

  static String _bio(Map<String, dynamic>? doc) =>
      (doc?['bio'] as String?)?.trim().isNotEmpty == true
          ? doc!['bio']
          : 'Building my style with Savarun ✨';

  /// Current signed-in user: merge live Auth identity with the Firestore doc.
  factory UserProfile.from(User user, Map<String, dynamic>? doc) {
    final username = doc?['username'] as String?;
    final email = user.email ?? doc?['email'];
    final phone = user.phoneNumber ?? doc?['phone'];
    return UserProfile(
      uid: user.uid,
      name: user.displayName ?? doc?['name'] ?? 'Savarun User',
      username: username,
      handle: _handle(username: username, email: email, phone: phone, uid: user.uid),
      email: email,
      phone: phone,
      photoURL: (doc?['photoURL'] as String?)?.isNotEmpty == true ? doc!['photoURL'] : user.photoURL,
      bio: _bio(doc),
      style: doc?['style'],
      wardrobePublic: doc?['wardrobePublic'] ?? true,
    );
  }

  /// Any user, built purely from their Firestore doc (for other profiles).
  factory UserProfile.fromDoc(String uid, Map<String, dynamic> doc) {
    final username = doc['username'] as String?;
    return UserProfile(
      uid: uid,
      name: doc['name'] ?? 'Savarun User',
      username: username,
      handle: _handle(username: username, email: doc['email'], phone: doc['phone'], uid: uid),
      email: doc['email'],
      phone: doc['phone'],
      photoURL: doc['photoURL'],
      bio: _bio(doc),
      style: doc['style'],
      wardrobePublic: doc['wardrobePublic'] ?? true,
    );
  }
}

/// Live profile of the signed-in user (rebuilds when the Firestore doc changes).
final myProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(authUser.uid)
      .snapshots()
      .map((snap) => UserProfile.from(authUser, snap.data()));
});

/// Live profile of any user by uid (for viewing other people).
final userByUidProvider = StreamProvider.family<UserProfile?, String>((ref, uid) {
  return FirebaseFirestore.instance.collection('users').doc(uid).snapshots().map(
        (snap) => snap.exists ? UserProfile.fromDoc(uid, snap.data()!) : null,
      );
});

final profileRepoProvider = Provider((ref) => ProfileRepository());

class ProfileRepository {
  final _db = FirebaseFirestore.instance;

  Future<void> setWardrobePublic(String uid, bool isPublic) {
    return _db.collection('users').doc(uid).update({'wardrobePublic': isPublic});
  }

  Future<void> setPhotoURL(String uid, String url) {
    return _db.collection('users').doc(uid).update({'photoURL': url});
  }

  /// Update editable profile fields. Username is stored lowercased for search.
  Future<void> updateProfile(
    String uid, {
    required String name,
    required String bio,
    required String username,
    required String style,
  }) {
    return _db.collection('users').doc(uid).set({
      'name': name.trim(),
      'bio': bio.trim(),
      'username': username.trim().toLowerCase(),
      'style': style,
    }, SetOptions(merge: true));
  }
}
