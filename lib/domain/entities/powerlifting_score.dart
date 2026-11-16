import 'dart:math' as math;

enum Gender { male, female }

enum ScoreFormula { dots, wilks, wilks2 }

enum StrengthClassification {
  novice,
  intermediate,
  advanced,
  elite,
  worldClass,
}

class PowerliftingScoreResult {
  final double bodyweightKg;
  final double squatKg;
  final double benchKg;
  final double deadliftKg;
  final Gender gender;
  final double dotsScore;
  final double wilksScore;
  final double wilks2Score;

  const PowerliftingScoreResult({
    required this.bodyweightKg,
    required this.squatKg,
    required this.benchKg,
    required this.deadliftKg,
    required this.gender,
    required this.dotsScore,
    required this.wilksScore,
    required this.wilks2Score,
  });

  double get totalKg => squatKg + benchKg + deadliftKg;

  double get bodyweightMultiplier =>
      bodyweightKg > 0 ? totalKg / bodyweightKg : 0.0;

  double get squatPercentage => totalKg > 0 ? (squatKg / totalKg) * 100.0 : 0.0;

  double get benchPercentage => totalKg > 0 ? (benchKg / totalKg) * 100.0 : 0.0;

  double get deadliftPercentage =>
      totalKg > 0 ? (deadliftKg / totalKg) * 100.0 : 0.0;

  StrengthClassification get classification {
    // Standard competitive powerlifting tier thresholds based on DOTS score
    if (dotsScore >= 500.0) return StrengthClassification.worldClass;
    if (dotsScore >= 425.0) return StrengthClassification.elite;
    if (dotsScore >= 350.0) return StrengthClassification.advanced;
    if (dotsScore >= 250.0) return StrengthClassification.intermediate;
    return StrengthClassification.novice;
  }

  String get classificationLabel {
    switch (classification) {
      case StrengthClassification.worldClass:
        return 'International World Class';
      case StrengthClassification.elite:
        return 'Elite National Competitor';
      case StrengthClassification.advanced:
        return 'Advanced Competitor';
      case StrengthClassification.intermediate:
        return 'Intermediate Athlete';
      case StrengthClassification.novice:
        return 'Novice Lifter';
    }
  }

  String get summaryDescription {
    final genderStr = gender == Gender.male ? 'Male' : 'Female';
    final bwStr = bodyweightKg.toStringAsFixed(1);
    final totalStr = totalKg.toStringAsFixed(1);
    final dotsStr = dotsScore.toStringAsFixed(2);
    final wilksStr = wilksScore.toStringAsFixed(2);
    final wilks2Str = wilks2Score.toStringAsFixed(2);
    final multStr = bodyweightMultiplier.toStringAsFixed(2);

    return 'Powerlifting Score Summary ($genderStr, ${bwStr}kg BW)\n'
        'Compound Total: ${totalStr}kg (${multStr}x BW)\n'
        '  - Squat: ${squatKg.toStringAsFixed(1)}kg (${squatPercentage.toStringAsFixed(1)}%)\n'
        '  - Bench Press: ${benchKg.toStringAsFixed(1)}kg (${benchPercentage.toStringAsFixed(1)}%)\n'
        '  - Deadlift: ${deadliftKg.toStringAsFixed(1)}kg (${deadliftPercentage.toStringAsFixed(1)}%)\n'
        'Scores:\n'
        '  - DOTS: $dotsStr\n'
        '  - Wilks (1994): $wilksStr\n'
        '  - Wilks-2 (2020): $wilks2Str\n'
        'Classification: $classificationLabel';
  }
}

class PowerliftingScoreCalculator {
  // Coefficients for DOTS formula
  // Denominator: a*x^4 + b*x^3 + c*x^2 + d*x + e
  static const double _dotsMaleA = -0.0000010930;
  static const double _dotsMaleB = 0.0007391293;
  static const double _dotsMaleC = -0.1918759221;
  static const double _dotsMaleD = 24.0900756;
  static const double _dotsMaleE = -307.75076;

  static const double _dotsFemaleA = -0.0000010706;
  static const double _dotsFemaleB = 0.0005158568;
  static const double _dotsFemaleC = -0.1126655495;
  static const double _dotsFemaleD = 13.6175032;
  static const double _dotsFemaleE = -57.96288;

  // Coefficients for Wilks (1994) formula
  // Denominator: a + b*x + c*x^2 + d*x^3 + e*x^4 + f*x^5
  static const double _wilksMaleA = -216.0475144;
  static const double _wilksMaleB = 16.2606339;
  static const double _wilksMaleC = -0.002388645;
  static const double _wilksMaleD = -0.00113732;
  static const double _wilksMaleE = 7.01863e-6;
  static const double _wilksMaleF = -1.291e-8;

  static const double _wilksFemaleA = 594.31747775582;
  static const double _wilksFemaleB = -27.23842536447;
  static const double _wilksFemaleC = 0.82112226871;
  static const double _wilksFemaleD = -0.00930733913;
  static const double _wilksFemaleE = 4.731582e-5;
  static const double _wilksFemaleF = -9.054e-8;

