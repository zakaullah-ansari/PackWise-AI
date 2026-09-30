import 'package:packwise_ai/data/mixins/barrier_calculator_mixin.dart';
import 'package:packwise_ai/data/mixins/sustainability_score_mixin.dart';
import 'package:packwise_ai/data/models/food_commodity.dart';

/// The eight packaging material families PackWise AI can recommend.
///
/// Syllabus mapping: Enums.
enum MaterialType {
  ldpe,
  hdpe,
  pet,
  metalizedFilm,
  aluminumFoil,
  pla,
  biodegradable,
  microPerforated;

  /// Short catalogue name shown throughout the UI.
  String get shortName {
    return switch (this) {
      MaterialType.ldpe => 'LDPE',
      MaterialType.hdpe => 'HDPE',
      MaterialType.pet => 'PET',
      MaterialType.metalizedFilm => 'Metalized Film',
      MaterialType.aluminumFoil => 'Aluminum Foil',
      MaterialType.pla => 'PLA',
      MaterialType.biodegradable => 'Biodegradable Film',
      MaterialType.microPerforated => 'Micro-perforated Film',
    };
  }
}

/// Abstract base class describing a food-packaging material and its barrier,
/// mechanical and sustainability characteristics.
///
/// Concrete subclasses (one per [MaterialType]) provide material-specific
/// reference constants and override [isSuitableFor]/[bestUseCase] with
/// polymorphic domain logic — this is the canonical "abstract class + many
/// subclasses" OOP example for the workshop.
///
/// Mixes in [BarrierCalculatorMixin] and [SustainabilityScoreMixin] so every
/// material automatically gets consistent barrier-rating and eco-scoring
/// behaviour without re-implementing the math per subclass.
///
/// Syllabus mapping: OOP (abstraction, inheritance, polymorphism), Mixins.
abstract class PackagingMaterial
    with BarrierCalculatorMixin, SustainabilityScoreMixin {
  const PackagingMaterial({
    required this.type,
    required this.displayName,
    required this.description,
    required this.otrCm3M2Day,
    required this.wvtrGM2Day,
    required this.recommendedThicknessMicrons,
    required this.isRecyclable,
    required this.isBiodegradable,
    required this.carbonFootprintIndex,
    required this.costIndex,
  });

  final MaterialType type;
  final String displayName;
  final String description;

  /// Oxygen Transmission Rate at [recommendedThicknessMicrons], cm³/m²/day.
  final double otrCm3M2Day;

  /// Water Vapor Transmission Rate at [recommendedThicknessMicrons], g/m²/day.
  final double wvtrGM2Day;

  final double recommendedThicknessMicrons;
  final bool isRecyclable;
  final bool isBiodegradable;

  /// Relative embodied-carbon index from 0 (very low) to 10 (very high).
  final double carbonFootprintIndex;

  /// Relative cost index from 1 (cheapest) to 5 (most expensive).
  final int costIndex;

  /// Whether this material is a physically/chemically sound choice for
  /// [commodity]. Each subclass implements its own domain rule — this is the
  /// polymorphic decision at the heart of the offline recommendation engine
  /// (see [LocalFallbackService]).
  bool isSuitableFor(FoodCommodity commodity);

  /// A one-line human-readable description of this material's ideal use
  /// case, shown on [MaterialDetailView].
  String get bestUseCase;

  /// Combined OTR+WVTR barrier classification (see [BarrierCalculatorMixin]).
  BarrierLevel get barrierRating => overallBarrier(otrCm3M2Day, wvtrGM2Day);

  /// 0–100 sustainability score (see [SustainabilityScoreMixin]).
  double get sustainabilityScore => computeSustainabilityScore(
        isRecyclable: isRecyclable,
        isBiodegradable: isBiodegradable,
        carbonFootprintIndex: carbonFootprintIndex,
        costIndex: costIndex,
      );

  EcoGrade get ecoGrade => gradeFor(sustainabilityScore);

  /// Factory returning the reference/catalogue instance for a given
  /// [MaterialType], used as the offline-mode default and as a fallback
  /// when the AI response omits a numeric field.
  factory PackagingMaterial.fromType(MaterialType type) {
    return switch (type) {
      MaterialType.ldpe => const LdpeMaterial(),
      MaterialType.hdpe => const HdpeMaterial(),
      MaterialType.pet => const PetMaterial(),
      MaterialType.metalizedFilm => const MetalizedFilmMaterial(),
      MaterialType.aluminumFoil => const AluminumFoilMaterial(),
      MaterialType.pla => const PlaMaterial(),
      MaterialType.biodegradable => const BiodegradableMaterial(),
      MaterialType.microPerforated => const MicroPerforatedMaterial(),
    };
  }

  @override
  String toString() => 'PackagingMaterial(${type.shortName})';
}

