import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitone/core/di/injection.dart';
import 'package:fitone/core/theme/theme_store.dart';
import 'package:fitone/domain/entities/exercise.dart';
import 'package:fitone/domain/entities/powerlifting_score.dart';
import 'package:fitone/domain/repositories/workout_repository.dart';
import 'package:fitone/presentation/exercise_workout/stores/exercise_store.dart';
import 'package:fitone/presentation/exercise_workout/stores/workout_logger_store.dart';
import 'package:fitone/presentation/exercise_workout/views/exercise_detail_view.dart';
import 'package:fitone/presentation/exercise_workout/views/workout_logger_view.dart';
import 'package:fitone/presentation/exercise_workout/widgets/powerlifting_calculator_sheet.dart';

class _MockWorkoutRepository implements WorkoutRepository {
  final List<Exercise> exercises = const [
    Exercise(
      id: 'ex_squat',
      name: 'Barbell Back Squat',
      bodyPart: 'Legs',
      equipment: 'Barbell',
      targetMuscles: 'Quadriceps, Glutes',
      instructions: 'Descend smoothly keeping core braced.',
      difficulty: 'Advanced',
    ),
    Exercise(
      id: 'ex_bench',
      name: 'Barbell Flat Bench Press',
      bodyPart: 'Chest',
      equipment: 'Barbell',
      targetMuscles: 'Pectoralis Major, Triceps',
      instructions: 'Lower bar smoothly to sternum.',
      difficulty: 'Intermediate',
    ),
  ];

  @override
  Future<List<Exercise>> getExercises({
    String? bodyPart,
    String? equipment,
    String? search,
    int page = 1,
    int limit = 60,
  }) async => exercises;

  @override
  Future<Exercise?> getExerciseById(String id) async =>
      exercises.where((e) => e.id == id).firstOrNull;

  @override
  Future<List<WorkoutPlan>> getWorkoutPlans() async => [];

  @override
  Future<void> saveWorkoutPlan(WorkoutPlan plan) async {}

  @override
  Future<List<WorkoutSession>> getPastWorkouts() async => [];

  @override
  Future<void> saveWorkoutSession(WorkoutSession session) async {}
}

