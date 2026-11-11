import 'package:flash_light_pro/core/config/app_theme_config.dart';
import 'package:flutter/material.dart';

class PowerButton extends StatelessWidget {
  const PowerButton({
    super.key,
    required this.isOn,
    required this.isBusy,
    required this.enabled,
    required this.label,
    required this.hint,
    required this.onPressed,
    required this.size,
    this.animate = true,
  });

  final bool isOn;
  final bool isBusy;
  final bool enabled;
  final String label;
  final String hint;
  final VoidCallback onPressed;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final duration = animate
        ? const Duration(milliseconds: 420)
        : Duration.zero;
    final coreSize = size * 0.64;
    final canPress = enabled && !isBusy;

    return Semantics(
      button: true,
      enabled: canPress,
      toggled: isOn,
      label: label,
      hint: hint,
      onTap: canPress ? onPressed : null,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        child: InkWell(
          key: const Key('power-button'),
          customBorder: const CircleBorder(),
          onTap: canPress ? onPressed : null,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isOn
                    ? [
                        AppColors.accent.withValues(alpha: 0.42),
                        AppColors.accent.withValues(alpha: 0.05),
                      ]
                    : [AppColors.surfaceHigh, AppColors.surface],
              ),
              border: Border.all(
                color: isOn
                    ? AppColors.accent
                    : enabled
                    ? AppColors.track
                    : AppColors.surfaceBorder,
                width: isOn ? 2 : 1.5,
              ),
              boxShadow: isOn
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.38),
                        blurRadius: 46,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                width: coreSize,
                height: coreSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOn
                      ? AppColors.accent
                      : enabled
                      ? AppColors.surfaceHigh
                      : AppColors.surface,
                ),
                child: Center(
                  child: isBusy
                      ? SizedBox(
                          width: coreSize * 0.34,
                          height: coreSize * 0.34,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: isOn
                                ? const Color(0xFF231A02)
                                : AppColors.accent,
                          ),
                        )
                      : Icon(
                          Icons.power_settings_new_rounded,
                          size: size * 0.25,
                          color: isOn
                              ? const Color(0xFF231A02)
                              : enabled
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
