/// API-related constants for the PackWise AI application.
///
/// Centralizing endpoint URLs, model identifiers, and network tuning
/// parameters here means the rest of the codebase never hard-codes a raw
/// string URL — a single source of truth that is easy to audit and update.
///
/// Syllabus mapping: Encapsulation, static/const members, REST API basics,
/// Exception-safe configuration resolution.
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration and endpoints for the Google Gemini Generative Language API.
abstract final class ApiConstants {
  // Private constructor prevents instantiation of this constants-only class.
  const ApiConstants._();

  /// The literal placeholder shipped in `.env.example`. If a developer
  /// copies that file to `.env` without editing it, this sentinel lets us
  /// treat the key as "not configured" rather than sending a doomed request
  /// to Gemini with the literal string "YOUR_GEMINI_API_KEY" as the key.
  static const String _placeholderSentinel = 'YOUR_GEMINI_API_KEY';

  /// Base host for the Gemini REST API (v1beta Generative Language API).
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  /// The Gemini model used for packaging recommendations.
  ///
  /// `gemini-1.5-flash` is chosen for its low latency and generous free-tier
  /// rate limits, which suits a hackathon demo / workshop classroom setting.
  static const String geminiModel = 'gemini-1.5-flash';

  /// Full `generateContent` endpoint for [geminiModel].
  static String get geminiGenerateContentUrl =>
      '$geminiBaseUrl/models/$geminiModel:generateContent';

  /// Compile-time fallback injected via `--dart-define=GEMINI_API_KEY=...`
  /// (preferred for CI/production — it never touches disk as a bundled
  /// asset the way a `.env` file does).
  static const String _dartDefineApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Resolves the Gemini API key at runtime, preferring (in order):
  /// 1. `GEMINI_API_KEY` from a local `.env` file (see `.env.example`) —
  ///    the most convenient option for local development.
  /// 2. `--dart-define=GEMINI_API_KEY=...` — the recommended option for
  ///    CI/production builds.
  /// 3. An empty string, which [hasApiKey] treats as "not configured",
  ///    causing the app to transparently fall back to
  ///    [LocalFallbackService] so the demo still works end-to-end offline.
  ///
  /// We deliberately avoid hard-coding secrets in source. Reading `.env` is
  /// wrapped in a `try`/`catch` because `dotenv.load()` may not have been
  /// called (or the `.env` file may not exist, e.g. a fresh clone before
  /// the developer runs `cp .env.example .env`) — either case degrades
  /// gracefully to the dart-define/offline fallback rather than throwing.
  static String get geminiApiKey {
    String fromDotEnv = '';
    try {
      fromDotEnv = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    } catch (_) {
      // dotenv was never loaded (no .env file present) — that's fine.
      fromDotEnv = '';
    }

    if (fromDotEnv.isNotEmpty && fromDotEnv != _placeholderSentinel) {
      return fromDotEnv;
    }
    return _dartDefineApiKey;
  }

  /// Whether a Gemini API key has been configured for this build.
  static bool get hasApiKey => geminiApiKey.trim().isNotEmpty;

  /// Network timeout applied to every Gemini HTTP request.
  static const Duration requestTimeout = Duration(seconds: 20);

  /// Number of automatic retries on transient network/5xx failures.
  static const int maxRetries = 2;

  /// Delay between retry attempts (simple linear backoff multiplier).
  static const Duration retryBackoff = Duration(seconds: 2);

  /// HTTP header keys/values shared by all requests.
  static const Map<String, String> jsonHeaders = <String, String>{
    'Content-Type': 'application/json',
  };
}
