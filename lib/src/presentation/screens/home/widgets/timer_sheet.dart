import 'package:flash_light_pro/features/lighting/domain/lighting_defaults.dart';
import 'package:flash_light_pro/src/bloc/flash_light/flash_light_bloc.dart';
import 'package:flash_light_pro/src/presentation/theme/app_theme.dart';
import 'package:flash_light_pro/src/presentation/utils/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showAutoOffTimerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => const AutoOffTimerSheet(),
  );
}

class AutoOffTimerSheet extends StatefulWidget {
  const AutoOffTimerSheet({super.key});

  @override
  State<AutoOffTimerSheet> createState() => _AutoOffTimerSheetState();
}

class _AutoOffTimerSheetState extends State<AutoOffTimerSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _customError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectPreset(int minutes) {
    context.read<FlashLightBloc>().add(SetAutoOffTimer(minutes));
    Navigator.of(context).pop();
  }

  void _applyCustom() {
    final minutes = int.tryParse(_controller.text.trim());
    if (minutes == null ||
        minutes < 1 ||
        minutes > LightingDefaults.maxCustomTimerMinutes) {
      setState(() {
        _customError = context.l10n.timerCustomError(
          LightingDefaults.maxCustomTimerMinutes,
        );
      });
      return;
    }

    context.read<FlashLightBloc>().add(SetAutoOffTimer(minutes));
    Navigator.of(context).pop();
  }

  void _cancelTimer() {
    context.read<FlashLightBloc>().add(const SetAutoOffTimer(null));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: BlocBuilder<FlashLightBloc, FlashLightState>(
        builder: (context, state) {
          final l10n = context.l10n;
          final remaining = state.timerSecondsRemaining;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.timerSheetTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.timerSheetSubtitle,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              if (remaining != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: AppColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.timerTurningOff(
                          formatCountdown(context, remaining),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final minutes in LightingDefaults.timerPresets)
                    ChoiceChip(
                      key: Key('timer-preset-$minutes'),
                      label: Text(l10n.timerPresetChip(minutes)),
                      selected: state.timerPresetMinutes == minutes,
                      onSelected: (_) => _selectPreset(minutes),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('timer-custom-input'),
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _applyCustom(),
                      decoration: InputDecoration(
                        labelText: l10n.timerCustomLabel,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    key: const Key('timer-custom-set'),
                    onPressed: _applyCustom,
                    child: Text(l10n.timerSet),
                  ),
                ],
              ),
              if (_customError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _customError!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (state.timerPresetMinutes != null) ...[
                    TextButton(
                      key: const Key('timer-cancel'),
                      onPressed: _cancelTimer,
                      child: Text(l10n.timerCancel),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.timerClose),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
