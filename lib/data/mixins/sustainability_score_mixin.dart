/// Letter-grade representation of a 0–100 sustainability score, used by
/// [EcoBadge] for a compact, glanceable UI indicator.
///
/// Syllabus mapping: Enums.
enum EcoGrade {
  aPlus,
  a,
  b,
  c,
  d,
  e;

  String get label {
    return switch (this) {
      EcoGrade.aPlus => 'A+',
      EcoGrade.a => 'A',
      EcoGrade.b => 'B',
      EcoGrade.c => 'C',
      EcoGrade.d => 'D',
      EcoGrade.e => 'E',
    };
  }
}

/// Reusable eco/sustainability scoring logic.
///
/// Mixed into [PackagingMaterial] so every material subclass can compute a
/// consistent 0–100 sustainability score from a small set of material
/// attributes, without duplicating the scoring formula in each subclass.
///
/// The formula is intentionally transparent/simple (a weighted sum) so it
/// can be explained on a whiteboard during the workshop, rather than a black
/// box — matching the "explainable AI-adjacent" spirit of the project.
///
/// Syllabus mapping: Mixins, weighted scoring algorithms, enums.
mixin SustainabilityScoreMixin {
  /// Computes a 0–100 sustainability score.
  ///
  /// - [isRecyclable] adds up to 25 points.
  /// - [isBiodegradable] (includes compostable materials) adds up to 30
  ///   points.
  /// - [carbonFootprintIndex] (0 = very low embodied carbon, 10 = very high,
  ///   e.g. virgin aluminum) subtracts up to 30 points.
  /// - [costIndex] (1 = cheapest/most accessible, 5 = most expensive) has a
  ///   small negative weight, reflecting that affordability aids real-world
  ///   sustainable adoption at scale.
  ///
  /// The result is always clamped to the valid `[0, 100]` range.
  double computeSustainabilityScore({
    required bool isRecyclable,
    required bool isBiodegradable,
    required double carbonFootprintIndex,
    required int costIndex,
  }) {
    double score = 50;
    if (isRecyclable) score += 25;
    if (isBiodegradable) score += 30;
    score -= carbonFootprintIndex.clamp(0, 10) * 3;
    score -= (costIndex.clamp(1, 5) - 1) * 2;
    return score.clamp(0, 100).toDouble();
  }

  /// Maps a numeric score to a letter [EcoGrade] for compact display.
  EcoGrade gradeFor(double score) {
    if (score >= 90) return EcoGrade.aPlus;
    if (score >= 75) return EcoGrade.a;
    if (score >= 60) return EcoGrade.b;
    if (score >= 45) return EcoGrade.c;
    if (score >= 30) return EcoGrade.d;
    return EcoGrade.e;
  }
}
