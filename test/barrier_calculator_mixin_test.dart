import 'package:flutter_test/flutter_test.dart';
import 'package:packwise_ai/data/mixins/barrier_calculator_mixin.dart';

class _TestBarrier with BarrierCalculatorMixin {}

void main() {
  final _TestBarrier barrier = _TestBarrier();

  group('BarrierCalculatorMixin.classifyOtr', () {
    test('classifies near-zero OTR as excellent', () {
      expect(barrier.classifyOtr(0.5), BarrierLevel.excellent);
    });

    test('classifies moderate OTR correctly', () {
      expect(barrier.classifyOtr(50), BarrierLevel.moderate);
    });

    test('classifies very high OTR as poor', () {
      expect(barrier.classifyOtr(5000), BarrierLevel.poor);
    });
  });

  group('BarrierCalculatorMixin.overallBarrier', () {
    test('takes the worse of OTR and WVTR classifications', () {
      // Excellent OTR but poor WVTR -> overall should be poor.
      expect(barrier.overallBarrier(0.5, 100), BarrierLevel.poor);
    });
  });

  group('BarrierCalculatorMixin.scaleTransmissionRate', () {
    test('doubling thickness roughly halves the transmission rate', () {
      final double scaled = barrier.scaleTransmissionRate(
        baseRate: 100,
        baseThicknessMicrons: 20,
        targetThicknessMicrons: 40,
      );
      expect(scaled, closeTo(50, 0.001));
    });

    test('returns the original rate when thickness is non-positive (guard)', () {
      final double scaled = barrier.scaleTransmissionRate(
        baseRate: 100,
        baseThicknessMicrons: 0,
        targetThicknessMicrons: 40,
      );
      expect(scaled, 100);
    });
  });
}
