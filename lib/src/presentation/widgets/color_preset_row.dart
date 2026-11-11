import 'package:flash_light_pro/core/config/app_theme_config.dart';
import 'package:flash_light_pro/src/presentation/utils/localization.dart';
import 'package:flutter/material.dart';

class ScreenColorPreset {
  const ScreenColorPreset({
    required this.id,
    required this.value,
    required this.color,
  });

  final String id;
  final int value;
  final Color color;
}

const List<ScreenColorPreset> screenColorPresets = [
  ScreenColorPreset(id: 'warm', value: 0xFFFFD9A0, color: AppColors.warm),
  ScreenColorPreset(id: 'neutral', value: 0xFFFFFFFF, color: AppColors.neutral),
  ScreenColorPreset(id: 'cool', value: 0xFFCCE4FF, color: AppColors.cool),
];

String _presetLabel(BuildContext context, ScreenColorPreset preset) {
  final l10n = context.l10n;
  return switch (preset.id) {
    'warm' => l10n.screenColorWarm,
    'cool' => l10n.screenColorCool,
    _ => l10n.screenColorNeutral,
  };
}

class ColorPresetRow extends StatelessWidget {
  const ColorPresetRow({
    super.key,
    required this.selectedValue,
    required this.onSelected,
  });

  final int selectedValue;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final preset in screenColorPresets)
          _PresetSwatch(
            preset: preset,
            selected: preset.value == selectedValue,
            onTap: () => onSelected(preset.value),
          ),
      ],
    );
  }
}

class _PresetSwatch extends StatelessWidget {
  const _PresetSwatch({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final ScreenColorPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final checkColor =
        ThemeData.estimateBrightnessForColor(preset.color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final label = _presetLabel(context, preset);

    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.screenColorSemantics(label),
      child: Tooltip(
        message: label,
        child: InkWell(
          key: Key('screen-color-${preset.id}'),
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: preset.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.track,
                width: selected ? 3 : 1,
              ),
            ),
            child: selected
                ? Icon(Icons.check_rounded, size: 22, color: checkColor)
                : null,
          ),
        ),
      ),
    );
  }
}
