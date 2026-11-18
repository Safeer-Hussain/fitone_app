import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../core/utils/app_feedback.dart';
import '../stores/nutrition_store.dart';

class WaterAdjustmentSheet extends StatelessWidget {
  final NutritionStore store;

  const WaterAdjustmentSheet({super.key, required this.store});

  static void show(BuildContext context, {required NutritionStore store}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WaterAdjustmentSheet(store: store),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Observer(
      builder: (_) {
        final adjustment = store.waterAdjustment;
        final isEnabled = store.autoAdjustmentEnabled;
        final baseTarget = store.baseWaterTargetMl;
        final runKm = store.todayRunningKm;
        final skinTemp = store.latestSkinTempDelta;

        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(context).size.height *
                    (isLandscape ? 0.95 : 0.88),
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
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
                          Icons.water_drop_rounded,
                          color: colorScheme.secondary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Adaptive Hydration Engine',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'GPS Distance & Thermal Auto-Adjustment',
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildToggleCard(
                            isEnabled: isEnabled,
                            onChanged: (val) {
                              store.toggleAutoAdjustment();
                              AppFeedback.showInfo(
                                context,
                                store.autoAdjustmentEnabled
                                    ? 'Adaptive hydration enabled'
                                    : 'Adaptive hydration disabled (fixed baseline)',
                              );
                            },
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryTargetCard(
                            adjustment: adjustment,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 12),
                          _buildBreakdownSection(
                            baseTarget: baseTarget,
                            runKm: runKm,
                            runBonus: adjustment.runningAdjustmentMl,
                            skinTemp: skinTemp,
                            tempBonus: adjustment.thermalAdjustmentMl,
                            isEnabled: isEnabled,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 12),
                          _buildBaselineSliderCard(
                            baseTarget: baseTarget,
                            onChanged: (val) =>
                                store.setBaseWaterTarget(val.round()),
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 12),
                          _buildClinicalGuidanceCard(
                            summary: adjustment.physiologicalSummary,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleCard({
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: colorScheme.secondary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dynamic Biometric Adaptation',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Adjust goal for running sweat loss and ring skin temp',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            key: const ValueKey('switch_adaptive_hydration'),
            value: isEnabled,
            onChanged: onChanged,
            activeColor: colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTargetCard({
    required dynamic adjustment,
    required ColorScheme colorScheme,
  }) {
    final int adjustedTarget = adjustment.adjustedTargetMl;
    final int consumed = adjustment.consumedWaterMl;
    final int remaining = adjustment.remainingWaterMl;
    final double progress = adjustment.progress;

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
          Text(
            'TODAY\'S DYNAMIC HYDRATION GOAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$adjustedTarget ml',
            key: const ValueKey('text_dynamic_water_target'),
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: colorScheme.secondary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
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
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  adjustment.statusLabel,
                  key: const ValueKey('badge_hydration_status'),
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
                  '${(progress * 100).toInt()}% • $consumed ml drank • $remaining ml left',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

  Widget _buildBreakdownSection({
    required int baseTarget,
    required double runKm,
    required int runBonus,
    required double skinTemp,
    required int tempBonus,
    required bool isEnabled,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target Calculation Breakdown',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          _buildBreakdownRow(
            icon: Icons.flag_outlined,
            label: 'Baseline Maintenance Requirement',
            detail: 'Sedentary homeostatic requirement',
            value: '$baseTarget ml',
            colorScheme: colorScheme,
            accentColor: colorScheme.onSurface,
          ),
          const Divider(height: 16),
          _buildBreakdownRow(
            icon: Icons.directions_run_rounded,
            label: 'GPS Running Fluid Compensation',
            detail: isEnabled
                ? '${runKm.toStringAsFixed(1)}km logged today (+350ml / 5km)'
                : 'Disabled in manual mode',
            value: isEnabled ? '+$runBonus ml' : '0 ml',
            colorScheme: colorScheme,
            accentColor: colorScheme.primary,
          ),
          const Divider(height: 16),
          _buildBreakdownRow(
            icon: Icons.thermostat_rounded,
            label: 'Smart-Ring Thermal Sweat Demand',
            detail: isEnabled
                ? '${skinTemp >= 0 ? '+' : ''}${skinTemp.toStringAsFixed(1)}°C skin temperature delta'
                : 'Disabled in manual mode',
            value: isEnabled ? '+$tempBonus ml' : '0 ml',
            colorScheme: colorScheme,
            accentColor: colorScheme.error,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required IconData icon,
    required String label,
    required String detail,
    required String value,
    required ColorScheme colorScheme,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: accentColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBaselineSliderCard({
    required int baseTarget,
    required ValueChanged<double> onChanged,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Baseline Hydration Target',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '$baseTarget ml',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          Slider(
            key: const ValueKey('slider_baseline_water'),
            value: baseTarget.toDouble().clamp(1500.0, 4500.0),
            min: 1500.0,
            max: 4500.0,
            divisions: 30,
            activeColor: colorScheme.secondary,
            inactiveColor: colorScheme.surfaceContainerHighest,
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1500 ml',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '2500 ml (Standard)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.secondary,
                ),
              ),
              Text(
                '4500 ml',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalGuidanceCard({
    required String summary,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: colorScheme.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biomechanical Hydration Protocol',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  summary,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
