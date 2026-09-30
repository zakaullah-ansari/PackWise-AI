import 'package:flutter_test/flutter_test.dart';
import 'package:packwise_ai/data/models/food_commodity.dart';

void main() {
  group('FoodCommodity JSON round-trip', () {
    test('toJson -> fromJson preserves all fields', () {
      const FoodCommodity original = FoodCommodity(
        name: 'Alphonso Mango',
        category: FoodCategory.fruit,
        moisturePercent: 82,
        fatPercent: 0.4,
        ph: 4.2,
        respirationRateMlCo2PerKgPerHr: 25,
        desiredShelfLifeDays: 14,
        storageTemperatureCelsius: 6,
        storageHumidityPercent: 88,
        storageType: StorageType.refrigerated,
      );

      final FoodCommodity restored = FoodCommodity.fromJson(original.toJson());

      expect(restored, original);
    });

    test('fromJson falls back to safe defaults for a malformed map', () {
      final FoodCommodity restored = FoodCommodity.fromJson(const <String, dynamic>{
        'category': 'not-a-real-category',
        'storageType': 'also-not-real',
      });

      expect(restored.category, FoodCategory.other);
      expect(restored.storageType, StorageType.ambient);
      expect(restored.name, isNotEmpty);
    });
  });

  group('FoodCommodity.copyWith', () {
    test('overrides only the specified fields', () {
      final FoodCommodity base = FoodCommodity.empty();
      final FoodCommodity updated = base.copyWith(name: 'Banana', ph: 5.2);

      expect(updated.name, 'Banana');
      expect(updated.ph, 5.2);
      expect(updated.category, base.category);
      expect(updated.moisturePercent, base.moisturePercent);
    });
  });
}
