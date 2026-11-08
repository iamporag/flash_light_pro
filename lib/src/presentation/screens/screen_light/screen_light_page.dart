import 'package:flash_light_pro/features/lighting/domain/light_mode.dart';
import 'package:flash_light_pro/features/lighting/domain/lighting_defaults.dart';
import 'package:flash_light_pro/src/bloc/flash_light/flash_light_bloc.dart';
import 'package:flash_light_pro/src/presentation/screens/home/widgets/timer_sheet.dart';
import 'package:flash_light_pro/src/presentation/theme/app_theme.dart';
import 'package:flash_light_pro/src/presentation/utils/localization.dart';
import 'package:flash_light_pro/src/presentation/widgets/color_preset_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScreenLightPage extends StatefulWidget {
  const ScreenLightPage({super.key});

  @override
  State<ScreenLightPage> createState() => _ScreenLightPageState();
}

class _ScreenLightPageState extends State<ScreenLightPage> {
  bool _showCustomColor = false;
  bool _popped = false;

  void _closeIfInactive(FlashLightState state) {
    if (state.activeLight == LightMode.screenLight || _popped) return;
    _popped = true;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _stop() {
    context.read<FlashLightBloc>().add(const StopActiveLight());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlashLightBloc, FlashLightState>(
      listenWhen: (previous, current) =>
          previous.activeLight != current.activeLight,
      listener: (context, state) => _closeIfInactive(state),
      builder: (context, state) {
        final l10n = context.l10n;
        final color = Color(state.screenColorValue);
        final surfaceBrightness = ThemeData.estimateBrightnessForColor(color);
        final onColor = surfaceBrightness == Brightness.dark
            ? Colors.white
            : Colors.black87;

        return PopScope(
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) _stop();
          },
          child: Scaffold(
            backgroundColor: color,
            body: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: color)),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _GlassButton(
                              buttonKey: const Key('screen-light-exit'),
                              tooltip: l10n.exitScreenLight,
                              onColor: onColor,
                              icon: Icons.close_rounded,
                              onPressed: _stop,
                            ),
                            const Spacer(),
                            _TimerPill(
                              remaining: state.timerSecondsRemaining,
                              presetMinutes: state.timerPresetMinutes,
                              onPressed: () => showAutoOffTimerSheet(context),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.light_mode_rounded,
                                      size: 18,
                                      color: AppColors.accent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.screenLight,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Text(
                                      l10n.brightness,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      localizedPercent(
                                        context,
                                        state.screenBrightness,
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  key: const Key('screen-brightness-slider'),
                                  value: state.screenBrightness.clamp(
                                    LightingDefaults.minScreenBrightness,
                                    LightingDefaults.maxScreenBrightness,
                                  ),
                                  min: LightingDefaults.minScreenBrightness,
                                  max: LightingDefaults.maxScreenBrightness,
                                  onChanged: (value) => context
                                      .read<FlashLightBloc>()
                                      .add(SetScreenBrightness(value)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.color,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ColorPresetRow(
                                  selectedValue: state.screenColorValue,
                                  onSelected: (value) => context
                                      .read<FlashLightBloc>()
                                      .add(SetScreenLightColor(value)),
                                ),
                                const SizedBox(height: 10),
                                TextButton.icon(
                                  key: const Key('screen-custom-toggle'),
                                  onPressed: () => setState(
                                    () => _showCustomColor = !_showCustomColor,
                                  ),
                                  icon: Icon(
                                    _showCustomColor
                                        ? Icons.expand_less_rounded
                                        : Icons.palette_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _showCustomColor
                                        ? l10n.hideCustomColor
                                        : l10n.customColor,
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.accent,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                                if (_showCustomColor) ...[
                                  const SizedBox(height: 4),
                                  _CustomColorControls(
                                    value: state.screenColorValue,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    key: const Key('screen-light-off'),
                                    onPressed: _stop,
                                    icon: const Icon(
                                      Icons.power_settings_new_rounded,
                                    ),
                                    label: Text(l10n.turnOffLight),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CustomColorControls extends StatelessWidget {
  const _CustomColorControls({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hsv = HSVColor.fromColor(Color(value));

    void apply(HSVColor next) {
      context.read<FlashLightBloc>().add(
        SetScreenLightColor(next.toColor().toARGB32()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.hue,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const Spacer(),
            Text(
              '${localizedNumber(context, hsv.hue.round())}°',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        Slider(
          key: const Key('screen-hue-slider'),
          value: hsv.hue.clamp(0, 360),
          min: 0,
          max: 360,
          onChanged: (hue) => apply(
            HSVColor.fromAHSV(
              1,
              hue,
              hsv.saturation < 0.1 ? 0.45 : hsv.saturation,
              1,
            ),
          ),
        ),
        Row(
          children: [
            Text(
              l10n.saturation,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const Spacer(),
            Text(
              localizedPercent(context, hsv.saturation),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        Slider(
          key: const Key('screen-saturation-slider'),
          value: hsv.saturation.clamp(0, 1),
          min: 0,
          max: 1,
          onChanged: (saturation) =>
              apply(HSVColor.fromAHSV(1, hsv.hue, saturation, 1)),
        ),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.buttonKey,
    required this.tooltip,
    required this.onColor,
    required this.icon,
    required this.onPressed,
  });

  final Key buttonKey;
  final String tooltip;
  final Color onColor;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: buttonKey,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      color: onColor,
      style: IconButton.styleFrom(
        backgroundColor: onColor.withValues(alpha: 0.14),
        minimumSize: const Size(48, 48),
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  const _TimerPill({
    required this.remaining,
    required this.presetMinutes,
    required this.onPressed,
  });

  final int? remaining;
  final int? presetMinutes;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = remaining != null
        ? l10n.timerCountdown(formatCountdown(context, remaining!))
        : presetMinutes != null
        ? l10n.timerPreset(presetMinutes!)
        : l10n.timerOff;

    return TextButton.icon(
      key: const Key('screen-light-timer'),
      onPressed: onPressed,
      icon: const Icon(Icons.timer_outlined, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black.withValues(alpha: 0.32),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}
