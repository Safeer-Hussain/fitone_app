import 'dart:async';

import 'package:mobx/mobx.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/nutrition_day.dart';
import '../../../domain/entities/water_goal_adjustment.dart';
import '../../../domain/repositories/nutrition_repository.dart';
import '../../../domain/repositories/ring_repository.dart';
import '../../../domain/repositories/running_repository.dart';

class NutritionStore {
  final NutritionRepository nutritionRepository;
  final RunningRepository? runningRepository;
  final RingRepository? ringRepository;

  NutritionStore({
    required this.nutritionRepository,
    this.runningRepository,
    this.ringRepository,
  });

  final _isLoading = Observable<bool>(false);
  bool get isLoading => _isLoading.value;

  final _hasError = Observable<bool>(false);
  bool get hasError => _hasError.value;

  final _dailySummary = Observable<DailyNutritionSummary?>(null);
  DailyNutritionSummary? get dailySummary => _dailySummary.value;

  final _selectedDateStr = Observable<String>('');
  String get selectedDateStr => _selectedDateStr.value;

  final _waterStreakDays = Observable<int>(14);
  int get waterStreakDays => _waterStreakDays.value;

  // --- Water Intake Goal Auto-Adjustment Observables ---
  final _baseWaterTargetMl = Observable<int>(2500);
  int get baseWaterTargetMl => _baseWaterTargetMl.value;

  final _autoAdjustmentEnabled = Observable<bool>(true);
  bool get autoAdjustmentEnabled => _autoAdjustmentEnabled.value;

  final _todayRunningKm = Observable<double>(0.0);
  double get todayRunningKm => _todayRunningKm.value;

  final _latestSkinTempDelta = Observable<double>(0.0);
  double get latestSkinTempDelta => _latestSkinTempDelta.value;

  final _waterAdjustment = Observable<WaterGoalAdjustment?>(null);
  WaterGoalAdjustment get waterAdjustment {
    return _waterAdjustment.value ??
        WaterGoalAdjustment(
          baseTargetMl: _baseWaterTargetMl.value,
          runningDistanceKm: _todayRunningKm.value,
          skinTempDelta: _latestSkinTempDelta.value,
          consumedWaterMl: _dailySummary.value?.consumedWaterMl ?? 0,
          isEnabled: _autoAdjustmentEnabled.value,
        );
  }

  StreamSubscription? _ringSub;

  void initialize() {
    final now = DateTime.now();
    _selectedDateStr.value =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    _ringSub?.cancel();
    if (ringRepository != null) {
      _ringSub = ringRepository!.watchTelemetry().listen((telemetry) {
        runInAction(() {
          _latestSkinTempDelta.value = telemetry.skinTempDelta;
        });
        _recalculateWaterAdjustment();
      });
    }

    loadDailySummary();
  }

  Future<void> loadDailySummary() async {
    runInAction(() {
      _isLoading.value = true;
      _hasError.value = false;
    });

    try {
      final summary = await nutritionRepository.getDailySummary(
        _selectedDateStr.value,
      );

      // Fetch running distance logged today
      if (runningRepository != null) {
        try {
          final runs = await runningRepository!.getRunHistory();
          double kmSum = 0.0;
          for (final run in runs) {
            final runDateStr =
                '${run.startTime.year}-${run.startTime.month.toString().padLeft(2, '0')}-${run.startTime.day.toString().padLeft(2, '0')}';
            if (runDateStr == _selectedDateStr.value) {
              kmSum += run.distanceKm;
            }
          }
          runInAction(() {
            _todayRunningKm.value = kmSum;
          });
        } catch (_) {}
      }

      // Fetch recent wearable ambient skin temperature delta
      if (ringRepository != null && _latestSkinTempDelta.value == 0.0) {
        try {
          final history = await ringRepository!.getHistoricalTelemetry();
          if (history.isNotEmpty) {
            runInAction(() {
              _latestSkinTempDelta.value = history.last.skinTempDelta;
            });
          }
        } catch (_) {}
      }

      final adj = WaterGoalAdjustment(
        baseTargetMl: _baseWaterTargetMl.value,
        runningDistanceKm: _todayRunningKm.value,
        skinTempDelta: _latestSkinTempDelta.value,
        consumedWaterMl: summary.consumedWaterMl,
        isEnabled: _autoAdjustmentEnabled.value,
      );

      runInAction(() {
        _waterAdjustment.value = adj;
        _dailySummary.value = summary.copyWith(
          targetWaterMl: adj.adjustedTargetMl,
        );
      });
    } catch (_) {
      runInAction(() {
        _hasError.value = true;
      });
    } finally {
      runInAction(() => _isLoading.value = false);
    }
  }

  void toggleAutoAdjustment() {
    runInAction(() {
      _autoAdjustmentEnabled.value = !_autoAdjustmentEnabled.value;
    });
    _recalculateWaterAdjustment();
  }

  void setBaseWaterTarget(int targetMl) {
    runInAction(() {
      _baseWaterTargetMl.value = targetMl.clamp(1000, 6000);
    });
    _recalculateWaterAdjustment();
  }

  void setManualRunningKm(double km) {
    runInAction(() {
      _todayRunningKm.value = km.clamp(0.0, 100.0);
    });
    _recalculateWaterAdjustment();
  }

  void setManualSkinTempDelta(double delta) {
    runInAction(() {
      _latestSkinTempDelta.value = delta.clamp(-5.0, 10.0);
    });
    _recalculateWaterAdjustment();
  }

  void _recalculateWaterAdjustment() {
    final currentSummary = _dailySummary.value;
    final adj = WaterGoalAdjustment(
      baseTargetMl: _baseWaterTargetMl.value,
      runningDistanceKm: _todayRunningKm.value,
      skinTempDelta: _latestSkinTempDelta.value,
      consumedWaterMl: currentSummary?.consumedWaterMl ?? 0,
      isEnabled: _autoAdjustmentEnabled.value,
    );

    runInAction(() {
      _waterAdjustment.value = adj;
      if (currentSummary != null) {
        _dailySummary.value = currentSummary.copyWith(
          targetWaterMl: adj.adjustedTargetMl,
        );
      }
    });
  }

  Future<void> addFood({
    required String mealType,
    required String foodName,
    required double calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) async {
    final item = NutritionLogItem(
      id: const Uuid().v4(),
      dateStr: _selectedDateStr.value,
      mealType: mealType,
      foodName: foodName,
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      timestamp: DateTime.now(),
    );

    await nutritionRepository.addFoodEntry(item);
    await loadDailySummary();
  }

  Future<void> deleteFood(String id) async {
    await nutritionRepository.deleteFoodEntry(id);
    await loadDailySummary();
  }

  Future<void> logWater(int amountMl) async {
    final item = HydrationLogItem(
      id: const Uuid().v4(),
      dateStr: _selectedDateStr.value,
      amountMl: amountMl,
      timestamp: DateTime.now(),
    );

    await nutritionRepository.logHydration(item);
    await loadDailySummary();
  }

  Future<void> resetHydration() async {
    await nutritionRepository.resetDayHydration(_selectedDateStr.value);
    await loadDailySummary();
  }

  void dispose() {
    _ringSub?.cancel();
  }
}
