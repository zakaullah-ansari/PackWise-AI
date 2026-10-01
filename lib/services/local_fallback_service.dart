import 'dart:math' as math;

import 'package:packwise_ai/data/mixins/barrier_calculator_mixin.dart';
import 'package:packwise_ai/data/models/food_commodity.dart';
import 'package:packwise_ai/data/models/packaging_material.dart';
import 'package:packwise_ai/data/models/recommendation.dart';

/// A deterministic, fully-offline "rules engine" that mirrors what Gemini
/// would normally decide, using the domain knowledge already encoded in
/// [PackagingMaterial.isSuitableFor] and the barrier/sustainability mixins.
///
/// This is the resilience backbone of the app: whenever the network is
/// unavailable, the API key is missing, or Gemini returns an error, the
/// [RecommendationRepository] transparently falls back to this engine so a
/// demo (or a real farmer/small processor with poor connectivity) always
/// gets *a* usable recommendation instead of a dead end.
///
/// Syllabus mapping: OOP/polymorphism (iterating over all [PackagingMaterial]
/// subclasses via their shared abstract interface), Mixins reuse, sorting
/// algorithms, pure functions.
class LocalFallbackService {
  /// Produces a heuristic [Recommendation] for [commodity] using only local
  /// domain rules — no network access required.
  Recommendation generateOfflineRecommendation(FoodCommodity commodity) {
    final List<_ScoredMaterial> scored = MaterialType.values
        .map((MaterialType type) => PackagingMaterial.fromType(type))
        .map((PackagingMaterial material) => _ScoredMaterial(
              material: material,
              score: _scoreMaterial(material, commodity),
            ))
        .toList()
      ..sort((_ScoredMaterial a, _ScoredMaterial b) => b.score.compareTo(a.score));

    final List<_ScoredMaterial> top3 = scored.take(3).toList();
    final Map<String, double> mapGas = _estimateMapGas(commodity);

    final List<RecommendedMaterialResult> materials = <RecommendedMaterialResult>[
      for (int i = 0; i < top3.length; i++)
        _toRecommendedResult(
          rank: i + 1,
          scored: top3[i],
          commodity: commodity,
          mapGas: mapGas,
        ),
    ];

    return Recommendation(
      id: 'offline-${DateTime.now().microsecondsSinceEpoch}',
      commodity: commodity,
      materials: materials,
      generatedAt: DateTime.now(),
      isOfflineFallback: true,
    );
  }

  /// Combines rule-based suitability with the material's own sustainability
  /// score into a single ranking score in the range roughly `[0, 100]`.
  double _scoreMaterial(PackagingMaterial material, FoodCommodity commodity) {
    final double suitabilityPoints = material.isSuitableFor(commodity) ? 55 : 15;
    final double sustainabilityPoints = material.sustainabilityScore * 0.35;
    return suitabilityPoints + sustainabilityPoints;
  }

  RecommendedMaterialResult _toRecommendedResult({
    required int rank,
    required _ScoredMaterial scored,
    required FoodCommodity commodity,
    required Map<String, double> mapGas,
  }) {
    final PackagingMaterial material = scored.material;
    final BarrierLevel barrier = material.barrierRating;
    final bool isSuitable = material.isSuitableFor(commodity);

    // Better barriers extend predicted shelf life relative to the desired
    // target; a mismatch between material and commodity shortens it.
    final int barrierBonusDays = switch (barrier) {
      BarrierLevel.excellent => 10,
      BarrierLevel.good => 5,
      BarrierLevel.moderate => 0,
      BarrierLevel.poor => -5,
    };
    final int predictedShelfLifeDays = math.max(
      1,
      commodity.desiredShelfLifeDays + (isSuitable ? barrierBonusDays : -barrierBonusDays.abs()),
    );

    return RecommendedMaterialResult(
      rank: rank,
      materialType: material.type,
      recommendedThicknessMicrons: material.recommendedThicknessMicrons,
      predictedOtrCm3M2Day: material.otrCm3M2Day,
      predictedWvtrGM2Day: material.wvtrGM2Day,
      mapGasRatioPercent: mapGas,
      predictedShelfLifeDays: predictedShelfLifeDays,
      // Heuristic confidence is intentionally lower than a typical AI
      // response to make clear in the UI this is an offline estimate.
      confidenceScore: isSuitable ? 0.62 : 0.4,
      aiRationale:
          '${material.bestUseCase} (Offline heuristic recommendation — '
          'connect to the internet for an AI-personalized analysis.)',
    );
  }

  /// Heuristic Modified-Atmosphere gas mix based on respiration rate: highly
  /// respiring produce needs lower O2 / higher CO2 to slow senescence.
  Map<String, double> _estimateMapGas(FoodCommodity commodity) {
    final double respiration = commodity.respirationRateMlCo2PerKgPerHr;
    final double o2 = respiration > 50 ? 2 : (respiration > 20 ? 5 : 8);
    final double co2 = respiration > 50 ? 10 : (respiration > 20 ? 7 : 4);
    final double n2 = 100 - o2 - co2;
    return <String, double>{'co2': co2, 'o2': o2, 'n2': n2};
  }
}

/// Internal pairing of a candidate material with its computed ranking score.
class _ScoredMaterial {
  const _ScoredMaterial({required this.material, required this.score});
  final PackagingMaterial material;
  final double score;
}
