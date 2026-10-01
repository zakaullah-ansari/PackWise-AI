import 'package:flutter_test/flutter_test.dart';
import 'package:packwise_ai/data/mixins/sustainability_score_mixin.dart';

class _TestScorer with SustainabilityScoreMixin {}

void main() {
  final _TestScorer scorer = _TestScorer();

  group('SustainabilityScoreMixin.computeSustainabilityScore', () {
    test('recyclable + biodegradable + low carbon yields a high score', () {
      final double score = scorer.computeSustainabilityScore(
        isRecyclable: true,
        isBiodegradable: true,
        carbonFootprintIndex: 0,
        costIndex: 1,
      );
      expect(score, greaterThanOrEqualTo(90));
    });

    test('non-recyclable, non-biodegradable, high carbon yields a low score', () {
      final double score = scorer.computeSustainabilityScore(
        isRecyclable: false,
        isBiodegradable: false,
        carbonFootprintIndex: 10,
        costIndex: 5,
      );
      expect(score, lessThan(30));
    });

    test('score is always clamped within [0, 100]', () {
      final double score = scorer.computeSustainabilityScore(
        isRecyclable: false,
        isBiodegradable: false,
        carbonFootprintIndex: 999,
        costIndex: 5,
      );
      expect(score, greaterThanOrEqualTo(0));
      expect(score, lessThanOrEqualTo(100));
    });
  });

  group('SustainabilityScoreMixin.gradeFor', () {
    test('maps a 95 score to A+', () {
      expect(scorer.gradeFor(95), EcoGrade.aPlus);
    });

    test('maps a 10 score to E', () {
      expect(scorer.gradeFor(10), EcoGrade.e);
    });
  });
}
