import 'package:flutter_test/flutter_test.dart';
import 'package:fitone/domain/entities/powerlifting_score.dart';

void main() {
  group('Powerlifting Score Calculator Unit Tests', () {
    test('Calculates standard DOTS score accurately for male lifter', () {
      final dots = PowerliftingScoreCalculator.calculateDots(
        bodyweightKg: 83.0,
        totalKg: 600.0,
        gender: Gender.male,
      );

      // Expected ~405.05
      expect(dots, closeTo(405.05, 0.1));
    });

    test('Calculates standard DOTS score accurately for female lifter', () {
      final dots = PowerliftingScoreCalculator.calculateDots(
        bodyweightKg: 63.0,
        totalKg: 380.0,
        gender: Gender.female,
      );

      // Expected ~408.70
      expect(dots, closeTo(408.70, 0.1));
    });

    test(
      'Calculates Wilks (1994) score accurately for male and female lifters',
      () {
        final maleWilks = PowerliftingScoreCalculator.calculateWilks(
          bodyweightKg: 83.0,
          totalKg: 600.0,
          gender: Gender.male,
        );
        expect(maleWilks, closeTo(400.50, 0.1));

        final femaleWilks = PowerliftingScoreCalculator.calculateWilks(
          bodyweightKg: 63.0,
          totalKg: 380.0,
          gender: Gender.female,
        );
        expect(femaleWilks, closeTo(408.10, 0.1));
      },
    );

    test(
      'Calculates Wilks-2 (2020) score accurately for male and female lifters',
      () {
        final maleWilks2 = PowerliftingScoreCalculator.calculateWilks2(
          bodyweightKg: 83.0,
          totalKg: 600.0,
          gender: Gender.male,
        );
        expect(maleWilks2, closeTo(400.82, 0.1));

        final femaleWilks2 = PowerliftingScoreCalculator.calculateWilks2(
          bodyweightKg: 63.0,
          totalKg: 380.0,
          gender: Gender.female,
        );
        expect(femaleWilks2, closeTo(404.90, 0.1));
      },
    );

    test(
      'Returns 0.0 on zero or negative bodyweight or total without throwing',
      () {
        expect(
          PowerliftingScoreCalculator.calculateDots(
            bodyweightKg: 0,
            totalKg: 500,
            gender: Gender.male,
          ),
          0.0,
        );
        expect(
          PowerliftingScoreCalculator.calculateDots(
            bodyweightKg: 80,
            totalKg: 0,
            gender: Gender.male,
          ),
          0.0,
        );
        expect(
          PowerliftingScoreCalculator.calculateWilks(
            bodyweightKg: -80,
            totalKg: 500,
            gender: Gender.male,
          ),
          0.0,
        );
        expect(
          PowerliftingScoreCalculator.calculateWilks2(
            bodyweightKg: 80,
            totalKg: -500,
            gender: Gender.female,
          ),
          0.0,
        );
      },
    );

    test('Comprehensive calculate method outputs consistent PowerliftingScoreResult', () {
      final result = PowerliftingScoreCalculator.calculate(
        bodyweightKg: 83.0,
        squatKg: 210.0,
        benchKg: 140.0,
        deadliftKg: 250.0,
        gender: Gender.male,
      );

      expect(result.totalKg, 600.0);
      expect(result.bodyweightMultiplier, closeTo(7.228, 0.01));
      expect(result.squatPercentage, closeTo(35.0, 0.01));
      expect(result.benchPercentage, closeTo(23.33, 0.01));
      expect(result.deadliftPercentage, closeTo(41.67, 0.01));

      expect(result.dotsScore, closeTo(405.05, 0.1));
      expect(result.wilksScore, closeTo(400.50, 0.1));
      expect(result.wilks2Score, closeTo(400.82, 0.1));

      expect(result.classification, StrengthClassification.advanced);
      expect(result.classificationLabel, 'Advanced Competitor');

      expect(result.summaryDescription, contains('Powerlifting Score Summary'));
      expect(result.summaryDescription, contains('Compound Total: 600.0kg'));
      expect(result.summaryDescription, contains('DOTS: 405.05'));
      expect(result.summaryDescription, contains('Advanced Competitor'));
    });

    test('Classifies strength tiers correctly across score spectrum', () {
      PowerliftingScoreResult makeResult(double dots) {
        return PowerliftingScoreResult(
          bodyweightKg: 80,
          squatKg: 100,
          benchKg: 80,
          deadliftKg: 120,
          gender: Gender.male,
          dotsScore: dots,
          wilksScore: dots,
          wilks2Score: dots,
        );
      }

      expect(makeResult(200.0).classification, StrengthClassification.novice);
      expect(
        makeResult(290.0).classification,
        StrengthClassification.intermediate,
      );
      expect(makeResult(380.0).classification, StrengthClassification.advanced);
      expect(makeResult(450.0).classification, StrengthClassification.elite);
      expect(
        makeResult(520.0).classification,
        StrengthClassification.worldClass,
      );
    });
  });
}
