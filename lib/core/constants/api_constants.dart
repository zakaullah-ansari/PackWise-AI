/// API-related constants for the PackWise AI application.
///
/// Centralizing endpoint URLs, model identifiers, and network tuning
/// parameters here means the rest of the codebase never hard-codes a raw
/// string URL — a single source of truth that is easy to audit and update.
///
/// Syllabus mapping: Encapsulation, static/const members, REST API basics.
library;

/// Configuration and endpoints for the Google Gemini Generative Language API.
abstract final class ApiConstants {
  // Private constructor prevents instantiation of this constants-only class.
  const ApiConstants._();

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

  /// API key injected at build/run time via `--dart-define=GEMINI_API_KEY=...`
  ///
  /// We deliberately avoid hard-coding secrets in source. When the key is
  /// missing (e.g. a student clones the repo without configuring it), the
  /// app transparently falls back to [LocalFallbackService] so the demo
  /// still works end-to-end offline.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

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
