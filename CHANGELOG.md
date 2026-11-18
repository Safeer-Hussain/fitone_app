# Changelog

All notable changes to the Fitone mobile ecosystem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-11-18

### Added
- **Water Intake Goal Auto-Adjustment Engine (Sprint 08)**:
  - Dynamic calculation of daily hydration targets based on acute exercise sweat loss and wearable thermal telemetry.
  - Running volume compensation: automatically appends +350ml fluid replenishment per 5.0km logged today (+70ml/km).
  - Ambient thermoregulatory compensation: automatically appends +200ml fluid compensation per +0.5°C elevated smart-ring skin temperature delta (+400ml/°C).
  - Dedicated `WaterAdjustmentSheet` modal bottom sheet providing full transparency into baseline requirements, running bonuses, and thermoregulatory sweat demands.
  - Adaptive hydration engine toggle and fine baseline target adjustment slider (1500ml - 4500ml).
  - Interactive adaptive pill and breakdown line directly in `HydrationTrackerCard`.
  - Comprehensive unit test suite (`water_goal_adjustment_test.dart`) and widget test suite (`water_goal_adjustment_widget_test.dart`) verifying 100% calculation accuracy and 800x360 landscape safety.
- **Automated Release Workflow**:
  - GitHub Actions release pipeline (`.github/workflows/release.yml`) to automatically compile `flutter build apk --release` and publish `app-release.apk` to GitHub Releases on version tags.
  - Added `--android-skip-build-dependency-validation` to CI release workflow to ensure reliable Gradle builds without dependency version mismatch interruptions.

### Changed
- Incremented package version to `1.0.1+2`.
- Updated static analysis pipeline in `tool/sprint_gate.dart` with `--no-fatal-infos`.
- Verified analysis options error suppression for Flutter 3.50+ deprecated member notices.

## [1.0.0] - 2026-11-17

### Added
- Initial production release of Fitone Mobile Wearable Ecosystem.
- Dual smart-ring Bluetooth & native platform channels for AURA and Kinetix rings.
- GPS Outdoor Route Tracker with live pace, splits, and GPX 1.1 exporter.
- Audio and visual cadence metronome (160 - 190 SPM).
- Olympic barbell plate calculator and Wilks/DOTS powerlifting scoring.
- Intermittent fasting window tracker with circadian stage markers.
- Antagonist superset and drop set workout logging.
- AI Coach with real-time biometric contextual streaming.
