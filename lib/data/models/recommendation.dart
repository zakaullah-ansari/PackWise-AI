import 'package:packwise_ai/core/utils/logger.dart';
import 'package:packwise_ai/data/mixins/barrier_calculator_mixin.dart';
import 'package:packwise_ai/data/mixins/sustainability_score_mixin.dart';
import 'package:packwise_ai/data/models/food_commodity.dart';
import 'package:packwise_ai/data/models/packaging_material.dart';

/// Parses a free-form material name/string (as returned by Gemini, which may
/// not always respect the exact enum spelling) into a [MaterialType].
///
/// Falls back to [MaterialType.ldpe] — the safest, most common default — if
/// nothing matches, so a single unexpected AI string never crashes parsing
/// of the other two recommendations in the same response.
///
/// Syllabus mapping: String processing, Exception-safe parsing, enums.
MaterialType materialTypeFromString(String raw) {
  final String normalized =
      raw.toLowerCase().trim().replaceAll(RegExp(r'[\s_-]+'), '');

  for (final MaterialType type in MaterialType.values) {
    if (type.name.toLowerCase() == normalized) return type;
  }

  // Handle common synonyms / AI phrasing variance.
  if (normalized.contains('metaliz') || normalized.contains('metallis')) {
    return MaterialType.metalizedFilm;
  }
  if (normalized.contains('aluminum') || normalized.contains('aluminium') ||
      normalized.contains('foil')) {
    return MaterialType.aluminumFoil;
  }
  if (normalized.contains('microperfor') || normalized.contains('perforated')) {
    return MaterialType.microPerforated;
  }
  if (normalized.contains('biodegrad') || normalized.contains('compost')) {
    return MaterialType.biodegradable;
  }
  if (normalized.contains('pla')) return MaterialType.pla;
  if (normalized.contains('hdpe')) return MaterialType.hdpe;
  if (normalized.contains('ldpe')) return MaterialType.ldpe;
  if (normalized.contains('pet')) return MaterialType.pet;

  AppLogger.warning('Unrecognized material type from AI: "$raw" — defaulting to LDPE.');
  return MaterialType.ldpe;
}

/// A single ranked packaging material recommendation with AI-predicted (or
/// offline-computed) performance figures specific to the requested
/// commodity — distinct from the generic catalogue values on
/// [PackagingMaterial], which describe the material family in general.
///
/// Mixes in [BarrierCalculatorMixin] so the *predicted* OTR/WVTR for this
/// specific recommendation get their own barrier classification, reusing the
/// exact same logic as the generic catalogue rating.
///
/// Syllabus mapping: OOP composition, Mixins, JSON parsing, Exception
/// Handling (defensive numeric parsing with fallbacks).
class RecommendedMaterialResult with BarrierCalculatorMixin {
  const RecommendedMaterialResult({
    required this.rank,
    required this.materialType,
    required this.recommendedThicknessMicrons,
    required this.predictedOtrCm3M2Day,
    required this.predictedWvtrGM2Day,
    required this.mapGasRatioPercent,
    required this.predictedShelfLifeDays,
    required this.confidenceScore,
    required this.aiRationale,
  });

  /// 1-based rank (1 = top recommendation).
  final int rank;
  final MaterialType materialType;
  final double recommendedThicknessMicrons;
  final double predictedOtrCm3M2Day;
  final double predictedWvtrGM2Day;

  /// Modified Atmosphere Packaging gas mix, keys `co2`, `o2`, `n2` — values
  /// are percentages that should sum to ~100.
  final Map<String, double> mapGasRatioPercent;

  final int predictedShelfLifeDays;

  /// AI confidence in this specific recommendation, 0.0–1.0.
  final double confidenceScore;

  /// Short natural-language justification from the AI (or the offline rules
  /// engine) explaining *why* this material was chosen.
  final String aiRationale;

  /// The generic catalogue entry for this material family (description,
  /// suitability rules, base sustainability inputs).
  PackagingMaterial get material => PackagingMaterial.fromType(materialType);

  /// Barrier classification computed from THIS recommendation's predicted
  /// OTR/WVTR (which may differ from the catalogue defaults because of the
  /// specific recommended thickness).
  BarrierLevel get barrierRating =>
      overallBarrier(predictedOtrCm3M2Day, predictedWvtrGM2Day);

