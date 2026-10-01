import 'package:packwise_ai/core/errors/app_exception.dart';

/// A UI-safe, serializable representation of an [AppException].
///
/// Repositories translate the exception hierarchy (which may carry raw
/// `cause` objects unsuitable for display) into a [Failure] before handing
/// control back to a [ChangeNotifier] provider. This keeps the ViewModel
/// layer free of any knowledge of *how* an error occurred (HTTP, Firebase,
/// parsing, ...) — only *what* went wrong and how to present it.
///
/// Syllabus mapping: OOP (abstract classes), Dart 3 sealed classes & pattern
/// matching, Exception Handling.
sealed class Failure {
  const Failure(this.message);

  final String message;

  /// Maps any caught [Object] (typically an [AppException]) to a concrete
  /// [Failure] subtype so callers can `switch` exhaustively.
  factory Failure.fromException(Object error) {
    return switch (error) {
      NetworkException e => NetworkFailure(e.message),
      ApiConfigurationException e => ConfigurationFailure(e.message),
      ApiException e => ApiFailure(e.message, statusCode: e.statusCode),
      ParsingException e => ParsingFailure(e.message),
      ValidationException e => ValidationFailure(e.message),
      AuthException e => AuthFailure(e.message, code: e.code),
      FirestoreException e => FirestoreFailure(e.message),
      AppException e => UnknownFailure(e.message),
      _ => UnknownFailure(error.toString()),
    };
  }
}

/// Device offline / request timed out.
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Gemini API key missing/invalid — app should offer offline mode.
final class ConfigurationFailure extends Failure {
  const ConfigurationFailure(super.message);
}

/// Remote API returned an error status code.
final class ApiFailure extends Failure {
  const ApiFailure(super.message, {this.statusCode});
  final int? statusCode;

  bool get isRateLimited => statusCode == 429;
}

/// Response body could not be parsed into the expected model.
final class ParsingFailure extends Failure {
  const ParsingFailure(super.message);
}

/// User input failed client-side validation.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Firebase Authentication failure.
final class AuthFailure extends Failure {
  const AuthFailure(super.message, {this.code});
  final String? code;
}

/// Cloud Firestore read/write failure.
final class FirestoreFailure extends Failure {
  const FirestoreFailure(super.message);
}

/// Anything that doesn't fit a more specific bucket above.
final class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

/// A minimal `Result`/`Either`-style wrapper used by repositories so callers
/// are forced (via Dart 3 exhaustive `switch`) to handle both the success and
/// failure paths instead of relying on try/catch at every call site.
///
/// This avoids pulling in a third-party functional-programming package while
/// still teaching the same "railway oriented programming" concept.
sealed class Result<T> {
  const Result();

  /// Convenience constructor for a successful computation.
  const factory Result.success(T data) = Success<T>;

  /// Convenience constructor for a failed computation.
  const factory Result.failure(Failure failure) = ResultError<T>;

  /// Returns `true` if this is a [Success].
  bool get isSuccess => this is Success<T>;

  /// Pattern-matching helper: run [onSuccess] or [onFailure] and return a
  /// unified value of type [R].
  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success<T>(:final data) => onSuccess(data),
      ResultError<T>(:final failure) => onFailure(failure),
    };
  }
}

/// Successful [Result] holding the computed [data].
final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

/// Failed [Result] holding the [Failure] reason.
final class ResultError<T> extends Result<T> {
  const ResultError(this.failure);
  final Failure failure;
}
