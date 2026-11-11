import 'package:flash_light_pro/features/lighting/domain/light_mode.dart';
import 'package:flash_light_pro/features/lighting/domain/lighting_defaults.dart';
import 'package:flash_light_pro/features/morse/domain/morse_codec.dart';
import 'package:flash_light_pro/src/bloc/flash_light/flash_light_bloc.dart';
import 'package:flash_light_pro/core/config/app_theme_config.dart';
import 'package:flash_light_pro/src/presentation/utils/localization.dart';
import 'package:flash_light_pro/src/presentation/widgets/color_preset_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ModeDetails extends StatelessWidget {
  const ModeDetails({
    super.key,
    required this.state,
    required this.morseController,
    required this.onPlayMorse,
  });

  final FlashLightState state;
  final TextEditingController morseController;
  final VoidCallback onPlayMorse;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: switch (state.selectedMode) {
        LightMode.torch => _TorchPanel(state: state),
        LightMode.screenLight => _ScreenPanel(state: state),
        LightMode.sos => _SosPanel(state: state),
        LightMode.strobe => _StrobePanel(state: state),
        LightMode.morse => _MorsePanel(
          state: state,
          controller: morseController,
          onPlay: onPlayMorse,
        ),
      },
    );
  }
}

class _TorchPanel extends StatelessWidget {
  const _TorchPanel({required this.state});

  final FlashLightState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            icon: Icons.flashlight_on_rounded,
            title: l10n.flashlight,
            subtitle: state.isAvailable
                ? l10n.rearCameraTorch
                : l10n.noUsableTorch,
          ),
          if (state.isAvailable) ...[
            const SizedBox(height: 16),
            if (state.isTorchLevelSupported)
              _LabeledSlider(
                sliderKey: const Key('torch-strength-slider'),
                label: l10n.torchStrength,
                valueLabel: localizedPercent(context, state.torchLevel),
                value: state.torchLevel,
                min: 0.05,
                max: 1,
                onChanged: (value) =>
                    context.read<FlashLightBloc>().add(SetTorchLevel(value)),
              )
            else
              _HintLine(
                icon: Icons.info_outline_rounded,
                text: l10n.torchStrengthUnsupported,
              ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _HintLine(
                icon: Icons.lightbulb_outline_rounded,
                text: l10n.screenLightWorksWithoutTorch,
              ),
            ),
        ],
      ),
    );
  }
}

class _ScreenPanel extends StatelessWidget {
  const _ScreenPanel({required this.state});

  final FlashLightState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            icon: Icons.light_mode_rounded,
            title: l10n.screenLight,
            subtitle: l10n.screenPanelSubtitle,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.color,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          ColorPresetRow(
            selectedValue: state.screenColorValue,
            onSelected: (value) =>
                context.read<FlashLightBloc>().add(SetScreenLightColor(value)),
          ),
          const SizedBox(height: 14),
          _LabeledSlider(
            sliderKey: const Key('screen-brightness-slider'),
            label: l10n.brightness,
            valueLabel: localizedPercent(context, state.screenBrightness),
            value: state.screenBrightness,
            min: LightingDefaults.minScreenBrightness,
            max: LightingDefaults.maxScreenBrightness,
            onChanged: (value) =>
                context.read<FlashLightBloc>().add(SetScreenBrightness(value)),
          ),
          const SizedBox(height: 4),
          _HintLine(icon: Icons.restore_rounded, text: l10n.brightnessRestored),
        ],
      ),
    );
  }
}

class _SosPanel extends StatelessWidget {
  const _SosPanel({required this.state});

  final FlashLightState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isActive = state.activeLight == LightMode.sos;

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            icon: Icons.sos_rounded,
            title: l10n.sosSignal,
            subtitle: l10n.sosSubtitle,
          ),
          const SizedBox(height: 16),
          Container(
            key: const Key('sos-pattern'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.27),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '... --- ...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 26,
                letterSpacing: 5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isActive
                ? l10n.sosTransmitting
                : state.isAvailable
                ? l10n.sosPlaysOnTorch
                : l10n.sosNeedsTorch,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _StrobePanel extends StatelessWidget {
  const _StrobePanel({required this.state});

  final FlashLightState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final frequency = LightingDefaults.strobeFrequencyHz(
      state.strobeIntervalMs,
    );

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            icon: Icons.bolt_rounded,
            title: l10n.strobe,
            subtitle: l10n.strobeSubtitle,
          ),
          const SizedBox(height: 16),
          _LabeledSlider(
            sliderKey: const Key('strobe-speed-slider'),
            label: l10n.flashSpeed,
            valueLabel: l10n.speedHz(
              localizedDecimal(context, frequency, decimals: 1),
            ),
            value: state.strobeIntervalMs.toDouble(),
            min: LightingDefaults.minStrobeIntervalMs.toDouble(),
            max: LightingDefaults.maxStrobeIntervalMs.toDouble(),
            divisions: 16,
            onChanged: (value) => context.read<FlashLightBloc>().add(
              SetStrobeInterval(value.round()),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            key: const Key('strobe-warning'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.photosensitivityWarning,
                    style: const TextStyle(fontSize: 12.5, height: 1.35),
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

class _MorsePanel extends StatelessWidget {
  const _MorsePanel({
    required this.state,
    required this.controller,
    required this.onPlay,
  });

  final FlashLightState state;
  final TextEditingController controller;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final active = state.activeLight == LightMode.morse;
    final result = MorseCodec.encode(controller.text);
    final bloc = context.read<FlashLightBloc>();

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            icon: Icons.graphic_eq_rounded,
            title: l10n.morseTitle,
            subtitle: l10n.morseSubtitle,
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('morse-input'),
            controller: controller,
            enabled: !active,
            maxLength: 60,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.message,
              hintText: l10n.morseHint,
              isDense: true,
              counterText: '',
              border: const OutlineInputBorder(),
              suffixIcon: controller.text.isEmpty || active
                  ? null
                  : IconButton(
                      key: const Key('morse-clear'),
                      tooltip: l10n.clearMessage,
                      onPressed: controller.clear,
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.27),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              result.hasContent ? result.morse : l10n.morsePreviewPlaceholder,
              key: const Key('morse-preview'),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                letterSpacing: 1.2,
                height: 1.5,
                color: result.hasContent
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ),
          ),
          if (result.unsupported.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.morseUnsupported(result.unsupported.join(' ')),
              key: const Key('morse-unsupported'),
              style: const TextStyle(color: AppColors.danger, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            state.isAvailable
                ? l10n.morsePlaysOnTorch
                : l10n.morseScreenFallback,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          if (active)
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  key: Key(
                    state.sequencePaused ? 'morse-resume' : 'morse-pause',
                  ),
                  onPressed: () => bloc.add(
                    state.sequencePaused
                        ? const ResumeSequence()
                        : const PauseSequence(),
                  ),
                  icon: Icon(
                    state.sequencePaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                  ),
                  label: Text(state.sequencePaused ? l10n.resume : l10n.pause),
                ),
                OutlinedButton.icon(
                  key: const Key('morse-stop'),
                  onPressed: () => bloc.add(const StopActiveLight()),
                  icon: const Icon(Icons.stop_rounded),
                  label: Text(l10n.stop),
                ),
              ],
            )
          else
            FilledButton.icon(
              key: const Key('morse-play'),
              onPressed: result.isPlayable ? onPlay : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.playMorse),
            ),
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: child,
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: AppColors.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.sliderKey,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final Key sliderKey;
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const Spacer(),
            Text(
              valueLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        Slider(
          key: sliderKey,
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _HintLine extends StatelessWidget {
  const _HintLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
