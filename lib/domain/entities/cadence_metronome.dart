enum CadenceZone { recovery, aerobic, optimal, sprint }

class CadenceMetronomeConfig {
  final int spm;
  final bool isEnabled;
  final bool audioEnabled;
  final bool hapticEnabled;

  const CadenceMetronomeConfig({
    this.spm = 175,
    this.isEnabled = false,
    this.audioEnabled = true,
    this.hapticEnabled = true,
  });

  CadenceMetronomeConfig copyWith({
    int? spm,
    bool? isEnabled,
    bool? audioEnabled,
    bool? hapticEnabled,
  }) {
    return CadenceMetronomeConfig(
      spm: spm ?? this.spm,
      isEnabled: isEnabled ?? this.isEnabled,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    );
  }

  int get intervalMs => (60000 / spm).round();

  Duration get tickInterval => Duration(milliseconds: intervalMs);

  CadenceZone get zone {
    if (spm < 165) return CadenceZone.recovery;
    if (spm < 175) return CadenceZone.aerobic;
    if (spm <= 185) return CadenceZone.optimal;
    return CadenceZone.sprint;
  }

  String get zoneLabel {
    switch (zone) {
      case CadenceZone.recovery:
        return 'Recovery & Warmup';
      case CadenceZone.aerobic:
        return 'Aerobic Endurance';
      case CadenceZone.optimal:
        return 'Optimal Race Pace';
      case CadenceZone.sprint:
        return 'High Cadence Sprint';
    }
  }

  String get impactReductionSummary {
    switch (zone) {
      case CadenceZone.recovery:
        return 'Lower cadence with longer ground contact. Suitable for easy warmups.';
      case CadenceZone.aerobic:
        return 'Moderate stride rate; reduces vertical oscillation and braking force.';
      case CadenceZone.optimal:
        return 'Peak biomechanical efficiency; reduces knee patellofemoral load by ~20%.';
      case CadenceZone.sprint:
        return 'Fast leg turnover minimizing heel-strike deceleration during surges.';
    }
  }

  static const List<int> standardPresets = [160, 165, 170, 175, 180, 185, 190];
}
