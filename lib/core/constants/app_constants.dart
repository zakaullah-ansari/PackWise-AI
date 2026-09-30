/// App-wide, non-visual constants: validation ranges, Firestore collection
/// names, default values and shared string labels.
///
/// Keeping "magic numbers" out of widgets/services makes the acceptable
/// input ranges auditable in one place — important for a food-safety
/// adjacent domain where a wrong pH or temperature range is a real bug.
///
/// Syllabus mapping: Encapsulation, static const fields, enums.
library;

/// General application metadata.
abstract final class AppConstants {
  const AppConstants._();

  static const String appName = 'PackWise AI';
  static const String appTagline =
      'Intelligent Food Packaging Recommendation System';
  static const String appVersion = '1.0.0';

  /// Default page transition duration used by [RouteGenerator].
  static const Duration pageTransitionDuration = Duration(milliseconds: 350);

  /// Minimum splash-screen dwell time so the branding animation is visible
  /// even on very fast devices/emulators.
  static const Duration splashMinimumDuration = Duration(milliseconds: 1800);
}

/// Firestore collection & document field names, kept as constants so a typo
/// in a string literal cannot silently create a new, wrong collection.
abstract final class FirestoreCollections {
  const FirestoreCollections._();

  static const String users = 'users';
  static const String recommendations = 'recommendations';
}

/// Acceptable input ranges for [FoodCommodity] properties.
///
/// These ranges are intentionally generous (covering fresh produce, dairy,
/// meat and bakery) but still reject physically impossible values (e.g.
/// negative moisture %, pH > 14).
abstract final class ValidationRanges {
  const ValidationRanges._();

  static const double minMoisturePercent = 0.0;
  static const double maxMoisturePercent = 100.0;

  static const double minFatPercent = 0.0;
  static const double maxFatPercent = 100.0;

  static const double minPh = 0.0;
  static const double maxPh = 14.0;

  /// Respiration rate expressed in mL CO2 / kg / hr — typical fresh produce
  /// ranges from ~5 (low, e.g. citrus) to ~300+ (very high, e.g. mushrooms).
  static const double minRespirationRate = 0.0;
  static const double maxRespirationRate = 500.0;

  static const int minShelfLifeDays = 1;
  static const int maxShelfLifeDays = 365;

  static const double minStorageTemperatureCelsius = -30.0;
  static const double maxStorageTemperatureCelsius = 45.0;

  static const double minStorageHumidityPercent = 0.0;
  static const double maxStorageHumidityPercent = 100.0;
}
