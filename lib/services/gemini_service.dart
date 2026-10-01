import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:packwise_ai/core/constants/api_constants.dart';
import 'package:packwise_ai/core/errors/app_exception.dart';
import 'package:packwise_ai/core/utils/logger.dart';
import 'package:packwise_ai/data/models/food_commodity.dart';
import 'package:packwise_ai/data/models/packaging_material.dart';

/// Thin REST client around the Google Gemini `generateContent` API.
///
/// This class only knows about HTTP + JSON — it has no knowledge of
/// [Recommendation] parsing (that belongs to [RecommendationRepository]) and
/// no knowledge of Firestore/offline fallback (that's orchestrated one layer
/// up). Keeping it this narrow makes it trivial to mock in unit tests via
/// the injectable [http.Client].
///
/// Syllabus mapping: REST API integration, async/await, Future, Exception
/// Handling, JSON encode/decode.
class GeminiService {
  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Requests top-3 packaging material recommendations for [commodity].
  ///
  /// Returns the *decoded* JSON map produced by the model (already stripped
  /// of any Markdown code-fence wrapper). Throws:
  /// - [ApiConfigurationException] if no API key is configured.
  /// - [NetworkException] on connectivity/timeout failure.
  /// - [ApiException] on a non-2xx HTTP response.
  /// - [ParsingException] if the model's text cannot be parsed as JSON.
  Future<Map<String, dynamic>> generateRecommendation(
    FoodCommodity commodity,
  ) async {
    if (!ApiConstants.hasApiKey) {
      throw const ApiConfigurationException();
    }

    final Uri url = Uri.parse(
      '${ApiConstants.geminiGenerateContentUrl}?key=${ApiConstants.geminiApiKey}',
    );
    final Map<String, dynamic> body = <String, dynamic>{
      'contents': <Map<String, dynamic>>[
        <String, dynamic>{
          'parts': <Map<String, String>>[
            <String, String>{'text': _buildPrompt(commodity)},
          ],
        },
      ],
      'generationConfig': <String, dynamic>{
        'temperature': 0.4,
        'responseMimeType': 'application/json',
      },
    };

    http.Response response = await _postWithRetry(url, body);

    if (response.statusCode != 200) {
      throw ApiException(
        _extractApiErrorMessage(response.body) ??
            'Gemini API request failed (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    final String modelText = _extractModelText(response.body);
    return _parseJsonText(modelText);
  }

  /// Performs the POST with a small linear-backoff retry loop for transient
  /// network errors and 5xx/429 responses — a single flaky request should
  /// not force the user all the way down to offline mode.
  Future<http.Response> _postWithRetry(
    Uri url,
    Map<String, dynamic> body,
  ) async {
    int attempt = 0;
    while (true) {
      try {
        final http.Response response = await _client
            .post(url, headers: ApiConstants.jsonHeaders, body: jsonEncode(body))
            .timeout(ApiConstants.requestTimeout);

        final bool isTransientFailure =
            response.statusCode >= 500 || response.statusCode == 429;
        if (isTransientFailure && attempt < ApiConstants.maxRetries) {
          attempt++;
          AppLogger.warning(
            'Gemini request failed with ${response.statusCode}, retrying '
            '($attempt/${ApiConstants.maxRetries})...',
          );
          await Future<void>.delayed(ApiConstants.retryBackoff * attempt);
          continue;
        }
        return response;
      } on SocketException catch (e, stackTrace) {
        if (attempt < ApiConstants.maxRetries) {
          attempt++;
          await Future<void>.delayed(ApiConstants.retryBackoff * attempt);
          continue;
        }
        AppLogger.error('Gemini request: no network', error: e, stackTrace: stackTrace);
        throw const NetworkException();
      } on TimeoutException catch (e, stackTrace) {
        if (attempt < ApiConstants.maxRetries) {
          attempt++;
          await Future<void>.delayed(ApiConstants.retryBackoff * attempt);
          continue;
        }
        AppLogger.error('Gemini request timed out', error: e, stackTrace: stackTrace);
        throw const NetworkException('The request timed out. Please try again.');
      } on HttpException catch (e, stackTrace) {
        AppLogger.error('Gemini HTTP error', error: e, stackTrace: stackTrace);
        throw NetworkException(e.message, e);
      }
    }
  }

  /// Extracts `candidates[0].content.parts[0].text` from a raw Gemini
  /// response body, throwing [ParsingException] if the expected shape is
  /// missing (e.g. the response was blocked by a safety filter).
  String _extractModelText(String rawBody) {
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(rawBody) as Map<String, dynamic>;
      final List<dynamic>? candidates = decoded['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const ParsingException(
          'Gemini returned no candidates (the request may have been blocked).',
        );
      }
      final Map<String, dynamic> content =
          (candidates.first as Map<String, dynamic>)['content'] as Map<String, dynamic>;
      final List<dynamic> parts = content['parts'] as List<dynamic>;
      return (parts.first as Map<String, dynamic>)['text'] as String;
    } on ParsingException {
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to extract Gemini model text', error: e, stackTrace: stackTrace);
      throw ParsingException('Unexpected Gemini response shape.', e);
    }
  }

