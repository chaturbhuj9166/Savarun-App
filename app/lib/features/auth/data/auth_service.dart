import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Wraps Firebase Auth for Savarun — Google, Apple and Phone OTP — and makes sure a
/// matching `users/{uid}` profile document exists in Firestore on first login.
class AuthService {
  AuthService(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── Google ──
  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    final cred = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    await _ensureUserDoc(cred.user);
  }

  // ── Apple ──
  /// Requires the Apple provider to be enabled in the Firebase console
  /// (and an Apple Developer account for the native iOS flow).
  Future<void> signInWithApple() async {
    final provider = AppleAuthProvider()..addScope('email')..addScope('name');
    final cred = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    await _ensureUserDoc(cred.user);
  }

  // ── Phone OTP (web) ──
  /// Web sends the SMS and returns a confirmation object you later `.confirm()`.
  Future<ConfirmationResult> sendOtpWeb(String phoneE164) {
    return _auth.signInWithPhoneNumber(phoneE164);
  }

  Future<void> confirmOtpWeb(ConfirmationResult result, String smsCode) async {
    final cred = await result.confirm(smsCode);
    await _ensureUserDoc(cred.user);
  }

  // ── Phone OTP (mobile) ──
  Future<void> sendOtpMobile(
    String phoneE164, {
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException e) onFailed,
    void Function(PhoneAuthCredential cred)? onAutoVerified,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      verificationCompleted: (cred) async {
        await _auth.signInWithCredential(cred);
        await _ensureUserDoc(_auth.currentUser);
        onAutoVerified?.call(cred);
      },
      verificationFailed: onFailed,
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> confirmOtpMobile(String verificationId, String smsCode) async {
    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCred = await _auth.signInWithCredential(cred);
    await _ensureUserDoc(userCred.user);
  }

  Future<void> signOut() => _auth.signOut();

  /// Create the user's profile doc the first time they sign in.
  Future<void> _ensureUserDoc(User? user) async {
    if (user == null) return;
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'uid': user.uid,
      'name': user.displayName ?? 'Savarun User',
      'email': user.email,
      'phone': user.phoneNumber,
      'photoURL': user.photoURL,
      'bio': '',
      'style': null,
      'wardrobePublic': true,
      'followers': 0,
      'following': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
