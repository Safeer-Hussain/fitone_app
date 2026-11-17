import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/cadence_metronome.dart';
import '../stores/gps_running_store.dart';

class CadenceMetronomeSheet extends StatelessWidget {
  final GpsRunningStore store;

  const CadenceMetronomeSheet({super.key, required this.store});

  static void show(BuildContext context, {required GpsRunningStore store}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CadenceMetronomeSheet(store: store),
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
        final isEnabled = store.isMetronomeEnabled;
        final spm = store.cadenceSpm;
        final audio = store.metronomeAudioEnabled;
        final haptic = store.metronomeHapticEnabled;
        final currentBeat = store.metronomeBeat;
        final isFlash = store.isBeatFlash;
        final config = store.metronomeConfig;

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
                          Icons.speed_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Audio & Visual Cadence Metronome',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Rhythmic Stride Pacer (160 - 190 SPM)',
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
                          _buildVisualizerCard(
                            spm: spm,
                            isEnabled: isEnabled,
                            currentBeat: currentBeat,
                            isFlash: isFlash,
                            config: config,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 12),
                          _buildPresetChips(
                            selectedSpm: spm,
                            onSelected: (val) {
                              store.setCadenceSpm(val);
                              AppFeedback.showInfo(
                                context,
                                'Target cadence set to $val SPM',
                              );
                            },
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 12),
                          _buildSpmSliderCard(
                            spm: spm,
                            onChanged: (val) =>
                                store.setCadenceSpm(val.round()),
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 12),
                          _buildFeedbackSwitches(
                            audio: audio,
                            haptic: haptic,
                            onAudioChanged: store.toggleMetronomeAudio,
                            onHapticChanged: store.toggleMetronomeHaptic,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 12),
                          _buildImpactAnalysisCard(
                            config: config,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 16),
                          _buildMainActionButton(
                            isEnabled: isEnabled,
                            onTap: () {
                              store.toggleMetronome();
                              if (store.isMetronomeEnabled) {
                                AppFeedback.showSuccess(
                                  context,
                                  'Metronome started at $spm SPM',
                                );
                              } else {
                                AppFeedback.showInfo(
                                  context,
                                  'Metronome stopped',
                                );
                              }
                            },
                            colorScheme: colorScheme,
                          ),
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
      },
    );
  }

  Widget _buildVisualizerCard({
    required int spm,
    required bool isEnabled,
    required int currentBeat,
    required bool isFlash,
    required CadenceMetronomeConfig config,
    required ColorScheme colorScheme,
  }) {
    final intervalMs = config.intervalMs;
    final stepsPerSec = (spm / 60.0).toStringAsFixed(2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled && isFlash
              ? colorScheme.primary
              : colorScheme.outlineVariant,
          width: isEnabled && isFlash ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isCurrent = isEnabled && currentBeat == index;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 32,
                height: 10,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(5),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            '$spm',
            key: const ValueKey('cadence_spm_display_text'),
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: isEnabled ? colorScheme.primary : colorScheme.onSurface,
              letterSpacing: -1,
            ),
          ),
          Text(
            'STEPS PER MINUTE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
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
                  config.zoneLabel,
                  key: const ValueKey('cadence_zone_badge'),
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
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$intervalMs ms / stride • $stepsPerSec steps/s',
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

  Widget _buildPresetChips({
    required int selectedSpm,
    required ValueChanged<int> onSelected,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Cadence Presets',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: CadenceMetronomeConfig.standardPresets.map((preset) {
            final isSelected = preset == selectedSpm;
            return ChoiceChip(
              key: ValueKey('chip_spm_$preset'),
              label: Text('$preset SPM'),
              selected: isSelected,
              onSelected: (_) => onSelected(preset),
              selectedColor: colorScheme.primary,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpmSliderCard({
    required int spm,
    required ValueChanged<double> onChanged,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fine Cadence Adjustment',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '$spm SPM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            key: const ValueKey('cadence_spm_slider'),
            value: spm.toDouble().clamp(150.0, 200.0),
            min: 150.0,
            max: 200.0,
            divisions: 50,
            activeColor: colorScheme.primary,
            inactiveColor: colorScheme.surfaceContainerHighest,
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '150 SPM',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '175 SPM (Optimal)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                '200 SPM',
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

  Widget _buildFeedbackSwitches({
    required bool audio,
    required bool haptic,
    required VoidCallback onAudioChanged,
    required VoidCallback onHapticChanged,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.volume_up_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Audio Click Beat',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Switch(
                key: const ValueKey('switch_metronome_audio'),
                value: audio,
                onChanged: (_) => onAudioChanged(),
              ),
            ],
          ),
          Divider(height: 8, color: colorScheme.outlineVariant),
          Row(
            children: [
              Icon(
                Icons.vibration_rounded,
                size: 20,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Haptic Vibration Pulse',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Switch(
                key: const ValueKey('switch_metronome_haptic'),
                value: haptic,
                onChanged: (_) => onHapticChanged(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactAnalysisCard({
    required CadenceMetronomeConfig config,
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
          Icon(Icons.shield_outlined, size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Joint Impact Reduction',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  config.impactReductionSummary,
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

  Widget _buildMainActionButton({
    required bool isEnabled,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        key: const ValueKey('btn_toggle_metronome'),
        onPressed: onTap,
        icon: Icon(
          isEnabled ? Icons.stop_rounded : Icons.play_arrow_rounded,
          size: 20,
        ),
        label: Text(
          isEnabled ? 'Stop Cadence Metronome' : 'Start Cadence Metronome',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? colorScheme.error : colorScheme.primary,
          foregroundColor: isEnabled
              ? colorScheme.onError
              : colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
