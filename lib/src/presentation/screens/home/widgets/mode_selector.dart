import 'package:flash_light_pro/features/lighting/domain/light_mode.dart';
import 'package:flash_light_pro/src/presentation/theme/app_theme.dart';
import 'package:flash_light_pro/src/presentation/utils/light_mode_labels.dart';
import 'package:flash_light_pro/src/presentation/utils/localization.dart';
import 'package:flutter/material.dart';

class ModeSelector extends StatelessWidget {
  const ModeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final LightMode selected;
  final ValueChanged<LightMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          for (final mode in LightMode.values)
            Padding(
              padding: EdgeInsets.only(
                right: mode == LightMode.values.last ? 0 : 8,
              ),
              child: _ModeChip(
                mode: mode,
                selected: mode == selected,
                onTap: () => onSelected(mode),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final LightMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = modeChipLabel(mode, context.l10n);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('mode-${mode.name}'),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: duration,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.16)
                  : AppColors.surface.withValues(alpha: 0.72),
              border: Border.all(
                color: selected ? AppColors.accent : const Color(0x1FFFFFFF),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _icon,
                  size: 18,
                  color: selected ? AppColors.accent : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.accent : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch (mode) {
    LightMode.torch => Icons.flashlight_on_rounded,
    LightMode.screenLight => Icons.light_mode_rounded,
    LightMode.sos => Icons.sos_rounded,
    LightMode.strobe => Icons.bolt_rounded,
    LightMode.morse => Icons.graphic_eq_rounded,
  };
}
