import 'package:fitone/domain/entities/nutrition_day.dart';
import 'package:fitone/domain/entities/run_record.dart';
import 'package:fitone/domain/entities/water_goal_adjustment.dart';
import 'package:fitone/domain/repositories/nutrition_repository.dart';
import 'package:fitone/domain/repositories/running_repository.dart';
import 'package:fitone/presentation/nutrition/stores/nutrition_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNutritionRepository implements NutritionRepository {
  DailyNutritionSummary summary = DailyNutritionSummary(
    dateStr: '2026-11-18',
    targetWaterMl: 2500,
    mealItems: const [],
    waterItems: [
      HydrationLogItem(
        id: 'w1',
        dateStr: '2026-11-18',
        amountMl: 500,
        timestamp: DateTime(2026, 11, 18, 8, 0),
      ),
    ],
  );

  @override
  Future<DailyNutritionSummary> getDailySummary(String dateStr) async =>
      summary;

  @override
  Future<void> addFoodEntry(NutritionLogItem item) async {}

  @override
  Future<void> deleteFoodEntry(String id) async {}

  @override
  Future<void> logHydration(HydrationLogItem item) async {
    final updatedList = List<HydrationLogItem>.from(summary.waterItems)
      ..add(item);
    summary = summary.copyWith(waterItems: updatedList);
  }

  @override
  Future<void> resetDayHydration(String dateStr) async {
    summary = summary.copyWith(waterItems: []);
  }
}

class _FakeRunningRepository implements RunningRepository {
  final List<RunRecord> runs;
  _FakeRunningRepository(this.runs);

  @override
  Future<List<RunRecord>> getRunHistory() async => runs;

  @override
  Future<RunRecord?> getRunById(String id) async => null;

  @override
  Future<void> saveRunRecord(RunRecord run) async => runs.add(run);
}

