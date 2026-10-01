import 'package:flutter_test/flutter_test.dart';
import 'package:packwise_ai/core/errors/app_exception.dart';
import 'package:packwise_ai/data/models/food_commodity.dart';
import 'package:packwise_ai/data/repositories/recommendation_repository.dart';
import 'package:packwise_ai/providers/recommendation_provider.dart';
import 'package:packwise_ai/services/gemini_service.dart';

/// A [GeminiService] stand-in that returns a canned, well-formed response
/// without making any real HTTP calls — demonstrating dependency injection
/// for testability (every service/repository constructor accepts an
/// injectable collaborator for exactly this reason).
class _FakeSuccessfulGeminiService extends GeminiService {
  @override
  Future<Map<String, dynamic>> generateRecommendation(FoodCommodity commodity) async {
    return <String, dynamic>{
      'materials': <dynamic>[
        <String, dynamic>{
          'rank': 1,
          'materialType': 'pet',
          'recommendedThicknessMicrons': 30,
          'predictedOtrCm3M2Day': 10.0,
          'predictedWvtrGM2Day': 2.0,
          'mapGasRatioPercent': <String, dynamic>{'co2': 5, 'o2': 3, 'n2': 92},
          'predictedShelfLifeDays': 20,
          'confidenceScore': 0.9,
          'aiRationale': 'Great clarity and barrier for this commodity.',
        },
        <String, dynamic>{
          'rank': 2,
          'materialType': 'ldpe',
          'recommendedThicknessMicrons': 40,
          'predictedOtrCm3M2Day': 800.0,
          'predictedWvtrGM2Day': 8.0,
          'mapGasRatioPercent': <String, dynamic>{'co2': 5, 'o2': 3, 'n2': 92},
          'predictedShelfLifeDays': 14,
          'confidenceScore': 0.7,
          'aiRationale': 'Breathable option for fresh produce.',
        },
      ],
    };
  }
}

/// A [GeminiService] stand-in that always fails, to prove the repository's
/// automatic offline-fallback path (exercised through the provider's public
/// API, not by calling the repository directly).
class _FakeFailingGeminiService extends GeminiService {
  @override
  Future<Map<String, dynamic>> generateRecommendation(FoodCommodity commodity) async {
    throw const ApiException('Simulated API outage', statusCode: 503);
  }
}

void main() {
  group('RecommendationProvider.requestRecommendation', () {
    test('transitions idle -> loading -> success with a well-formed AI response', () async {
      final RecommendationProvider provider = RecommendationProvider(
        repository: RecommendationRepository(geminiService: _FakeSuccessfulGeminiService()),
      );

      expect(provider.state, RecommendationViewState.idle);

      final Future<void> future = provider.requestRecommendation(FoodCommodity.empty());
      expect(provider.state, RecommendationViewState.loading);

      await future;

      expect(provider.state, RecommendationViewState.success);
      expect(provider.recommendation, isNotNull);
      expect(provider.recommendation!.materials.length, 2);
      expect(provider.recommendation!.isOfflineFallback, isFalse);
    });

    test('falls back to the offline engine and still reaches success when Gemini fails', () async {
      final RecommendationProvider provider = RecommendationProvider(
        repository: RecommendationRepository(geminiService: _FakeFailingGeminiService()),
      );

      await provider.requestRecommendation(FoodCommodity.empty());

      expect(provider.state, RecommendationViewState.success);
      expect(provider.recommendation, isNotNull);
      expect(provider.recommendation!.isOfflineFallback, isTrue);
      expect(provider.errorMessage, isNull);
    });

    test('ignores a second concurrent submit while already loading', () async {
      final RecommendationProvider provider = RecommendationProvider(
        repository: RecommendationRepository(geminiService: _FakeSuccessfulGeminiService()),
      );

      final Future<void> first = provider.requestRecommendation(FoodCommodity.empty());
      final Future<void> second = provider.requestRecommendation(FoodCommodity.empty());

      await Future.wait(<Future<void>>[first, second]);
      expect(provider.state, RecommendationViewState.success);
    });
  });

  group('RecommendationProvider.reset', () {
    test('clears recommendation/error state back to idle', () async {
      final RecommendationProvider provider = RecommendationProvider(
        repository: RecommendationRepository(geminiService: _FakeSuccessfulGeminiService()),
      );
      await provider.requestRecommendation(FoodCommodity.empty());
      expect(provider.state, RecommendationViewState.success);

      provider.reset();

      expect(provider.state, RecommendationViewState.idle);
      expect(provider.recommendation, isNull);
      expect(provider.errorMessage, isNull);
    });
  });
}
