/// Broad food category — helps Gemini contextualize respiration behaviour
/// and helps [LocalFallbackService] pick sane offline defaults.
///
/// Syllabus mapping: Enums.
enum FoodCategory {
  fruit,
  vegetable,
  dairy,
  meat,
  seafood,
  bakery,
  grainAndCereal,
  other;

  /// Human-friendly label for dropdowns/UI.
  String get label {
    return switch (this) {
      FoodCategory.fruit => 'Fruit',
      FoodCategory.vegetable => 'Vegetable',
      FoodCategory.dairy => 'Dairy',
      FoodCategory.meat => 'Meat & Poultry',
      FoodCategory.seafood => 'Seafood',
      FoodCategory.bakery => 'Bakery',
      FoodCategory.grainAndCereal => 'Grain & Cereal',
      FoodCategory.other => 'Other',
    };
  }
}

/// Where/how the packaged commodity will be stored — directly affects the
/// required barrier and mechanical properties of the packaging film.
///
/// Syllabus mapping: Enums.
enum StorageType {
  ambient,
  refrigerated,
  frozen,
  controlledAtmosphere;

  String get label {
    return switch (this) {
      StorageType.ambient => 'Ambient (Room Temperature)',
      StorageType.refrigerated => 'Refrigerated (2–8°C)',
      StorageType.frozen => 'Frozen (below -18°C)',
      StorageType.controlledAtmosphere => 'Controlled Atmosphere (CA)',
    };
  }
}

/// Immutable domain model describing the food commodity a user wants to
/// package, plus the intended storage environment.
///
/// This is the single input object that flows: `InputFormView` → the
/// [RecommendationProvider] → [RecommendationRepository] → [GeminiService].
///
/// Syllabus mapping: OOP (encapsulation, immutability), factory
/// constructors, `copyWith`, operator overriding, JSON (de)serialization.
class FoodCommodity {
  const FoodCommodity({
    required this.name,
    required this.category,
    required this.moisturePercent,
    required this.fatPercent,
    required this.ph,
    required this.respirationRateMlCo2PerKgPerHr,
    required this.desiredShelfLifeDays,
    required this.storageTemperatureCelsius,
    required this.storageHumidityPercent,
    required this.storageType,
  });

  /// Common/display name of the commodity, e.g. "Alphonso Mango".
  final String name;

  final FoodCategory category;

  /// Moisture content, in percent (0–100).
  final double moisturePercent;

  /// Fat content, in percent (0–100).
  final double fatPercent;

  /// Product pH (0–14). Low pH accelerates certain packaging degradation.
  final double ph;

  /// Respiration rate in mL CO2 / kg / hr — drives OTR requirements for
  /// fresh produce (higher respiration ⇒ needs more oxygen transmission or
  /// active/modified atmosphere packaging).
  final double respirationRateMlCo2PerKgPerHr;

  /// Target shelf life requested by the user, in days.
  final int desiredShelfLifeDays;

  final double storageTemperatureCelsius;

  /// Relative humidity of the storage environment, in percent.
  final double storageHumidityPercent;

  final StorageType storageType;

  /// Returns a new [FoodCommodity] with the given fields overridden,
  /// leaving all others unchanged (standard immutable-update pattern).
  FoodCommodity copyWith({
    String? name,
    FoodCategory? category,
    double? moisturePercent,
    double? fatPercent,
    double? ph,
    double? respirationRateMlCo2PerKgPerHr,
    int? desiredShelfLifeDays,
    double? storageTemperatureCelsius,
    double? storageHumidityPercent,
    StorageType? storageType,
  }) {
    return FoodCommodity(
      name: name ?? this.name,
      category: category ?? this.category,
      moisturePercent: moisturePercent ?? this.moisturePercent,
      fatPercent: fatPercent ?? this.fatPercent,
      ph: ph ?? this.ph,
      respirationRateMlCo2PerKgPerHr: respirationRateMlCo2PerKgPerHr ??
          this.respirationRateMlCo2PerKgPerHr,
      desiredShelfLifeDays: desiredShelfLifeDays ?? this.desiredShelfLifeDays,
      storageTemperatureCelsius:
          storageTemperatureCelsius ?? this.storageTemperatureCelsius,
      storageHumidityPercent:
          storageHumidityPercent ?? this.storageHumidityPercent,
      storageType: storageType ?? this.storageType,
    );
  }

