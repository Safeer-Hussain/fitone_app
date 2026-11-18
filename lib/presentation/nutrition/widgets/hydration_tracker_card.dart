import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../core/utils/app_feedback.dart';
import '../stores/nutrition_store.dart';
import 'water_adjustment_sheet.dart';

class HydrationTrackerCard extends StatelessWidget {
  final NutritionStore store;
  final bool isCompact;

  const HydrationTrackerCard({
    super.key,
    required this.store,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final summary = store.dailySummary;
        final adjustment = store.waterAdjustment;
        final consumedMl = summary?.consumedWaterMl ?? 0;
        final targetMl = summary?.targetWaterMl ?? adjustment.adjustedTargetMl;
        final progress = summary?.waterProgress ?? adjustment.progress;
        final streak = store.waterStreakDays;

        return Card(
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.water_drop_rounded,
                            size: isCompact ? 14 : 16,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'HYDRATION ENGINE',
                              style: TextStyle(
                                fontSize: isCompact ? 10 : 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          key: const ValueKey('chip_adaptive_hydration_engine'),
                          borderRadius: BorderRadius.circular(8),
                          onTap: () =>
                              WaterAdjustmentSheet.show(context, store: store),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 5 : 7,
                              vertical: isCompact ? 2 : 3,
                            ),
                            decoration: BoxDecoration(
                              color: adjustment.hasActiveAdjustment
                                  ? colorScheme.secondary.withValues(
                                      alpha: 0.18,
                                    )
                                  : colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: adjustment.hasActiveAdjustment
                                    ? colorScheme.secondary
                                    : colorScheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: isCompact ? 10 : 12,
                                  color: adjustment.hasActiveAdjustment
                                      ? colorScheme.secondary
                                      : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  adjustment.hasActiveAdjustment
                                      ? '+${adjustment.totalAdjustmentMl}ml Auto'
                                      : 'Adaptive',
                                  style: TextStyle(
                                    fontSize: isCompact ? 9 : 11,
                                    fontWeight: FontWeight.w700,
                                    color: adjustment.hasActiveAdjustment
                                        ? colorScheme.secondary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 5 : 7,
                            vertical: isCompact ? 2 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.secondary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            '$streak Day Streak',
                            style: TextStyle(
                              color: colorScheme.secondary,
                              fontSize: isCompact ? 9 : 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 8 : 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$consumedMl ml',
                          style: TextStyle(
                            fontSize: isCompact ? 18 : 24,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Target $targetMl ml per day',
                          style: TextStyle(
                            fontSize: isCompact ? 10 : 12,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (adjustment.hasActiveAdjustment) ...[
                          const SizedBox(height: 2),
                          InkWell(
                            onTap: () => WaterAdjustmentSheet.show(
                              context,
                              store: store,
                            ),
                            child: Text(
                              'Base ${adjustment.baseTargetMl}ml • +${adjustment.runningAdjustmentMl}ml Run • +${adjustment.thermalAdjustmentMl}ml Temp',
                              style: TextStyle(
                                fontSize: isCompact ? 9 : 10,
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: isCompact ? 16 : 20,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isCompact ? 8 : 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: isCompact ? 6 : 10,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(colorScheme.secondary),
                  ),
                ),
                SizedBox(height: isCompact ? 10 : 18),
                Row(
                  children: [
                    _WaterButton(
                      label: '+250ml',
                      onTap: () {
                        store.logWater(250);
                        AppFeedback.showSuccess(
                          context,
                          'Logged 250ml water (+0.25L)',
                        );
                      },
                      colorScheme: colorScheme,
                      isCompact: isCompact,
                    ),
                    const SizedBox(width: 6),
                    _WaterButton(
                      label: '+500ml',
                      onTap: () {
                        store.logWater(500);
                        AppFeedback.showSuccess(
                          context,
                          'Logged 500ml water (+0.50L)',
                        );
                      },
                      colorScheme: colorScheme,
                      isCompact: isCompact,
                    ),
                    const SizedBox(width: 6),
                    _WaterButton(
                      label: '+750ml',
                      onTap: () {
                        store.logWater(750);
                        AppFeedback.showSuccess(
                          context,
                          'Logged 750ml water (+0.75L)',
                        );
                      },
                      colorScheme: colorScheme,
                      isCompact: isCompact,
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () {
                        store.resetHydration();
                        AppFeedback.showInfo(
                          context,
                          'Hydration reset to 0ml for today',
                        );
                      },
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: isCompact ? 16 : 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Reset Day Hydration',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      key: const ValueKey('btn_open_water_adjustment_sheet'),
                      onPressed: () =>
                          WaterAdjustmentSheet.show(context, store: store),
                      icon: Icon(
                        Icons.tune_rounded,
                        size: isCompact ? 16 : 18,
                        color: colorScheme.secondary,
                      ),
                      tooltip: 'Configure Adaptive Hydration',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WaterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isCompact;

  const _WaterButton({
    required this.label,
    required this.onTap,
    required this.colorScheme,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outlineVariant),
          padding: EdgeInsets.symmetric(vertical: isCompact ? 4 : 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 10 : 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
