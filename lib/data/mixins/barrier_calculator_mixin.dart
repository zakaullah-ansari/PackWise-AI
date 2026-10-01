/// Qualitative classification of a packaging film's gas/moisture barrier
/// performance, from best to worst.
///
/// Syllabus mapping: Enums.
enum BarrierLevel {
  excellent,
  good,
  moderate,
  poor;

  String get label {
    return switch (this) {
      BarrierLevel.excellent => 'Excellent',
      BarrierLevel.good => 'Good',
      BarrierLevel.moderate => 'Moderate',
      BarrierLevel.poor => 'Poor',
    };
  }
}

/// Reusable Oxygen/Water-Vapor Transmission Rate math.
///
/// Mixed into [PackagingMaterial] (and unit-testable in isolation) so any
/// class that "has" OTR/WVTR characteristics gets consistent, single-source
/// classification and thickness-scaling logic without inheriting from a
/// common base class — the textbook use case for a Dart mixin.
///
/// Reference thresholds are simplified for teaching purposes but directionally
/// match real packaging-science literature (lower OTR/WVTR = better barrier).
///
/// Syllabus mapping: Mixins, pure functions, enums, basic physics/engineering
/// formulas (Fick's law thickness scaling) applied in code.
mixin BarrierCalculatorMixin {
  /// Classifies Oxygen Transmission Rate, expressed in cm³/m²/day (at 23°C,
  /// 0% RH — the standard ASTM D3985 reference condition).
  BarrierLevel classifyOtr(double otrCm3M2Day) {
    if (otrCm3M2Day <= 1) return BarrierLevel.excellent;
    if (otrCm3M2Day <= 10) return BarrierLevel.good;
    if (otrCm3M2Day <= 100) return BarrierLevel.moderate;
    return BarrierLevel.poor;
  }

  /// Classifies Water Vapor Transmission Rate, expressed in g/m²/day
  /// (ASTM F1249 reference condition).
  BarrierLevel classifyWvtr(double wvtrGM2Day) {
    if (wvtrGM2Day <= 1) return BarrierLevel.excellent;
    if (wvtrGM2Day <= 5) return BarrierLevel.good;
    if (wvtrGM2Day <= 20) return BarrierLevel.moderate;
    return BarrierLevel.poor;
  }

  /// Combines the OTR and WVTR classifications into a single overall
  /// [BarrierLevel], conservatively taking the *worse* of the two ratings
  /// (a film is only as good as its weakest barrier property).
  BarrierLevel overallBarrier(double otrCm3M2Day, double wvtrGM2Day) {
    final BarrierLevel otrLevel = classifyOtr(otrCm3M2Day);
    final BarrierLevel wvtrLevel = classifyWvtr(wvtrGM2Day);
    return otrLevel.index >= wvtrLevel.index ? otrLevel : wvtrLevel;
  }

  /// Scales a transmission rate measured at [baseThicknessMicrons] to an
  /// equivalent rate at [targetThicknessMicrons].
  ///
  /// Transmission rate is approximately inversely proportional to film
  /// thickness (a simplified application of Fick's first law of diffusion):
  /// doubling the thickness roughly halves the transmission rate.
  ///
  /// Returns the original [baseRate] unchanged if either thickness is
  /// non-positive, guarding against a division-by-zero edge case.
  double scaleTransmissionRate({
    required double baseRate,
    required double baseThicknessMicrons,
    required double targetThicknessMicrons,
  }) {
    if (baseThicknessMicrons <= 0 || targetThicknessMicrons <= 0) {
      return baseRate;
    }
    return baseRate * (baseThicknessMicrons / targetThicknessMicrons);
  }
}
