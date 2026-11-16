import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/powerlifting_score.dart';

class PowerliftingCalculatorSheet extends StatefulWidget {
  final double initialBodyweight;
  final double initialSquat;
  final double initialBench;
  final double initialDeadlift;
  final String unit;
  final Gender initialGender;

  const PowerliftingCalculatorSheet({
    super.key,
    this.initialBodyweight = 83.0,
    this.initialSquat = 180.0,
    this.initialBench = 120.0,
    this.initialDeadlift = 220.0,
    this.unit = 'kg',
    this.initialGender = Gender.male,
  });

  static void show(
    BuildContext context, {
    double initialBodyweight = 83.0,
    double initialSquat = 180.0,
    double initialBench = 120.0,
    double initialDeadlift = 220.0,
    String unit = 'kg',
    Gender initialGender = Gender.male,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PowerliftingCalculatorSheet(
        initialBodyweight: initialBodyweight,
        initialSquat: initialSquat,
        initialBench: initialBench,
        initialDeadlift: initialDeadlift,
        unit: unit,
        initialGender: initialGender,
      ),
    );
  }

  @override
  State<PowerliftingCalculatorSheet> createState() =>
      _PowerliftingCalculatorSheetState();
}

class _PowerliftingCalculatorSheetState
    extends State<PowerliftingCalculatorSheet> {
  late String _unit;
  late Gender _gender;
  ScoreFormula _formula = ScoreFormula.dots;

  late double _bodyweight;
  late double _squat;
  late double _bench;
  late double _deadlift;

  late final TextEditingController _bwController;
  late final TextEditingController _squatController;
  late final TextEditingController _benchController;
  late final TextEditingController _deadliftController;

  @override
  void initState() {
    super.initState();
    _unit = widget.unit.toLowerCase() == 'lbs' ? 'lbs' : 'kg';
    _gender = widget.initialGender;

    _bodyweight = widget.initialBodyweight;
    _squat = widget.initialSquat;
    _bench = widget.initialBench;
    _deadlift = widget.initialDeadlift;

    _bwController = TextEditingController(text: _bodyweight.toStringAsFixed(1));
    _squatController = TextEditingController(text: _squat.toStringAsFixed(1));
    _benchController = TextEditingController(text: _bench.toStringAsFixed(1));
    _deadliftController = TextEditingController(
      text: _deadlift.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _bwController.dispose();
    _squatController.dispose();
    _benchController.dispose();
    _deadliftController.dispose();
    super.dispose();
  }

  void _toggleUnit(String newUnit) {
    if (_unit == newUnit) return;
    setState(() {
      if (newUnit == 'lbs') {
        _unit = 'lbs';
        _bodyweight = (_bodyweight * 2.20462 * 2).round() / 2.0;
        _squat = (_squat * 2.20462 * 2).round() / 2.0;
        _bench = (_bench * 2.20462 * 2).round() / 2.0;
        _deadlift = (_deadlift * 2.20462 * 2).round() / 2.0;
      } else {
        _unit = 'kg';
        _bodyweight = (_bodyweight / 2.20462 * 2).round() / 2.0;
        _squat = (_squat / 2.20462 * 2).round() / 2.0;
        _bench = (_bench / 2.20462 * 2).round() / 2.0;
        _deadlift = (_deadlift / 2.20462 * 2).round() / 2.0;
      }
      _syncControllers();
    });
  }

  void _syncControllers() {
    _bwController.text = _bodyweight.toStringAsFixed(1);
    _squatController.text = _squat.toStringAsFixed(1);
    _benchController.text = _bench.toStringAsFixed(1);
    _deadliftController.text = _deadlift.toStringAsFixed(1);
  }

  void _adjustField({
    required double current,
    required double delta,
    required double min,
    required double max,
    required void Function(double) onApplied,
  }) {
    final next = (current + delta).clamp(min, max);
    setState(() {
      onApplied(next);
      _syncControllers();
    });
  }

  double get _bwInKg => _unit == 'lbs' ? _bodyweight * 0.453592 : _bodyweight;
  double get _squatInKg => _unit == 'lbs' ? _squat * 0.453592 : _squat;
  double get _benchInKg => _unit == 'lbs' ? _bench * 0.453592 : _bench;
  double get _deadliftInKg => _unit == 'lbs' ? _deadlift * 0.453592 : _deadlift;

  PowerliftingScoreResult _computeResult() {
    return PowerliftingScoreCalculator.calculate(
      bodyweightKg: _bwInKg,
      squatKg: _squatInKg,
      benchKg: _benchInKg,
      deadliftKg: _deadliftInKg,
      gender: _gender,
    );
  }

  void _copyBreakdown(PowerliftingScoreResult result) {
    Clipboard.setData(ClipboardData(text: result.summaryDescription));
    AppFeedback.showSuccess(
      context,
      'Powerlifting score breakdown copied to clipboard.',
    );
  }

  void _resetDefaults() {
    setState(() {
      _bodyweight = _unit == 'kg' ? 83.0 : 183.0;
      _squat = _unit == 'kg' ? 180.0 : 396.0;
      _bench = _unit == 'kg' ? 120.0 : 264.0;
      _deadlift = _unit == 'kg' ? 220.0 : 485.0;
      _gender = Gender.male;
      _formula = ScoreFormula.dots;
      _syncControllers();
    });
    AppFeedback.showSuccess(context, 'Reset to standard competitor defaults.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final result = _computeResult();
    final totalDisplay = _squat + _bench + _deadlift;

    double activeScore;
    String activeFormulaName;
    switch (_formula) {
      case ScoreFormula.dots:
        activeScore = result.dotsScore;
        activeFormulaName = 'DOTS';
        break;
      case ScoreFormula.wilks:
        activeScore = result.wilksScore;
        activeFormulaName = 'Wilks (1994)';
        break;
      case ScoreFormula.wilks2:
        activeScore = result.wilks2Score;
        activeFormulaName = 'Wilks-2 (2020)';
        break;
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height *
                (isLandscape ? 0.96 : 0.88),
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sports_score_rounded,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Powerlifting Score Calculator',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Wilks-2 & DOTS Coefficient Engine',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderControls(colorScheme),
                      const SizedBox(height: 12),
                      _buildScoreHeroCard(
                        result: result,
                        activeScore: activeScore,
                        activeFormulaName: activeFormulaName,
                        totalDisplay: totalDisplay,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 12),
                      _buildCompoundBreakdownBar(
                        result: result,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 12),
                      _buildBodyweightCard(colorScheme),
                      const SizedBox(height: 12),
                      _buildCompoundLiftsCard(colorScheme),
                      const SizedBox(height: 12),
                      _buildFormulaComparisonGrid(
                        result: result,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 16),
                      _buildActionButtons(result, colorScheme),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderControls(ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'kg', label: Text('KG')),
                  ButtonSegment(value: 'lbs', label: Text('LBS')),
                ],
                selected: {_unit},
                onSelectionChanged: (s) => _toggleUnit(s.first),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SegmentedButton<Gender>(
                segments: const [
                  ButtonSegment(
                    value: Gender.male,
                    label: Text('Male'),
                    icon: Icon(Icons.male_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: Gender.female,
                    label: Text('Female'),
                    icon: Icon(Icons.female_rounded, size: 16),
                  ),
                ],
                selected: {_gender},
                onSelectionChanged: (s) => setState(() => _gender = s.first),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreHeroCard({
    required PowerliftingScoreResult result,
    required double activeScore,
    required String activeFormulaName,
    required double totalDisplay,
    required ColorScheme colorScheme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ScoreFormula>(
              segments: const [
                ButtonSegment(value: ScoreFormula.dots, label: Text('DOTS')),
                ButtonSegment(
                  value: ScoreFormula.wilks,
                  label: Text('Wilks (1994)'),
                ),
                ButtonSegment(
                  value: ScoreFormula.wilks2,
                  label: Text('Wilks-2 (2020)'),
                ),
              ],
              selected: {_formula},
              onSelectionChanged: (s) => setState(() => _formula = s.first),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            activeScore.toStringAsFixed(2),
            key: const ValueKey('powerlifting_primary_score_text'),
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: colorScheme.primary,
              letterSpacing: -1,
            ),
          ),
          Text(
            '$activeFormulaName Score',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.classificationLabel,
                  key: const ValueKey('powerlifting_classification_badge'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${result.bodyweightMultiplier.toStringAsFixed(2)}x Bodyweight',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total: ${totalDisplay.toStringAsFixed(1)} $_unit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompoundBreakdownBar({
    required PowerliftingScoreResult result,
    required ColorScheme colorScheme,
  }) {
    final sqPct = result.squatPercentage;
    final bpPct = result.benchPercentage;
    final dlPct = result.deadliftPercentage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Compound Lift Distribution',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'SQ • BP • DL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (sqPct * 10).round().clamp(1, 1000),
                    child: Container(color: colorScheme.primary),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (bpPct * 10).round().clamp(1, 1000),
                    child: Container(color: colorScheme.secondary),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (dlPct * 10).round().clamp(1, 1000),
                    child: Container(color: colorScheme.tertiary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(
                label: 'Squat',
                pct: sqPct,
                color: colorScheme.primary,
                colorScheme: colorScheme,
              ),
              _buildLegendItem(
                label: 'Bench',
                pct: bpPct,
                color: colorScheme.secondary,
                colorScheme: colorScheme,
              ),
              _buildLegendItem(
                label: 'Deadlift',
                pct: dlPct,
                color: colorScheme.tertiary,
                colorScheme: colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required String label,
    required double pct,
    required Color color,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ${pct.toStringAsFixed(1)}%',
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildBodyweightCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Athlete Bodyweight ($_unit)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          _buildAdjustableInputRow(
            keyTag: 'bodyweight',
            controller: _bwController,
            current: _bodyweight,
            stepSmall: 1.0,
            stepLarge: 5.0,
            min: 30.0,
            max: 300.0,
            onApplied: (v) => _bodyweight = v,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildCompoundLiftsCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compound Lifts Max Attempt ($_unit)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          _buildLiftRow(
            label: '1. Squat',
            keyTag: 'squat',
            controller: _squatController,
            current: _squat,
            color: colorScheme.primary,
            onApplied: (v) => _squat = v,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 10),
          _buildLiftRow(
            label: '2. Bench Press',
            keyTag: 'bench',
            controller: _benchController,
            current: _bench,
            color: colorScheme.secondary,
            onApplied: (v) => _bench = v,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 10),
          _buildLiftRow(
            label: '3. Deadlift',
            keyTag: 'deadlift',
            controller: _deadliftController,
            current: _deadlift,
            color: colorScheme.tertiary,
            onApplied: (v) => _deadlift = v,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildLiftRow({
    required String label,
    required String keyTag,
    required TextEditingController controller,
    required double current,
    required Color color,
    required void Function(double) onApplied,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildAdjustableInputRow(
          keyTag: keyTag,
          controller: controller,
          current: current,
          stepSmall: 2.5,
          stepLarge: 10.0,
          min: 0.0,
          max: 600.0,
          onApplied: onApplied,
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildAdjustableInputRow({
    required String keyTag,
    required TextEditingController controller,
    required double current,
    required double stepSmall,
    required double stepLarge,
    required double min,
    required double max,
    required void Function(double) onApplied,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        IconButton(
          key: ValueKey('btn_minus_large_$keyTag'),
          icon: const Icon(Icons.keyboard_double_arrow_left, size: 18),
          visualDensity: VisualDensity.compact,
          tooltip: '-${stepLarge.toStringAsFixed(0)}',
          onPressed: () => _adjustField(
            current: current,
            delta: -stepLarge,
            min: min,
            max: max,
            onApplied: onApplied,
          ),
        ),
        IconButton(
          key: ValueKey('btn_minus_small_$keyTag'),
          icon: const Icon(Icons.remove, size: 16),
          visualDensity: VisualDensity.compact,
          tooltip: '-${stepSmall.toStringAsFixed(1)}',
          onPressed: () => _adjustField(
            current: current,
            delta: -stepSmall,
            min: min,
            max: max,
            onApplied: onApplied,
          ),
        ),
        Expanded(
          child: TextField(
            key: ValueKey('field_$keyTag'),
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              suffixText: _unit,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val);
              if (parsed != null && parsed >= min && parsed <= max) {
                setState(() {
                  onApplied(parsed);
                });
              }
            },
          ),
        ),
        IconButton(
          key: ValueKey('btn_plus_small_$keyTag'),
          icon: const Icon(Icons.add, size: 16),
          visualDensity: VisualDensity.compact,
          tooltip: '+${stepSmall.toStringAsFixed(1)}',
          onPressed: () => _adjustField(
            current: current,
            delta: stepSmall,
            min: min,
            max: max,
            onApplied: onApplied,
          ),
        ),
        IconButton(
          key: ValueKey('btn_plus_large_$keyTag'),
          icon: const Icon(Icons.keyboard_double_arrow_right, size: 18),
          visualDensity: VisualDensity.compact,
          tooltip: '+${stepLarge.toStringAsFixed(0)}',
          onPressed: () => _adjustField(
            current: current,
            delta: stepLarge,
            min: min,
            max: max,
            onApplied: onApplied,
          ),
        ),
      ],
    );
  }

  Widget _buildFormulaComparisonGrid({
    required PowerliftingScoreResult result,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Multi-Formula Comparison',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildComparisonCard(
                  title: 'DOTS',
                  score: result.dotsScore,
                  isSelected: _formula == ScoreFormula.dots,
                  colorScheme: colorScheme,
                  onTap: () => setState(() => _formula = ScoreFormula.dots),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildComparisonCard(
                  title: 'Wilks',
                  score: result.wilksScore,
                  isSelected: _formula == ScoreFormula.wilks,
                  colorScheme: colorScheme,
                  onTap: () => setState(() => _formula = ScoreFormula.wilks),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildComparisonCard(
                  title: 'Wilks-2',
                  score: result.wilks2Score,
                  isSelected: _formula == ScoreFormula.wilks2,
                  colorScheme: colorScheme,
                  onTap: () => setState(() => _formula = ScoreFormula.wilks2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard({
    required String title,
    required double score,
    required bool isSelected,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    PowerliftingScoreResult result,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            key: const ValueKey('btn_copy_powerlifting_breakdown'),
            onPressed: () => _copyBreakdown(result),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text(
              'Copy Score Breakdown',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            key: const ValueKey('btn_reset_powerlifting_calculator'),
            onPressed: _resetDefaults,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reset Defaults'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
              side: BorderSide(color: colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