  // Coefficients for Wilks-2 (2020 revision) formula
  // Denominator: a + b*x + c*x^2 + d*x^3 + e*x^4 + f*x^5
  static const double _wilks2MaleA = 47.46178854;
  static const double _wilks2MaleB = 8.472061379;
  static const double _wilks2MaleC = 0.07369410346;
  static const double _wilks2MaleD = -0.001395833811;
  static const double _wilks2MaleE = 7.07665973070743e-6;
  static const double _wilks2MaleF = -1.20804336482347e-8;

  static const double _wilks2FemaleA = -125.4255398;
  static const double _wilks2FemaleB = 13.71219419;
  static const double _wilks2FemaleC = -0.03307251465;
  static const double _wilks2FemaleD = -0.001050400051;
  static const double _wilks2FemaleE = 9.38773881462799e-6;
  static const double _wilks2FemaleF = -2.3334613884954e-8;

  static double calculateDots({
    required double bodyweightKg,
    required double totalKg,
    required Gender gender,
  }) {
    if (bodyweightKg <= 0 || totalKg <= 0) return 0.0;
    final x = bodyweightKg.clamp(30.0, 300.0);

    final double denominator;
    if (gender == Gender.male) {
      denominator =
          (_dotsMaleA * math.pow(x, 4)) +
          (_dotsMaleB * math.pow(x, 3)) +
          (_dotsMaleC * math.pow(x, 2)) +
          (_dotsMaleD * x) +
          _dotsMaleE;
    } else {
      denominator =
          (_dotsFemaleA * math.pow(x, 4)) +
          (_dotsFemaleB * math.pow(x, 3)) +
          (_dotsFemaleC * math.pow(x, 2)) +
          (_dotsFemaleD * x) +
          _dotsFemaleE;
    }

    if (denominator <= 0) return 0.0;
    return totalKg * (500.0 / denominator);
  }

  static double calculateWilks({
    required double bodyweightKg,
    required double totalKg,
    required Gender gender,
  }) {
    if (bodyweightKg <= 0 || totalKg <= 0) return 0.0;
    final x = bodyweightKg.clamp(30.0, 300.0);

    final double denominator;
    if (gender == Gender.male) {
      denominator =
          _wilksMaleA +
          (_wilksMaleB * x) +
          (_wilksMaleC * math.pow(x, 2)) +
          (_wilksMaleD * math.pow(x, 3)) +
          (_wilksMaleE * math.pow(x, 4)) +
          (_wilksMaleF * math.pow(x, 5));
    } else {
      denominator =
          _wilksFemaleA +
          (_wilksFemaleB * x) +
          (_wilksFemaleC * math.pow(x, 2)) +
          (_wilksFemaleD * math.pow(x, 3)) +
          (_wilksFemaleE * math.pow(x, 4)) +
          (_wilksFemaleF * math.pow(x, 5));
    }

    if (denominator <= 0) return 0.0;
    return totalKg * (500.0 / denominator);
  }

  static double calculateWilks2({
    required double bodyweightKg,
    required double totalKg,
    required Gender gender,
  }) {
    if (bodyweightKg <= 0 || totalKg <= 0) return 0.0;
    final x = bodyweightKg.clamp(30.0, 300.0);

    final double denominator;
    if (gender == Gender.male) {
      denominator =
          _wilks2MaleA +
          (_wilks2MaleB * x) +
          (_wilks2MaleC * math.pow(x, 2)) +
          (_wilks2MaleD * math.pow(x, 3)) +
          (_wilks2MaleE * math.pow(x, 4)) +
          (_wilks2MaleF * math.pow(x, 5));
    } else {
      denominator =
          _wilks2FemaleA +
          (_wilks2FemaleB * x) +
          (_wilks2FemaleC * math.pow(x, 2)) +
          (_wilks2FemaleD * math.pow(x, 3)) +
          (_wilks2FemaleE * math.pow(x, 4)) +
          (_wilks2FemaleF * math.pow(x, 5));
    }

    if (denominator <= 0) return 0.0;
    return totalKg * (500.0 / denominator);
  }

  static PowerliftingScoreResult calculate({
    required double bodyweightKg,
    required double squatKg,
    required double benchKg,
    required double deadliftKg,
    required Gender gender,
  }) {
    final total = squatKg + benchKg + deadliftKg;
    final dots = calculateDots(
      bodyweightKg: bodyweightKg,
      totalKg: total,
      gender: gender,
    );
    final wilks = calculateWilks(
      bodyweightKg: bodyweightKg,
      totalKg: total,
      gender: gender,
    );
    final wilks2 = calculateWilks2(
      bodyweightKg: bodyweightKg,
      totalKg: total,
      gender: gender,
    );

    return PowerliftingScoreResult(
      bodyweightKg: bodyweightKg,
      squatKg: squatKg,
      benchKg: benchKg,
      deadliftKg: deadliftKg,
      gender: gender,
      dotsScore: dots,
      wilksScore: wilks,
      wilks2Score: wilks2,
    );
  }
}
