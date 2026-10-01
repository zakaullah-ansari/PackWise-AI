import 'package:flutter_test/flutter_test.dart';
import 'package:packwise_ai/data/models/food_commodity.dart';
import 'package:packwise_ai/data/models/packaging_material.dart';
import 'package:packwise_ai/data/models/recommendation.dart';

void main() {
  group('materialTypeFromString', () {
    test('parses exact enum names', () {
      expect(materialTypeFromString('ldpe'), MaterialType.ldpe);
      expect(materialTypeFromString('metalizedFilm'), MaterialType.metalizedFilm);
    });

    test('parses common AI phrasing variants', () {
      expect(materialTypeFromString('Aluminum Foil'), MaterialType.aluminumFoil);
      expect(materialTypeFromString('metalized_film'), MaterialType.metalizedFilm);
      expect(materialTypeFromString('Micro-Perforated'), MaterialType.microPerforated);
      expect(materialTypeFromString('biodegradable film'), MaterialType.biodegradable);
    });

    test('falls back to ldpe for completely unknown strings', () {
      expect(materialTypeFromString('unobtainium'), MaterialType.ldpe);
    });
  });

  group('RecommendedMaterialResult.fromJson', () {
    test('parses a well-formed entry', () {
      final RecommendedMaterialResult result = RecommendedMaterialResult.fromJson(
        <String, dynamic>{
          'rank': 1,
          'materialType': 'pet',
          'recommendedThicknessMicrons': 35,
          'predictedOtrCm3M2Day': 12.5,
          'predictedWvtrGM2Day': 3.1,
          'mapGasRatioPercent': <String, dynamic>{'co2': 5, 'o2': 3, 'n2': 92},
          'predictedShelfLifeDays': 21,
          'confidenceScore': 0.87,
          'aiRationale': 'Great clarity and oxygen barrier for dairy.',
        },
        fallbackRank: 1,
      );

      expect(result.materialType, MaterialType.pet);
      expect(result.predictedShelfLifeDays, 21);
      expect(result.confidenceScore, 0.87);
      expect(result.mapGasRatioPercent['o2'], 3);
    });

    test('falls back to catalog defaults for missing numeric fields', () {
      final RecommendedMaterialResult result = RecommendedMaterialResult.fromJson(
        <String, dynamic>{'materialType': 'hdpe'},
        fallbackRank: 2,
      );

      final PackagingMaterial catalog = PackagingMaterial.fromType(MaterialType.hdpe);
      expect(result.rank, 2);
      expect(result.recommendedThicknessMicrons, catalog.recommendedThicknessMicrons);
      expect(result.predictedOtrCm3M2Day, catalog.otrCm3M2Day);
    });
  });

  group('Recommendation.fromGeminiJson', () {
    test('skips malformed entries but keeps the valid ones, capped at 3', () {
      final FoodCommodity commodity = FoodCommodity.empty();
      final Recommendation recommendation = Recommendation.fromGeminiJson(
        id: 'test-id',
        commodity: commodity,
        json: <String, dynamic>{
          'materials': <dynamic>[
            <String, dynamic>{'rank': 1, 'materialType': 'ldpe'},
            'this-is-not-a-map', // malformed — should be skipped safely
            <String, dynamic>{'rank': 2, 'materialType': 'pet'},
            <String, dynamic>{'rank': 3, 'materialType': 'pla'},
            <String, dynamic>{'rank': 4, 'materialType': 'hdpe'},
          ],
        },
      );

      expect(recommendation.materials.length, 3);
      expect(recommendation.materials.first.materialType, MaterialType.ldpe);
    });
  });
}
