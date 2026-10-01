import 'package:packwise_ai/core/errors/app_exception.dart';
import 'package:packwise_ai/data/models/food_commodity.dart';

/// Cross-field business-rule validation shared by any class that needs to
/// sanity-check a [FoodCommodity] *before* spending a network call on it.
///
/// This complements (rather than duplicates) [InputValidators]: the latter
/// checks each form field in isolation (e.g. "is this a number in range?"),
/// while [ValidationMixin] checks relationships *between* fields that only
/// make sense together (e.g. "Frozen storage but +20°C" is individually
/// valid per-field yet logically inconsistent).
///
/// Mixed into [RecommendationRepository] so validation happens at the
/// domain-orchestration layer, keeping [GeminiService] focused purely on
/// networking concerns.
///
/// Syllabus mapping: Mixins, Exception Handling, list processing.
mixin ValidationMixin {
  /// Returns a list of non-fatal warning messages for logically unusual
  /// (but not strictly invalid) input combinations. Callers may choose to
  /// surface these to the user or simply log them.
  List<String> collectCommodityWarnings(FoodCommodity commodity) {
    final List<String> warnings = <String>[];

    if (commodity.storageType == StorageType.frozen &&
        commodity.storageTemperatureCelsius > -12) {
      warnings.add(
        'Storage type is "Frozen" but the temperature entered '
        '(${commodity.storageTemperatureCelsius}°C) is unusually warm for '
        'frozen storage.',
      );
    }

    if (commodity.storageType == StorageType.refrigerated &&
        (commodity.storageTemperatureCelsius < -2 ||
            commodity.storageTemperatureCelsius > 12)) {
      warnings.add(
        'Storage type is "Refrigerated" but the temperature entered '
        '(${commodity.storageTemperatureCelsius}°C) is outside the typical '
        '2–8°C chiller range.',
      );
    }

    if (commodity.moisturePercent > 92 &&
        commodity.respirationRateMlCo2PerKgPerHr < 2) {
      warnings.add(
        'Very high moisture with almost no respiration is unusual — double '
        'check the respiration rate value.',
      );
    }

    return warnings;
  }

  /// Throws a [ValidationException] if [commodity] contains a fatal,
  /// unrecoverable inconsistency that must block the AI request entirely.
  void ensureCommodityIsValid(FoodCommodity commodity) {
    if (commodity.name.trim().isEmpty) {
      throw const ValidationException('Commodity name cannot be empty.');
    }
    if (commodity.desiredShelfLifeDays <= 0) {
      throw const ValidationException(
        'Desired shelf life must be at least 1 day.',
      );
    }
    if (commodity.ph < 0 || commodity.ph > 14) {
      throw const ValidationException('pH must be between 0 and 14.');
    }
  }
}
