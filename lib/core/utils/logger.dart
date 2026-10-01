import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode;

/// Severity levels supported by [AppLogger].
///
/// Syllabus mapping: Enums.
enum LogLevel { debug, info, warning, error }

/// A tiny structured logger wrapping `dart:developer`'s `log()`.
///
/// Using `dart:developer` (instead of `print`) means log lines show up
/// correctly ordered and filterable in DevTools, and are automatically
/// stripped from release performance traces. All logging is a no-op outside
/// [kDebugMode] so we never leak internal details (stack traces, raw API
/// payloads) in a shipped release build.
///
/// Syllabus mapping: Static utility classes, named parameters, Streams &
/// async debugging support.
abstract final class AppLogger {
  const AppLogger._();

  static const String _name = 'PackWiseAI';

  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;

    developer.log(
      message,
      name: _name,
      level: _severityFor(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Maps our [LogLevel] to the integer severity scale `dart:developer`
  /// expects (roughly aligned with `java.util.logging.Level`).
  static int _severityFor(LogLevel level) {
    return switch (level) {
      LogLevel.debug => 500,
      LogLevel.info => 800,
      LogLevel.warning => 900,
      LogLevel.error => 1000,
    };
  }
}