/// Low-Density Polyethylene — flexible, cheap, moderate barrier, common for
/// fresh produce bags.
class LdpeMaterial extends PackagingMaterial {
  const LdpeMaterial()
      : super(
          type: MaterialType.ldpe,
          displayName: 'Low-Density Polyethylene (LDPE)',
          description:
              'Flexible, low-cost thermoplastic film with moderate '
              'oxygen/moisture barrier — the workhorse of fresh produce '
              'bags and liners.',
          otrCm3M2Day: 800,
          wvtrGM2Day: 8,
          recommendedThicknessMicrons: 40,
          isRecyclable: true,
          isBiodegradable: false,
          carbonFootprintIndex: 3.5,
          costIndex: 1,
        );

  @override
  bool isSuitableFor(FoodCommodity commodity) {
    // High-respiration fresh produce needs a "breathable" film — LDPE's
    // relatively high OTR actually helps prevent anaerobic spoilage.
    return commodity.respirationRateMlCo2PerKgPerHr > 15 &&
        commodity.moisturePercent > 60;
  }

  @override
  String get bestUseCase =>
      'Fresh fruits & vegetables with moderate-to-high respiration needing '
      'breathability over strict barrier protection.';
}

/// High-Density Polyethylene — stiffer, better moisture barrier than LDPE.
class HdpeMaterial extends PackagingMaterial {
  const HdpeMaterial()
      : super(
          type: MaterialType.hdpe,
          displayName: 'High-Density Polyethylene (HDPE)',
          description:
              'Rigid-to-semi-rigid thermoplastic with a stronger moisture '
              'barrier than LDPE, commonly used for dry goods containers '
              'and pouches.',
          otrCm3M2Day: 300,
          wvtrGM2Day: 3,
          recommendedThicknessMicrons: 50,
          isRecyclable: true,
          isBiodegradable: false,
          carbonFootprintIndex: 3.2,
          costIndex: 2,
        );

  @override
  bool isSuitableFor(FoodCommodity commodity) {
    // Good for lower-moisture, shelf-stable dry commodities (grains, bakery).
    return commodity.moisturePercent < 40 && commodity.fatPercent < 20;
  }

  @override
  String get bestUseCase =>
      'Dry, shelf-stable goods (grains, cereals, bakery) needing a moderate '
      'moisture barrier with rigidity.';
}

/// Polyethylene Terephthalate — excellent clarity + good gas barrier,
/// common for bottles and rigid trays.
class PetMaterial extends PackagingMaterial {
  const PetMaterial()
      : super(
          type: MaterialType.pet,
          displayName: 'Polyethylene Terephthalate (PET)',
          description:
              'Transparent, strong polymer with a good oxygen barrier and '
              'excellent clarity — widely used for bottles, trays and '
              'high-visibility retail packaging.',
          otrCm3M2Day: 60,
          wvtrGM2Day: 6,
          recommendedThicknessMicrons: 30,
          isRecyclable: true,
          isBiodegradable: false,
          carbonFootprintIndex: 4.0,
          costIndex: 3,
        );

  @override
  bool isSuitableFor(FoodCommodity commodity) {
    return commodity.fatPercent > 10 && commodity.ph < 6;
  }

  @override
  String get bestUseCase =>
      'Fatty or acidic products (dairy, sauces, juices) needing clarity plus '
      'a solid oxygen barrier.';
}

/// Metalized (aluminum-vapor-coated) plastic film — strong barrier at low
/// cost/weight vs. solid foil.
class MetalizedFilmMaterial extends PackagingMaterial {
  const MetalizedFilmMaterial()
      : super(
          type: MaterialType.metalizedFilm,
          displayName: 'Metalized Film',
          description:
              'Plastic film vacuum-coated with a microscopically thin '
              'aluminum layer — near-foil barrier performance at a '
              'fraction of the weight and cost.',
          otrCm3M2Day: 1.0,
          wvtrGM2Day: 0.8,
          recommendedThicknessMicrons: 20,
          isRecyclable: false,
          isBiodegradable: false,
          carbonFootprintIndex: 5.0,
          costIndex: 3,
        );

  @override
  bool isSuitableFor(FoodCommodity commodity) {
    return commodity.desiredShelfLifeDays > 60 &&
        commodity.storageType != StorageType.frozen;
  }