  double get sustainabilityScore => material.sustainabilityScore;
  EcoGrade get ecoGrade => material.ecoGrade;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rank': rank,
      'materialType': materialType.name,
      'recommendedThicknessMicrons': recommendedThicknessMicrons,
      'predictedOtrCm3M2Day': predictedOtrCm3M2Day,
      'predictedWvtrGM2Day': predictedWvtrGM2Day,
      'mapGasRatioPercent': mapGasRatioPercent,
      'predictedShelfLifeDays': predictedShelfLifeDays,
      'confidenceScore': confidenceScore,
      'aiRationale': aiRationale,
    };
  }

  /// Parses one recommendation entry, tolerating missing/malformed numeric
  /// fields by substituting the material's catalogue defaults.
  factory RecommendedMaterialResult.fromJson(
    Map<String, dynamic> json, {
    required int fallbackRank,
  }) {
    final MaterialType type = materialTypeFromString(
      (json['materialType'] ?? json['material'] ?? 'ldpe').toString(),
    );
    final PackagingMaterial catalog = PackagingMaterial.fromType(type);

    double numOr(dynamic value, double fallback) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    int intOr(dynamic value, int fallback) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    final Map<String, dynamic> rawGas =
        (json['mapGasRatioPercent'] ?? json['mapGas'] ?? const <String, dynamic>{})
            as Map<String, dynamic>;

    return RecommendedMaterialResult(
      rank: intOr(json['rank'], fallbackRank),
      materialType: type,
      recommendedThicknessMicrons: numOr(
        json['recommendedThicknessMicrons'],
        catalog.recommendedThicknessMicrons,
      ),
      predictedOtrCm3M2Day: numOr(
        json['predictedOtrCm3M2Day'] ?? json['otr'],
        catalog.otrCm3M2Day,
      ),
      predictedWvtrGM2Day: numOr(
        json['predictedWvtrGM2Day'] ?? json['wvtr'],
        catalog.wvtrGM2Day,
      ),
      mapGasRatioPercent: <String, double>{
        'co2': numOr(rawGas['co2'], 5),
        'o2': numOr(rawGas['o2'], 3),
        'n2': numOr(rawGas['n2'], 92),
      },
      predictedShelfLifeDays: intOr(json['predictedShelfLifeDays'], 7),
      confidenceScore: numOr(json['confidenceScore'], 0.6).clamp(0, 1),
      aiRationale: (json['aiRationale'] ?? json['rationale'] ?? catalog.bestUseCase)
          .toString(),
    );
  }
}

/// The complete result of one recommendation request: the commodity that was
/// analyzed plus its top-ranked packaging material results.
///
/// Instances are produced either by [RecommendationRepository] (parsing a
/// live Gemini response) or by [LocalFallbackService] (offline rules
/// engine) and are persisted to/read from Cloud Firestore for the History
/// screen.
///
/// Syllabus mapping: OOP, JSON/Firestore (de)serialization, DateTime.
class Recommendation {
  const Recommendation({
    required this.id,
    required this.commodity,
    required this.materials,
    required this.generatedAt,
    this.userId,
    this.isOfflineFallback = false,
  });

  final String id;
  final FoodCommodity commodity;

  /// Top-N recommended materials, expected to already be sorted by [rank].
  final List<RecommendedMaterialResult> materials;
  final DateTime generatedAt;

  /// Owning Firebase Auth UID, null until saved for a signed-in user.
  final String? userId;

  /// True when Gemini was unreachable and this result came from
  /// [LocalFallbackService] instead — surfaced in the UI as an "Offline
  /// Mode" badge for transparency.
  final bool isOfflineFallback;

  /// The single best (rank 1) recommendation, if any.
  RecommendedMaterialResult? get topResult =>
      materials.isEmpty ? null : materials.first;

  Recommendation copyWith({String? userId}) {
    return Recommendation(
      id: id,
      commodity: commodity,
      materials: materials,
      generatedAt: generatedAt,
      userId: userId ?? this.userId,
      isOfflineFallback: isOfflineFallback,
    );
  }

  /// Serializes for Cloud Firestore storage.
  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'id': id,
      'commodity': commodity.toJson(),
      'materials': materials.map((RecommendedMaterialResult m) => m.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
      'userId': userId,
      'isOfflineFallback': isOfflineFallback,
    };
  }

  /// Rebuilds a [Recommendation] from a Firestore document map.
  factory Recommendation.fromFirestore(Map<String, dynamic> data) {
    final List<dynamic> rawMaterials =
        (data['materials'] as List<dynamic>?) ?? <dynamic>[];

    return Recommendation(
      id: data['id'] as String? ?? '',
      commodity: FoodCommodity.fromJson(
        (data['commodity'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      materials: <RecommendedMaterialResult>[
        for (int i = 0; i < rawMaterials.length; i++)
          RecommendedMaterialResult.fromJson(
            rawMaterials[i] as Map<String, dynamic>,
            fallbackRank: i + 1,
          ),
      ],
      generatedAt: DateTime.tryParse(data['generatedAt'] as String? ?? '') ??
          DateTime.now(),
      userId: data['userId'] as String?,
      isOfflineFallback: data['isOfflineFallback'] as bool? ?? false,
    );
  }

  /// Parses the raw JSON payload extracted from a Gemini `generateContent`
  /// response into a full [Recommendation] for [commodity].
  ///
  /// Expects a top-level `materials` array; any entry that fails to parse
  /// individually is skipped rather than failing the whole response, so one
  /// malformed AI entry doesn't discard two good ones.
  factory Recommendation.fromGeminiJson({
    required String id,
    required FoodCommodity commodity,
    required Map<String, dynamic> json,
  }) {
    final List<dynamic> rawMaterials =
        (json['materials'] as List<dynamic>?) ?? <dynamic>[];

    final List<RecommendedMaterialResult> parsed = <RecommendedMaterialResult>[];
    for (int i = 0; i < rawMaterials.length; i++) {
      try {
        parsed.add(
          RecommendedMaterialResult.fromJson(
            rawMaterials[i] as Map<String, dynamic>,
            fallbackRank: i + 1,
          ),
        );
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Skipping malformed recommendation entry at index $i',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    parsed.sort((RecommendedMaterialResult a, RecommendedMaterialResult b) =>
        a.rank.compareTo(b.rank));

    return Recommendation(
      id: id,
      commodity: commodity,
      materials: parsed.take(3).toList(),
      generatedAt: DateTime.now(),
    );
  }
}