void main() {
  group('WaterGoalAdjustment Domain Unit Tests', () {
    test('Default constructor sets 2500ml base with zero adjustments', () {
      const adj = WaterGoalAdjustment();

      expect(adj.baseTargetMl, equals(2500));
      expect(adj.runningDistanceKm, equals(0.0));
      expect(adj.skinTempDelta, equals(0.0));
      expect(adj.runningAdjustmentMl, equals(0));
      expect(adj.thermalAdjustmentMl, equals(0));
      expect(adj.totalAdjustmentMl, equals(0));
      expect(adj.adjustedTargetMl, equals(2500));
      expect(adj.hasActiveAdjustment, isFalse);
    });

    test('Running distance adds +350ml per 5km accurately', () {
      const adj5km = WaterGoalAdjustment(runningDistanceKm: 5.0);
      expect(adj5km.runningAdjustmentMl, equals(350));
      expect(adj5km.adjustedTargetMl, equals(2850));

      const adj10km = WaterGoalAdjustment(runningDistanceKm: 10.0);
      expect(adj10km.runningAdjustmentMl, equals(700));
      expect(adj10km.adjustedTargetMl, equals(3200));

      const adj2_5km = WaterGoalAdjustment(runningDistanceKm: 2.5);
      expect(adj2_5km.runningAdjustmentMl, equals(175));

      const adj7_5km = WaterGoalAdjustment(runningDistanceKm: 7.5);
      expect(adj7_5km.runningAdjustmentMl, equals(525));
    });

    test('Wearable skin temperature delta adds thermal sweat compensation', () {
      const normalTemp = WaterGoalAdjustment(skinTempDelta: 0.0);
      expect(normalTemp.thermalAdjustmentMl, equals(0));

      const coolTemp = WaterGoalAdjustment(skinTempDelta: -0.4);
      expect(coolTemp.thermalAdjustmentMl, equals(0));

      const elevated0_5 = WaterGoalAdjustment(skinTempDelta: 0.5);
      expect(elevated0_5.thermalAdjustmentMl, equals(200));

      const elevated1_0 = WaterGoalAdjustment(skinTempDelta: 1.0);
      expect(elevated1_0.thermalAdjustmentMl, equals(400));
    });

    test(
      'Combined workout and thermal load adjust daily target dynamically',
      () {
        const combined = WaterGoalAdjustment(
          baseTargetMl: 2500,
          runningDistanceKm: 10.0, // +700ml
          skinTempDelta: 0.5, // +200ml
          consumedWaterMl: 1700,
        );

        expect(combined.runningAdjustmentMl, equals(700));
        expect(combined.thermalAdjustmentMl, equals(200));
        expect(combined.totalAdjustmentMl, equals(900));
        expect(combined.adjustedTargetMl, equals(3400));
        expect(combined.remainingWaterMl, equals(1700));
        expect(combined.progress, equals(0.5));
        expect(combined.status, equals(HydrationStatus.onTrack));
        expect(combined.statusLabel, equals('Hydration On Track'));
        expect(combined.hasActiveAdjustment, isTrue);
        expect(combined.physiologicalSummary, contains('+700ml for 10.0km'));
        expect(combined.physiologicalSummary, contains('+200ml for +0.5°C'));
      },
    );

    test('Disabling adaptive engine reverts target to baseline', () {
      const disabled = WaterGoalAdjustment(
        baseTargetMl: 2500,
        runningDistanceKm: 10.0,
        skinTempDelta: 1.0,
        isEnabled: false,
      );

      expect(disabled.runningAdjustmentMl, equals(0));
      expect(disabled.thermalAdjustmentMl, equals(0));
      expect(disabled.adjustedTargetMl, equals(2500));
      expect(disabled.hasActiveAdjustment, isFalse);
    });

    test(
      'HydrationStatus flags dehydrated, onTrack, and targetReached accurately',
      () {
        const dehydrated = WaterGoalAdjustment(
          baseTargetMl: 2500,
          consumedWaterMl: 800,
        );
        expect(dehydrated.status, equals(HydrationStatus.dehydrated));
        expect(dehydrated.statusLabel, equals('Fluid Intake Needed'));

        const reached = WaterGoalAdjustment(
          baseTargetMl: 2500,
          consumedWaterMl: 2600,
        );
        expect(reached.status, equals(HydrationStatus.targetReached));
        expect(reached.statusLabel, equals('Hydration Target Reached'));
      },
    );
  });

  group('NutritionStore Auto-Adjustment State Unit Tests', () {
    late NutritionStore store;
    late _FakeNutritionRepository nutritionRepo;
    late _FakeRunningRepository runningRepo;

    setUp(() async {
      nutritionRepo = _FakeNutritionRepository();
      final today = DateTime.now();
      runningRepo = _FakeRunningRepository([
        RunRecord(
          id: 'run_today_1',
          title: 'Morning Tempo',
          startTime: today,
          durationSeconds: 1500,
          distanceKm: 5.0, // +350ml
          avgPaceSecPerKm: 300,
          elevationGainM: 10.0,
          caloriesBurned: 350.0,
          avgHeartRate: 150,
          coordinates: const [],
          splits: const [],
        ),
      ]);

      store = NutritionStore(
        nutritionRepository: nutritionRepo,
        runningRepository: runningRepo,
      );
      store.initialize();
      await store.loadDailySummary();
    });

    tearDown(() {
      store.dispose();
    });

    test(
      'Initializes with running distance and adjusts water target',
      () async {
        await store.loadDailySummary();

        expect(store.todayRunningKm, equals(5.0));
        expect(store.baseWaterTargetMl, equals(2500));
        expect(store.waterAdjustment.runningAdjustmentMl, equals(350));
        expect(store.dailySummary?.targetWaterMl, equals(2850));
      },
    );

    test(
      'setBaseWaterTarget updates baseline and recalculates dynamic target',
      () {
        store.setBaseWaterTarget(3000);
        expect(store.baseWaterTargetMl, equals(3000));
        expect(store.waterAdjustment.adjustedTargetMl, equals(3350));
      },
    );

    test('setManualSkinTempDelta updates thermal compensation', () {
      store.setManualSkinTempDelta(0.5);
      expect(store.latestSkinTempDelta, equals(0.5));
      expect(store.waterAdjustment.thermalAdjustmentMl, equals(200));
      expect(store.waterAdjustment.adjustedTargetMl, equals(3050));
    });

    test('toggleAutoAdjustment toggles adaptive engine on and off', () {
      expect(store.autoAdjustmentEnabled, isTrue);

      store.toggleAutoAdjustment();
      expect(store.autoAdjustmentEnabled, isFalse);
      expect(store.waterAdjustment.adjustedTargetMl, equals(2500));

      store.toggleAutoAdjustment();
      expect(store.autoAdjustmentEnabled, isTrue);
      expect(store.waterAdjustment.adjustedTargetMl, equals(2850));
    });

    test(
      'logWater updates consumed amount and re-evaluates remaining water',
      () async {
        await store.logWater(500);
        expect(store.dailySummary?.consumedWaterMl, equals(1000));
        expect(store.waterAdjustment.consumedWaterMl, equals(1000));
      },
    );
  });
}
