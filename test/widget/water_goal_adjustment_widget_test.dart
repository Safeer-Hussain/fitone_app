import 'package:fitone/core/di/injection.dart';
import 'package:fitone/core/theme/theme_store.dart';
import 'package:fitone/domain/entities/nutrition_day.dart';
import 'package:fitone/domain/entities/run_record.dart';
import 'package:fitone/domain/repositories/nutrition_repository.dart';
import 'package:fitone/domain/repositories/running_repository.dart';
import 'package:fitone/presentation/nutrition/stores/nutrition_store.dart';
import 'package:fitone/presentation/nutrition/widgets/hydration_tracker_card.dart';
import 'package:fitone/presentation/nutrition/widgets/water_adjustment_sheet.dart';
import 'package:flutter/material.dart';
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
  late NutritionStore store;
  late _FakeNutritionRepository nutritionRepo;
  late _FakeRunningRepository runningRepo;

  setUp(() async {
    await sl.reset();
    sl.registerLazySingleton<ThemeStore>(() => ThemeStore());

    nutritionRepo = _FakeNutritionRepository();
    final today = DateTime.now();
    runningRepo = _FakeRunningRepository([
      RunRecord(
        id: 'run_sample_today',
        title: 'Morning Tempo 5K',
        startTime: today,
        durationSeconds: 1500,
        distanceKm: 5.0, // +350ml bonus
        avgPaceSecPerKm: 300,
        elevationGainM: 12.0,
        caloriesBurned: 380.0,
        avgHeartRate: 152,
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

  tearDown(() async {
    store.dispose();
    await sl.reset();
  });

  Widget buildTestApp(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(body: child),
    );
  }

  void setupPortrait(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('HydrationTrackerCard Auto-Adjustment Widget Tests', () {
    testWidgets('Displays auto-adjusted target and adaptive chip', (
      tester,
    ) async {
      setupPortrait(tester);

      await tester.pumpWidget(buildTestApp(HydrationTrackerCard(store: store)));
      await tester.pumpAndSettle();

      expect(find.text('HYDRATION ENGINE'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('chip_adaptive_hydration_engine')),
        findsOneWidget,
      );
      expect(find.text('+350ml Auto'), findsOneWidget);
      expect(find.text('Target 2850 ml per day'), findsOneWidget);
    });

    testWidgets('Tapping adaptive chip opens WaterAdjustmentSheet', (
      tester,
    ) async {
      setupPortrait(tester);

      await tester.pumpWidget(buildTestApp(HydrationTrackerCard(store: store)));
      await tester.pumpAndSettle();

      final chipFinder = find.byKey(
        const ValueKey('chip_adaptive_hydration_engine'),
      );
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      expect(find.text('Adaptive Hydration Engine'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('text_dynamic_water_target')),
        findsOneWidget,
      );
      expect(find.text('2850 ml'), findsOneWidget);
    });

    testWidgets('Tapping tune button opens WaterAdjustmentSheet', (
      tester,
    ) async {
      setupPortrait(tester);

      await tester.pumpWidget(buildTestApp(HydrationTrackerCard(store: store)));
      await tester.pumpAndSettle();

      final tuneBtn = find.byKey(
        const ValueKey('btn_open_water_adjustment_sheet'),
      );
      await tester.tap(tuneBtn);
      await tester.pumpAndSettle();

      expect(find.text('Adaptive Hydration Engine'), findsOneWidget);
    });
  });

  group('WaterAdjustmentSheet Functional & Responsive Tests', () {
    testWidgets('Renders breakdown rows and toggle switch updates store', (
      tester,
    ) async {
      setupPortrait(tester);

      await tester.pumpWidget(buildTestApp(WaterAdjustmentSheet(store: store)));
      await tester.pumpAndSettle();

      expect(find.text('Adaptive Hydration Engine'), findsOneWidget);
      expect(find.text('2850 ml'), findsOneWidget);
      expect(find.text('Baseline Maintenance Requirement'), findsOneWidget);
      expect(find.text('GPS Running Fluid Compensation'), findsOneWidget);
      expect(find.text('+350 ml'), findsOneWidget);

      final switchFinder = find.byKey(
        const ValueKey('switch_adaptive_hydration'),
      );
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(store.autoAdjustmentEnabled, isFalse);
      final dynamicTargetFinder = find.byKey(
        const ValueKey('text_dynamic_water_target'),
      );
      expect(tester.widget<Text>(dynamicTargetFinder).data, equals('2500 ml'));
    });

    testWidgets('Baseline slider modifies target in store', (tester) async {
      setupPortrait(tester);

      await tester.pumpWidget(buildTestApp(WaterAdjustmentSheet(store: store)));
      await tester.pumpAndSettle();

      final sliderFinder = find.byKey(const ValueKey('slider_baseline_water'));
      expect(sliderFinder, findsOneWidget);

      store.setBaseWaterTarget(3000);
      await tester.pumpAndSettle();

      expect(store.baseWaterTargetMl, equals(3000));
      expect(find.text('3350 ml'), findsOneWidget);
    });

    testWidgets(
      'WaterAdjustmentSheet renders in 800x360 landscape without RenderFlex overflow',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildTestApp(WaterAdjustmentSheet(store: store)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Adaptive Hydration Engine'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