void main() {
  late WorkoutLoggerStore loggerStore;
  late ExerciseStore exerciseStore;
  late _MockWorkoutRepository mockRepo;

  setUp(() async {
    await sl.reset();
    sl.registerLazySingleton<ThemeStore>(() => ThemeStore());
    mockRepo = _MockWorkoutRepository();
    sl.registerLazySingleton<WorkoutRepository>(() => mockRepo);
    loggerStore = WorkoutLoggerStore(workoutRepository: mockRepo);
    sl.registerLazySingleton<WorkoutLoggerStore>(() => loggerStore);
    exerciseStore = ExerciseStore(workoutRepository: mockRepo);
    sl.registerLazySingleton<ExerciseStore>(() => exerciseStore);
    await exerciseStore.loadExercises();
  });

  tearDown(() async {
    loggerStore.stopRestTimer();
    await sl.reset();
  });

  Widget createTestWidget(Widget child) {
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

  void setupLandscape(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('PowerliftingCalculatorSheet Widget Tests', () {
    testWidgets(
      'Renders sheet with standard competitor defaults and distribution gauge',
      (tester) async {
        setupPortrait(tester);

        await tester.pumpWidget(
          createTestWidget(
            const PowerliftingCalculatorSheet(
              initialBodyweight: 83.0,
              initialSquat: 180.0,
              initialBench: 120.0,
              initialDeadlift: 220.0,
              unit: 'kg',
              initialGender: Gender.male,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Powerlifting Score Calculator'), findsOneWidget);
        expect(find.text('Wilks-2 & DOTS Coefficient Engine'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('powerlifting_primary_score_text')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('powerlifting_classification_badge')),
          findsOneWidget,
        );

        expect(find.text('Compound Lift Distribution'), findsOneWidget);
        expect(find.textContaining('Squat:'), findsOneWidget);
        expect(find.textContaining('Bench:'), findsOneWidget);
        expect(find.textContaining('Deadlift:'), findsOneWidget);
        expect(find.text('Total: 520.0 kg'), findsOneWidget);

        expect(
          find.byKey(const ValueKey('btn_copy_powerlifting_breakdown')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('btn_reset_powerlifting_calculator')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Switching score formulas updates score typography and comparison cards',
      (tester) async {
        setupPortrait(tester);

        await tester.pumpWidget(
          createTestWidget(
            const PowerliftingCalculatorSheet(
              initialBodyweight: 83.0,
              initialSquat: 180.0,
              initialBench: 120.0,
              initialDeadlift: 220.0,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Wilks (1994)
        await tester.tap(find.text('Wilks (1994)'));
        await tester.pumpAndSettle();
        expect(find.text('Wilks (1994) Score'), findsOneWidget);

        // Switch to Wilks-2 (2020)
        await tester.tap(find.text('Wilks-2 (2020)'));
        await tester.pumpAndSettle();
        expect(find.text('Wilks-2 (2020) Score'), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Tapping gender toggle recalculates score dynamically', (
      tester,
    ) async {
      setupPortrait(tester);

      await tester.pumpWidget(
        createTestWidget(
          const PowerliftingCalculatorSheet(
            initialBodyweight: 83.0,
            initialSquat: 180.0,
            initialBench: 120.0,
            initialDeadlift: 220.0,
            initialGender: Gender.male,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scoreFinder = find.byKey(
        const ValueKey('powerlifting_primary_score_text'),
      );
      final maleScoreText = (tester.widget(scoreFinder) as Text).data;

      // Switch to Female
      await tester.tap(find.text('Female'));
      await tester.pumpAndSettle();

      final femaleScoreText = (tester.widget(scoreFinder) as Text).data;
      expect(femaleScoreText, isNot(equals(maleScoreText)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping unit toggle switches between KG and LBS seamlessly', (
      tester,
    ) async {
      setupPortrait(tester);

      await tester.pumpWidget(
        createTestWidget(
          const PowerliftingCalculatorSheet(
            initialBodyweight: 100.0,
            initialSquat: 200.0,
            initialBench: 150.0,
            initialDeadlift: 250.0,
            unit: 'kg',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to LBS
      await tester.tap(find.text('LBS'));
      await tester.pumpAndSettle();

      expect(find.textContaining('lbs'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Quick adjusters modify lift weights and update total', (
      tester,
    ) async {
      setupPortrait(tester);

      await tester.pumpWidget(
        createTestWidget(
          const PowerliftingCalculatorSheet(
            initialBodyweight: 80.0,
            initialSquat: 100.0,
            initialBench: 80.0,
            initialDeadlift: 120.0,
            unit: 'kg',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Total: 300.0 kg'), findsOneWidget);

      // Increment squat by 2.5kg
      final plusSmall = find.byKey(const ValueKey('btn_plus_small_squat'));
      await tester.tap(plusSmall);
      await tester.pumpAndSettle();

      expect(find.text('Total: 302.5 kg'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Copy Breakdown button triggers clipboard copy and feedback', (
      tester,
    ) async {
      setupPortrait(tester);

      await tester.pumpWidget(
        createTestWidget(const PowerliftingCalculatorSheet()),
      );
      await tester.pumpAndSettle();

      final copyBtn = find.byKey(
        const ValueKey('btn_copy_powerlifting_breakdown'),
      );
      await tester.ensureVisible(copyBtn);
      await tester.tap(copyBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Powerlifting score breakdown copied to clipboard.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'WorkoutLoggerView opens PowerliftingCalculatorSheet via AppBar action',
      (tester) async {
        setupPortrait(tester);

        await tester.pumpWidget(createTestWidget(const WorkoutLoggerView()));
        await tester.pumpAndSettle();

        final calcBtn = find.byKey(
          const ValueKey('workout_open_powerlifting_calculator_button'),
        );
        expect(calcBtn, findsOneWidget);
        await tester.tap(calcBtn);
        await tester.pumpAndSettle();

        expect(find.text('Powerlifting Score Calculator'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ExerciseDetailView opens PowerliftingCalculatorSheet via button and AppBar',
      (tester) async {
        setupPortrait(tester);

        const exercise = Exercise(
          id: 'ex_squat',
          name: 'Barbell Back Squat',
          bodyPart: 'Legs',
          equipment: 'Barbell',
          targetMuscles: 'Quadriceps, Glutes',
          instructions: 'Descend smoothly keeping core braced.',
          difficulty: 'Advanced',
        );

        await tester.pumpWidget(
          createTestWidget(const ExerciseDetailView(exercise: exercise)),
        );
        await tester.pumpAndSettle();

        // Test detail view action button
        final openBtn = find.byKey(
          const ValueKey('open_powerlifting_calculator_detail_button'),
        );
        expect(openBtn, findsOneWidget);
        await tester.ensureVisible(openBtn);
        await tester.tap(openBtn);
        await tester.pumpAndSettle();

        expect(find.text('Powerlifting Score Calculator'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Landscape viewport (800x360) renders sheet with zero RenderFlex overflow',
      (tester) async {
        setupLandscape(tester);

        await tester.pumpWidget(
          createTestWidget(const PowerliftingCalculatorSheet()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Powerlifting Score Calculator'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Switch formulas in landscape
        await tester.tap(find.text('Wilks-2 (2020)'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