  /// Parses [text] as JSON, first stripping a Markdown ```` ```json ```` code
  /// fence if the model ignored the `responseMimeType` hint and wrapped its
  /// answer anyway (a common real-world Gemini quirk).
  Map<String, dynamic> _parseJsonText(String text) {
    String cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '')
          .replaceFirst(RegExp(r'```\s*$'), '')
          .trim();
    }
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } on FormatException catch (e, stackTrace) {
      AppLogger.error('Failed to parse Gemini JSON payload', error: e, stackTrace: stackTrace);
      throw ParsingException('Could not parse the AI response as JSON.', e);
    }
  }

  /// Best-effort extraction of a human-readable error message from a Gemini
  /// error response body, e.g. `{"error": {"message": "API key not valid"}}`.
  String? _extractApiErrorMessage(String rawBody) {
    try {
      final Map<String, dynamic> decoded = jsonDecode(rawBody) as Map<String, dynamic>;
      final Map<String, dynamic>? error = decoded['error'] as Map<String, dynamic>?;
      return error?['message'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Builds the natural-language + strict-JSON-schema instruction prompt
  /// sent to Gemini for a given [commodity].
  String _buildPrompt(FoodCommodity commodity) {
    final String allowedTypes =
        MaterialType.values.map((MaterialType t) => t.name).join(', ');

    return '''
You are a food packaging science expert. Analyze the following food commodity
and recommend the TOP 3 best packaging materials from this exact list only:
$allowedTypes.

Commodity properties:
- Name: ${commodity.name}
- Category: ${commodity.category.label}
- Moisture: ${commodity.moisturePercent}%
- Fat content: ${commodity.fatPercent}%
- pH: ${commodity.ph}
- Respiration rate: ${commodity.respirationRateMlCo2PerKgPerHr} mL CO2/kg/hr
- Desired shelf life: ${commodity.desiredShelfLifeDays} days
- Storage temperature: ${commodity.storageTemperatureCelsius}°C
- Storage humidity: ${commodity.storageHumidityPercent}%
- Storage type: ${commodity.storageType.label}

Respond with ONLY strict JSON (no Markdown, no commentary) matching exactly
this schema:
{
  "materials": [
    {
      "rank": 1,
      "materialType": "<one of: $allowedTypes>",
      "recommendedThicknessMicrons": <number>,
      "predictedOtrCm3M2Day": <number>,
      "predictedWvtrGM2Day": <number>,
      "mapGasRatioPercent": {"co2": <number>, "o2": <number>, "n2": <number>},
      "predictedShelfLifeDays": <integer>,
      "confidenceScore": <number between 0 and 1>,
      "aiRationale": "<max 200 characters explaining the choice>"
    }
  ]
}
The "materials" array must contain exactly 3 entries, ranked 1 to 3.
''';
  }

  /// Releases the underlying HTTP client's resources.
  void dispose() => _client.close();
}
