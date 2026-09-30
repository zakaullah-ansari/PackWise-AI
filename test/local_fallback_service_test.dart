import 'package:flutter_test/flutter_test.dart';
import 'package:packwise_ai/data/models/food_commodity.dart';
import 'package:packwise_ai/data/models/recommendation.dart';
import 'package:packwise_ai/services/local_fallback_service.dart';

void main() {
  final LocalFallbackService service = LocalFallbackService();

  group('LocalFallbackService.generateOfflineRecommendation', () {
    test('always returns at most 3 ranked materials', () {
      final Recommendation recommendation =
          service.generateOfflineRecommendation(FoodCommodity.empty());

      expect(recommendation.materials.length, lessThanOrEqualTo(3));
      expect(recommendation.isOfflineFallback, isTrue);
    });

    test('ranks are sequential starting at 1', () {
      final Recommendation recommendation =
          service.generateOfflineRecommendation(FoodCommodity.empty());

      for (int i = 0; i < recommendation.materials.length; i++) {
        expect(recommendation.materials[i].rank, i + 1);
      }
    });

    test('high-respiration fresh produce favors breathable materials', () {
      const FoodCommodity highRespirationProduce = FoodCommodity(
        name: 'Mushroom',
        category: FoodCategory.vegetable,
        moisturePercent: 90,
        fatPercent: 0.3,
        ph: 6.0,
        respirationRateMlCo2PerKgPerHr: 80,
        desiredShelfLifeDays: 7,
        storageTemperatureCelsius: 4,
        storageHumidityPercent: 95,
        storageType: StorageType.refrigerated,
      );

      final Recommendation recommendation =
          service.generateOfflineRecommendation(highRespirationProduce);

      expect(recommendation.materials, isNotEmpty);
      // The top pick must be produced by a material whose isSuitableFor()
      // rule matches this very high respiration commodity.
      final bool topPickIsSuitable =
          recommendation.materials.first.material.isSuitableFor(highRespirationProduce);
      expect(topPickIsSuitable, isTrue);
    });

    test('predicted shelf life is never zero or negative', () {
      final Recommendation recommendation =
          service.generateOfflineRecommendation(FoodCommodity.empty());

      for (final result in recommendation.materials) {
        expect(result.predictedShelfLifeDays, greaterThan(0));
      }
    });
  });
}