  @override
  String get bestUseCase =>
      'Long-shelf-life snacks and dry foods (chips, coffee, spices) needing '
      'a strong barrier without the cost of solid foil.';
}

/// Solid aluminum foil laminate — the gold standard for barrier protection.
class AluminumFoilMaterial extends PackagingMaterial {
  const AluminumFoilMaterial()
      : super(
          type: MaterialType.aluminumFoil,
          displayName: 'Aluminum Foil Laminate',
          description:
              'Multi-layer laminate with a solid aluminum foil core — '
              'near-total barrier to oxygen, moisture and light. Premium '
              'cost and weight.',
          otrCm3M2Day: 0.05,
          wvtrGM2Day: 0.05,
          recommendedThicknessMicrons: 60,
          isRecyclable: false,
          isBiodegradable: false,
          carbonFootprintIndex: 7.5,
          costIndex: 5,
        );

  @override
  bool isSuitableFor(FoodCommodity commodity) {
    return commodity.desiredShelfLifeDays > 180 ||
        commodity.storageType == StorageType.frozen;
  }

  @override
  String get bestUseCase =>
      'Ultra-long shelf-life or frozen products (retort pouches, military/'
      'space rations) requiring an absolute barrier.';
}

/// Polylactic Acid — plant-derived bioplastic, compostable.
class PlaMaterial extends PackagingMaterial {
  const PlaMaterial()
      : super(
          type: MaterialType.pla,
          displayName: 'Polylactic Acid (PLA)',
          description:
              'Compostable bioplastic derived from renewable resources '
              '(corn starch, sugarcane) with moderate barrier properties.',
          otrCm3M2Day: 400,
          wvtrGM2Day: 15,
          recommendedThicknessMicrons: 35,
          isRecyclable: false,
          isBiodegradable: true,
          carbonFootprintIndex: 2.0,
          costIndex: 3,
        );

  @override
  bool isSuitableFor(FoodCommodity commodity) {
    return commodity.desiredShelfLifeDays <= 21 &&
        commodity.storageType != StorageType.frozen;
  }

  @override
  String get bestUseCase =>
      'Short shelf-life, sustainability-focused products (bakery, ready '
      'meals) where compostability matters more than maximum barrier.';
}

/// Generic biodegradable film (e.g. starch-blend/PBAT compounds) — broader
/// than PLA, tuned for higher moisture tolerance.
class BiodegradableMaterial extends PackagingMaterial {
  const BiodegradableMaterial()
      : super(
          type: MaterialType.biodegradable,
          displayName: 'Biodegradable Film (Starch/PBAT Blend)',
          description:
              'Compostable starch-blend film engineered for higher moisture '
              'tolerance than pure PLA, suited to fresh, high-moisture '
              'produce.',
          otrCm3M2Day: 250,
          wvtrGM2Day: 25,
          recommendedThicknessMicrons: 30,
          isRecyclable: false,
          isBiodegradable: true,
          carbonFootprintIndex: 1.8,
          costIndex: 3,
        );

  @override
  bool isSuitableFor(FoodCommodity commodity) {
    return commodity.moisturePercent > 70 &&
        commodity.desiredShelfLifeDays <= 14;
  }

  @override
  String get bestUseCase =>
      'High-moisture fresh produce with a short desired shelf life, where '
      'eco-conscious disposal outweighs long-term barrier needs.';
}

/// Micro-perforated film — laser-drilled micro-holes tuned to a target gas
/// exchange rate, used heavily in Modified Atmosphere Packaging (MAP).
class MicroPerforatedMaterial extends PackagingMaterial {
  const MicroPerforatedMaterial()
      : super(
          type: MaterialType.microPerforated,
          displayName: 'Micro-perforated Film',
          description:
              'Base polymer film laser-perforated with micron-scale holes '
              'to precisely tune gas exchange for respiring produce inside '
              'Modified Atmosphere Packaging (MAP).',
          otrCm3M2Day: 5000,
          wvtrGM2Day: 40,
          recommendedThicknessMicrons: 25,
          isRecyclable: true,
          isBiodegradable: false,
          carbonFootprintIndex: 3.0,
          costIndex: 4,
        );

  @override
  bool isSuitableFor(FoodCommodity commodity) {
    return commodity.respirationRateMlCo2PerKgPerHr > 40;
  }

  @override
  String get bestUseCase =>
      'Very high-respiration fresh produce (mushrooms, broccoli, berries) '
      'that needs precisely tuned gas exchange to avoid anaerobic spoilage.';
}
