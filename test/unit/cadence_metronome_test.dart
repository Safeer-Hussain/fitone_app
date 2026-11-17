import 'dart:async';

import 'package:fitone/domain/entities/cadence_metronome.dart';
import 'package:fitone/domain/entities/ring_telemetry.dart';
import 'package:fitone/domain/entities/run_record.dart';
import 'package:fitone/domain/repositories/ring_repository.dart';
import 'package:fitone/domain/repositories/running_repository.dart';
import 'package:fitone/presentation/gps_running/stores/gps_running_store.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRunningRepository implements RunningRepository {
  final List<RunRecord> runs = [];

  @override
  Future<List<RunRecord>> getRunHistory() async => runs;

  @override
  Future<RunRecord?> getRunById(String id) async {
    try {
      return runs.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveRunRecord(RunRecord run) async {
    runs.add(run);
  }
}

class FakeRingRepository implements RingRepository {
  final StreamController<RingTelemetry> controller =
      StreamController<RingTelemetry>.broadcast();

  @override
  Future<List<RingDevice>> getDiscoveredDevices() async => [];

  @override
  Future<void> connectRing(String deviceId, String sdkType) async {}

  @override
  Future<void> disconnectRing() async {}

  @override
  Future<HardwareDiagnostics> getHardwareDiagnostics() async =>
      const HardwareDiagnostics(
        opticalPPG: 'PASSED',
        temperatureSensor: 'PASSED',
        sixAxisIMU: 'NORMAL',
        bleTransceiver: 'OPTIMAL',
        internalNAND: 'HEALTHY',
        batteryHealth: '100%',
      );

  @override
  Future<void> updateTelemetryRate(int intervalMs) async {}

  @override
  Stream<RingTelemetry> watchTelemetry() => controller.stream;

  @override
  Future<List<RingTelemetry>> getHistoricalTelemetry({
    Duration duration = const Duration(hours: 24),
  }) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CadenceMetronomeConfig Domain Unit Tests', () {
    test(
      'Default configuration initializes with 175 SPM and standard values',
      () {
        const config = CadenceMetronomeConfig();

        expect(config.spm, equals(175));
        expect(config.isEnabled, isFalse);
        expect(config.audioEnabled, isTrue);
        expect(config.hapticEnabled, isTrue);
        expect(config.intervalMs, equals((60000 / 175).round()));
        expect(config.tickInterval, equals(const Duration(milliseconds: 343)));
        expect(config.zone, equals(CadenceZone.optimal));
        expect(config.zoneLabel, equals('Optimal Race Pace'));
        expect(
          config.impactReductionSummary,
          contains('Peak biomechanical efficiency'),
        );
      },
    );

    test('Cadence zone categorizes accurately across thresholds', () {
      const c150 = CadenceMetronomeConfig(spm: 150);
      expect(c150.zone, equals(CadenceZone.recovery));
      expect(c150.zoneLabel, contains('Recovery'));

      const c170 = CadenceMetronomeConfig(spm: 170);
      expect(c170.zone, equals(CadenceZone.aerobic));
      expect(c170.zoneLabel, contains('Aerobic'));

      const c175 = CadenceMetronomeConfig(spm: 175);
      expect(c175.zone, equals(CadenceZone.optimal));
      expect(c175.zoneLabel, contains('Optimal'));

      const c182 = CadenceMetronomeConfig(spm: 182);
      expect(c182.zone, equals(CadenceZone.optimal));
      expect(c182.zoneLabel, contains('Optimal'));

      const c195 = CadenceMetronomeConfig(spm: 195);
      expect(c195.zone, equals(CadenceZone.sprint));
      expect(c195.zoneLabel, contains('Sprint'));
    });

    test('Standard presets list contains valid runner cadence values', () {
      expect(
        CadenceMetronomeConfig.standardPresets,
        equals([160, 165, 170, 175, 180, 185, 190]),
      );
    });

    test('copyWith properly updates selective properties', () {
      const config = CadenceMetronomeConfig(spm: 170);
      final updated = config.copyWith(spm: 180, isEnabled: true);

      expect(updated.spm, equals(180));
      expect(updated.isEnabled, isTrue);
      expect(updated.audioEnabled, isTrue);
      expect(updated.hapticEnabled, isTrue);
      expect(updated.intervalMs, equals(333));
    });
  });

  group('GpsRunningStore Metronome State Unit Tests', () {
    late GpsRunningStore store;
    late FakeRunningRepository runningRepo;
    late FakeRingRepository ringRepo;

    setUp(() {
      runningRepo = FakeRunningRepository();
      ringRepo = FakeRingRepository();
      store = GpsRunningStore(
        runningRepository: runningRepo,
        ringRepository: ringRepo,
      );
    });

    tearDown(() {
      store.dispose();
      ringRepo.controller.close();
    });

    test('Initial metronome state is disabled at 175 SPM', () {
      expect(store.isMetronomeEnabled, isFalse);
      expect(store.cadenceSpm, equals(175));
      expect(store.metronomeAudioEnabled, isTrue);
      expect(store.metronomeHapticEnabled, isTrue);
      expect(store.metronomeBeat, equals(0));
      expect(store.isBeatFlash, isFalse);
    });

    test('setCadenceSpm modifies SPM and clamps values within safe range', () {
      store.setCadenceSpm(185);
      expect(store.cadenceSpm, equals(185));

      store.setCadenceSpm(120);
      expect(store.cadenceSpm, equals(140));

      store.setCadenceSpm(260);
      expect(store.cadenceSpm, equals(220));
    });

    test(
      'toggleMetronome switches enabled state and resets beat indicator',
      () {
        expect(store.isMetronomeEnabled, isFalse);

        store.toggleMetronome();
        expect(store.isMetronomeEnabled, isTrue);
        expect(store.metronomeBeat, equals(0));

        store.toggleMetronome();
        expect(store.isMetronomeEnabled, isFalse);
      },
    );

    test('toggleMetronomeAudio and toggleMetronomeHaptic update flags', () {
      expect(store.metronomeAudioEnabled, isTrue);
      store.toggleMetronomeAudio();
      expect(store.metronomeAudioEnabled, isFalse);
      store.toggleMetronomeAudio();
      expect(store.metronomeAudioEnabled, isTrue);

      expect(store.metronomeHapticEnabled, isTrue);
      store.toggleMetronomeHaptic();
      expect(store.metronomeHapticEnabled, isFalse);
      store.toggleMetronomeHaptic();
      expect(store.metronomeHapticEnabled, isTrue);
    });

    test(
      'Metronome stops automatically on cancelRun and finishAndSaveRun',
      () async {
        store.startMetronome();
        expect(store.isMetronomeEnabled, isTrue);

        store.cancelRun();
        expect(store.isMetronomeEnabled, isFalse);

        store.startMetronome();
        expect(store.isMetronomeEnabled, isTrue);

        await store.finishAndSaveRun(title: 'Test Run');
        expect(store.isMetronomeEnabled, isFalse);
      },
    );
  });
}
