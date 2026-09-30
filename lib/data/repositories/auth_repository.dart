import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:packwise_ai/core/errors/app_exception.dart';
import 'package:packwise_ai/core/errors/failure.dart';
import 'package:packwise_ai/services/auth_service.dart';

/// Domain-level facade over [AuthService] returning [Result]s instead of
/// throwing, so [AuthProvider] can drive UI state purely by pattern-matching
/// on `Success`/`ResultError` without a try/catch at every call site.
///
/// Syllabus mapping: Repository pattern, Firebase Auth, Dart 3 sealed-class
/// `Result` pattern matching.
class AuthRepository {
  AuthRepository({AuthService? authService}) : _authService = authService ?? AuthService();

  final AuthService _authService;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  User? get currentUser => _authService.currentUser;

  Future<Result<User>> signIn({required String email, required String password}) async {
    try {
      final User? user = await _authService.signInWithEmail(email: email, password: password);
      if (user == null) {
        return const Result<User>.failure(AuthFailure('Sign-in failed. Please try again.'));
      }
      return Result<User>.success(user);
    } on AppException catch (e) {
      return Result<User>.failure(Failure.fromException(e));
    }
  }

  Future<Result<User>> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final User? user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      if (user == null) {
        return const Result<User>.failure(AuthFailure('Sign-up failed. Please try again.'));
      }
      return Result<User>.success(user);
    } on AppException catch (e) {
      return Result<User>.failure(Failure.fromException(e));
    }
  }

  Future<Result<bool>> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return const Result<bool>.success(true);
    } on AppException catch (e) {
      return Result<bool>.failure(Failure.fromException(e));
    }
  }

  Future<Result<bool>> signOut() async {
    try {
      await _authService.signOut();
      return const Result<bool>.success(true);
    } on AppException catch (e) {
      return Result<bool>.failure(Failure.fromException(e));
    }
  }
}
