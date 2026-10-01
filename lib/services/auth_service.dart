import 'package:firebase_auth/firebase_auth.dart';
import 'package:packwise_ai/core/errors/app_exception.dart';
import 'package:packwise_ai/core/utils/logger.dart';

/// Thin wrapper around [FirebaseAuth] translating every
/// [FirebaseAuthException] into a user-friendly [AuthException].
///
/// [_firebaseAuth] resolves [FirebaseAuth.instance] **lazily** (via a getter)
/// rather than eagerly in the constructor's initializer list. This matters:
/// if Firebase has not been initialized (e.g. a student runs the app before
/// `flutterfire configure`), accessing `FirebaseAuth.instance` throws. If
/// that happened inside the constructor, simply *creating* an [AuthService]
/// — which happens unconditionally at app startup via [AuthProvider] — would
/// crash the entire app before any UI could render. By deferring the lookup
/// until a method is actually called, the failure happens *inside* a
/// `try`/`catch`, where it is caught and converted into a friendly
/// [AuthException] instead of an unhandled crash.
///
/// Syllabus mapping: Firebase Auth, Streams (`authStateChanges`), Exception
/// Handling (defensive lazy initialization), async/await.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth}) : _injectedAuth = firebaseAuth;

  /// Explicitly injected instance (used by tests); `null` in production,
  /// where [_firebaseAuth] falls back to the real [FirebaseAuth.instance].
  final FirebaseAuth? _injectedAuth;

  FirebaseAuth get _firebaseAuth => _injectedAuth ?? FirebaseAuth.instance;

  /// Real-time stream of the current authenticated user (or `null` when
  /// signed out) — consumed by [AuthProvider] to drive the splash-screen
  /// redirect and route guarding.
  ///
  /// Wrapped so that a Firebase-not-configured failure surfaces as an empty
  /// stream (treated as "signed out") rather than throwing synchronously
  /// from a getter, which [AuthProvider] cannot easily guard with try/catch
  /// since it's consumed via `.listen(...)`.
  Stream<User?> get authStateChanges {
    try {
      return _firebaseAuth.authStateChanges();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Could not subscribe to Firebase auth state — is Firebase configured?',
        error: e,
        stackTrace: stackTrace,
      );
      return Stream<User?>.value(null);
    }
  }

  User? get currentUser {
    try {
      return _firebaseAuth.currentUser;
    } catch (_) {
      return null;
    }
  }

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
    } catch (e, stackTrace) {
      AppLogger.error('Sign-in failed unexpectedly', error: e, stackTrace: stackTrace);
      throw const AuthException(
        'Could not sign in — please check your Firebase configuration.',
      );
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
    } catch (e, stackTrace) {
      AppLogger.error('Sign-up failed unexpectedly', error: e, stackTrace: stackTrace);
      throw const AuthException(
        'Could not create your account — please check your Firebase configuration.',
      );
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error('Password reset failed', error: e, stackTrace: stackTrace);
      throw AuthException(_messageForAuthCode(e.code), code: e.code, cause: e);
    } catch (e, stackTrace) {
      AppLogger.error('Password reset failed unexpectedly', error: e, stackTrace: stackTrace);
      throw const AuthException('Could not send the password reset email.');
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error('Sign-out failed', error: e, stackTrace: stackTrace);
      throw AuthException(_messageForAuthCode(e.code), code: e.code, cause: e);
    } catch (e, stackTrace) {
      // Signing out should never block the UI — log and swallow.
      AppLogger.warning('Sign-out encountered an error (ignored)', error: e, stackTrace: stackTrace);
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
