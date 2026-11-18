import 'dart:math' as math;

enum HydrationStatus { dehydrated, onTrack, targetReached }

class WaterGoalAdjustment {
  final int baseTargetMl;
  final double runningDistanceKm;
  final double skinTempDelta;
  final int consumedWaterMl;
  final bool isEnabled;

  const WaterGoalAdjustment({
    this.baseTargetMl = 2500,
    this.runningDistanceKm = 0.0,
    this.skinTempDelta = 0.0,
    this.consumedWaterMl = 0,
    this.isEnabled = true,
  });

  /// Running distance bonus: +350ml per 5km logged (70ml/km)
  int get runningAdjustmentMl {
    if (!isEnabled || runningDistanceKm <= 0.0) return 0;
    return ((runningDistanceKm / 5.0) * 350.0).round();
  }

  /// Ambient skin temperature thermal sweat bonus:
  /// Adds 200ml per +0.5 °C above baseline (+400ml per +1.0 °C), clamped to max 1200ml.
  int get thermalAdjustmentMl {
    if (!isEnabled || skinTempDelta <= 0.0) return 0;
    final bonus = (skinTempDelta * 400.0).round();
    return bonus.clamp(0, 1200);
  }

  /// Total dynamic water target adjusted for workout distance and thermal stress
  int get adjustedTargetMl {
    if (!isEnabled) return baseTargetMl;
    return baseTargetMl + runningAdjustmentMl + thermalAdjustmentMl;
  }

  int get totalAdjustmentMl => runningAdjustmentMl + thermalAdjustmentMl;

  bool get hasActiveAdjustment => isEnabled && totalAdjustmentMl > 0;

  int get remainingWaterMl => math.max(0, adjustedTargetMl - consumedWaterMl);

  double get progress => adjustedTargetMl > 0
      ? (consumedWaterMl / adjustedTargetMl).clamp(0.0, 1.0)
      : 0.0;

  HydrationStatus get status {
    if (progress >= 1.0) return HydrationStatus.targetReached;
    if (progress >= 0.5) return HydrationStatus.onTrack;
    return HydrationStatus.dehydrated;
  }

  String get statusLabel {
    switch (status) {
      case HydrationStatus.targetReached:
        return 'Hydration Target Reached';
      case HydrationStatus.onTrack:
        return 'Hydration On Track';
      case HydrationStatus.dehydrated:
        return 'Fluid Intake Needed';
    }
  }

  String get physiologicalSummary {
    if (!hasActiveAdjustment) {
      return 'Baseline maintenance target: ${baseTargetMl}ml/day without acute exercise sweat demand.';
    }
    final parts = <String>[];
    if (runningAdjustmentMl > 0) {
      parts.add(
        '+${runningAdjustmentMl}ml for ${runningDistanceKm.toStringAsFixed(1)}km running volume (+350ml/5km)',
      );
    }
    if (thermalAdjustmentMl > 0) {
      parts.add(
        '+${thermalAdjustmentMl}ml for +${skinTempDelta.toStringAsFixed(1)}°C skin temperature thermoregulatory demand',
      );
    }
    return parts.join(' • ');
  }

  WaterGoalAdjustment copyWith({
    int? baseTargetMl,
    double? runningDistanceKm,
    double? skinTempDelta,
    int? consumedWaterMl,
    bool? isEnabled,
  }) {
    return WaterGoalAdjustment(
      baseTargetMl: baseTargetMl ?? this.baseTargetMl,
      runningDistanceKm: runningDistanceKm ?? this.runningDistanceKm,
      skinTempDelta: skinTempDelta ?? this.skinTempDelta,
      consumedWaterMl: consumedWaterMl ?? this.consumedWaterMl,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
