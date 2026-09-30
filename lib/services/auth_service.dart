import 'package:firebase_auth/firebase_auth.dart';
import 'package:packwise_ai/core/errors/app_exception.dart';
import 'package:packwise_ai/core/utils/logger.dart';

/// Thin wrapper around [FirebaseAuth] translating every
/// [FirebaseAuthException] into a user-friendly [AuthException].
///
/// Syllabus mapping: Firebase Auth, Streams (`authStateChanges`), Exception
/// Handling, async/await.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  /// Real-time stream of the current authenticated user (or `null` when
  /// signed out) — consumed by [AuthProvider] to drive the splash-screen
  /// redirect and route guarding.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      return credential.user;
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error('Sign-in failed', error: e, stackTrace: stackTrace);
      throw AuthException(_messageForAuthCode(e.code), code: e.code, cause: e);
    }
  }

  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email.trim(), password: password);
      if (displayName.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
      }
      return credential.user;
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error('Sign-up failed', error: e, stackTrace: stackTrace);
      throw AuthException(_messageForAuthCode(e.code), code: e.code, cause: e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error('Password reset failed', error: e, stackTrace: stackTrace);
      throw AuthException(_messageForAuthCode(e.code), code: e.code, cause: e);
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error('Sign-out failed', error: e, stackTrace: stackTrace);
      throw AuthException(_messageForAuthCode(e.code), code: e.code, cause: e);
    }
  }

  /// Maps common Firebase Auth error codes to friendly, actionable copy.
  String _messageForAuthCode(String code) {
    return switch (code) {
      'user-not-found' => 'No account found for that email address.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'invalid-credential' => 'Incorrect email or password.',
      'email-already-in-use' => 'An account already exists for that email.',
      'invalid-email' => 'That email address looks invalid.',
      'weak-password' => 'Password is too weak — use at least 6 characters.',
      'network-request-failed' =>
        'Network error. Please check your connection and try again.',
      'too-many-requests' => 'Too many attempts. Please wait and try again.',
      _ => 'Authentication failed. Please try again.',
    };
  }
}
