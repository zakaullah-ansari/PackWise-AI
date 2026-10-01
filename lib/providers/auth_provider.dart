import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';
import 'package:packwise_ai/data/repositories/auth_repository.dart';

/// The three states the authentication flow can be in.
///
/// Syllabus mapping: Enums as a finite state machine.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// MVVM ViewModel exposing Firebase Authentication state and actions to the
/// View layer (`SplashView`, `LoginView`, `SignupView`, `HomeView`).
///
/// Subscribes once to [AuthRepository.authStateChanges] for the lifetime of
/// the provider and cancels the subscription in [dispose] to avoid leaking a
/// [StreamSubscription] — a common interview/exam question in the "Streams"
/// syllabus unit.
///
/// Syllabus mapping: State Management (ChangeNotifier), Streams, Firebase
/// Auth, async/await, Exception Handling (via [Result]).
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository() {
    _authSubscription = _repository.authStateChanges.listen(_onAuthStateChanged);
  }

  final AuthRepository _repository;
  late final StreamSubscription<User?> _authSubscription;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  bool _isSubmitting = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void _onAuthStateChanged(User? user) {
    _user = user;
    _status = user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _beginSubmit();
    final bool success = (await _repository.signIn(email: email, password: password)).when(
      onSuccess: (User user) => true,
      onFailure: (failure) {
        _errorMessage = failure.message;
        return false;
      },
    );
    _endSubmit();
    return success;
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _beginSubmit();
    final bool success = (await _repository.signUp(
      email: email,
      password: password,
      displayName: displayName,
    ))
        .when(
      onSuccess: (User user) => true,
      onFailure: (failure) {
        _errorMessage = failure.message;
        return false;
      },
    );
    _endSubmit();
    return success;
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _beginSubmit();
    final bool success = (await _repository.sendPasswordResetEmail(email)).when(
      onSuccess: (_) => true,
      onFailure: (failure) {
        _errorMessage = failure.message;
        return false;
      },
    );
    _endSubmit();
    return success;
  }

  Future<void> logout() async {
    _beginSubmit();
    await _repository.signOut();
    _endSubmit();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _beginSubmit() {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _endSubmit() {
    _isSubmitting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_authSubscription.cancel());
    super.dispose();
  }
}