  /// Serializes to a plain JSON map — used both when persisting to Firestore
  /// (embedded inside a [Recommendation] document) and when building the
  /// Gemini prompt payload.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'category': category.name,
      'moisturePercent': moisturePercent,
      'fatPercent': fatPercent,
      'ph': ph,
      'respirationRateMlCo2PerKgPerHr': respirationRateMlCo2PerKgPerHr,
      'desiredShelfLifeDays': desiredShelfLifeDays,
      'storageTemperatureCelsius': storageTemperatureCelsius,
      'storageHumidityPercent': storageHumidityPercent,
      'storageType': storageType.name,
    };
  }

  /// Rebuilds a [FoodCommodity] from a JSON map (e.g. read back from
  /// Firestore). Falls back to safe defaults for any missing/malformed
  /// field so a corrupt historical document never crashes the History
  /// screen.
  factory FoodCommodity.fromJson(Map<String, dynamic> json) {
    return FoodCommodity(
      name: json['name'] as String? ?? 'Unknown Commodity',
      category: FoodCategory.values.firstWhere(
        (FoodCategory c) => c.name == json['category'],
        orElse: () => FoodCategory.other,
      ),
      moisturePercent: (json['moisturePercent'] as num?)?.toDouble() ?? 0,
      fatPercent: (json['fatPercent'] as num?)?.toDouble() ?? 0,
      ph: (json['ph'] as num?)?.toDouble() ?? 7,
      respirationRateMlCo2PerKgPerHr:
          (json['respirationRateMlCo2PerKgPerHr'] as num?)?.toDouble() ?? 0,
      desiredShelfLifeDays: (json['desiredShelfLifeDays'] as num?)?.toInt() ??
          7,
      storageTemperatureCelsius:
          (json['storageTemperatureCelsius'] as num?)?.toDouble() ?? 4,
      storageHumidityPercent:
          (json['storageHumidityPercent'] as num?)?.toDouble() ?? 50,
      storageType: StorageType.values.firstWhere(
        (StorageType s) => s.name == json['storageType'],
        orElse: () => StorageType.ambient,
      ),
    );
  }

  /// A sensible default instance used to pre-fill the input form.
  factory FoodCommodity.empty() {
    return const FoodCommodity(
      name: '',
      category: FoodCategory.fruit,
      moisturePercent: 85,
      fatPercent: 0.5,
      ph: 4.5,
      respirationRateMlCo2PerKgPerHr: 20,
      desiredShelfLifeDays: 14,
      storageTemperatureCelsius: 4,
      storageHumidityPercent: 90,
      storageType: StorageType.refrigerated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FoodCommodity &&
        other.name == name &&
        other.category == category &&
        other.moisturePercent == moisturePercent &&
        other.fatPercent == fatPercent &&
        other.ph == ph &&
        other.respirationRateMlCo2PerKgPerHr ==
            respirationRateMlCo2PerKgPerHr &&
        other.desiredShelfLifeDays == desiredShelfLifeDays &&
        other.storageTemperatureCelsius == storageTemperatureCelsius &&
        other.storageHumidityPercent == storageHumidityPercent &&
        other.storageType == storageType;
  }

  @override
  int get hashCode => Object.hash(
        name,
        category,
        moisturePercent,
        fatPercent,
        ph,
        respirationRateMlCo2PerKgPerHr,
        desiredShelfLifeDays,
        storageTemperatureCelsius,
        storageHumidityPercent,
        storageType,
      );

  @override
  String toString() => 'FoodCommodity(name: $name, category: ${category.label})';
}
