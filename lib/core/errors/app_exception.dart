/// Custom exception hierarchy for PackWise AI.
///
/// Rather than letting raw [Exception]/[Error] types (SocketException,
/// FormatException, FirebaseAuthException, ...) leak into the UI layer, every
/// service/repository catches low-level errors and re-throws one of these
/// well-typed [AppException]s. Providers can then pattern-match on the
/// concrete subtype to show a precise, user-friendly message.
///
/// Syllabus mapping: OOP (abstraction & inheritance), custom Exception
/// classes, Exception Handling (try/catch/on).
library;

/// Base class for every exception thrown deliberately by PackWise AI code.
///
/// Implements [Exception] (not [Error]) because these represent recoverable,
/// expected failure conditions (bad network, bad input) rather than
/// programmer bugs.
abstract class AppException implements Exception {
  const AppException(this.message, {this.cause});

  /// Human-readable message safe to show directly in the UI.
  final String message;

  /// The original low-level error that triggered this exception, if any —
  /// kept for logging/debugging without being exposed to end users.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when the device has no connectivity or a request timed out.
class NetworkException extends AppException {
  const NetworkException([
    String message = 'No internet connection. Please check your network and try again.',
    Object? cause,
  ]) : super(message, cause: cause);
}

/// Thrown when the Gemini API (or any remote REST API) returns a non-2xx
/// status code, is rate-limited, or refuses the request.
class ApiException extends AppException {
  const ApiException(
    String message, {
    this.statusCode,
    Object? cause,
  }) : super(message, cause: cause);

  /// HTTP status code returned by the API, if available.
  final int? statusCode;

  /// Convenience getter for HTTP 429 "Too Many Requests".
  bool get isRateLimited => statusCode == 429;
}

/// Thrown when the API key required to call Gemini is missing or invalid.
class ApiConfigurationException extends AppException {
  const ApiConfigurationException([
    String message =
        'Gemini API key is not configured. Falling back to offline mode.',
  ]) : super(message);
}

/// Thrown when a JSON payload (from Gemini or Firestore) cannot be parsed
/// into the expected model shape.
class ParsingException extends AppException {
  const ParsingException([
    String message = 'Received an unexpected response format from the server.',
    Object? cause,
  ]) : super(message, cause: cause);
}

/// Thrown when user-supplied form input fails validation before it is ever
/// sent to a service.
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Thrown by [AuthService]/[AuthRepository] for any Firebase Authentication
/// failure (wrong password, email already in use, weak password, etc.).
class AuthException extends AppException {
  const AuthException(super.message, {this.code, super.cause});

  /// The original Firebase Auth error code (e.g. `user-not-found`).
  final String? code;
}

/// Thrown for any Cloud Firestore read/write failure.
class FirestoreException extends AppException {
  const FirestoreException(super.message, {super.cause});
}

/// Generic catch-all for unexpected errors that don't map to a more specific
/// exception type above. Keeping this narrow (used sparingly) preserves the
/// value of the typed hierarchy.
class UnknownAppException extends AppException {
  const UnknownAppException([
    String message = 'Something went wrong. Please try again.',
    Object? cause,
  ]) : super(message, cause: cause);
}
