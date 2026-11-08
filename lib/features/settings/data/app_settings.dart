import 'package:equatable/equatable.dart';

import '../../lighting/domain/light_mode.dart';
import '../../lighting/domain/lighting_defaults.dart';
import '../../shake/domain/shake_sensitivity.dart';
import '../domain/app_language.dart';

class AppSettings extends Equatable {
  const AppSettings({
    this.selectedMode = LightMode.torch,
    this.screenColorValue = LightingDefaults.screenColorValue,
    this.screenBrightness = LightingDefaults.screenBrightness,
    this.torchLevel = LightingDefaults.torchLevel,
    this.strobeIntervalMs = LightingDefaults.strobeIntervalMs,
    this.timerPresetMinutes,
    this.appLanguage = AppLanguage.english,
    this.hapticsEnabled = true,
    this.shakeEnabled = false,
    this.shakeSensitivity = ShakeSensitivity.medium,
    this.keepScreenAwake = true,
    this.reduceAnimations = false,
    this.backgroundTorchEnabled = true,
  });

  final LightMode selectedMode;
  final int screenColorValue;
  final double screenBrightness;
  final double torchLevel;
  final int strobeIntervalMs;
  final int? timerPresetMinutes;

  final AppLanguage appLanguage;
  final bool hapticsEnabled;
  final bool shakeEnabled;
  final ShakeSensitivity shakeSensitivity;
  final bool keepScreenAwake;
  final bool reduceAnimations;
  final bool backgroundTorchEnabled;

  AppSettings copyWith({
    LightMode? selectedMode,
    int? screenColorValue,
    double? screenBrightness,
    double? torchLevel,
    int? strobeIntervalMs,
    int? timerPresetMinutes,
    AppLanguage? appLanguage,
    bool? hapticsEnabled,
    bool? shakeEnabled,
    ShakeSensitivity? shakeSensitivity,
    bool? keepScreenAwake,
    bool? reduceAnimations,
    bool? backgroundTorchEnabled,
  }) {
    return AppSettings(
      selectedMode: selectedMode ?? this.selectedMode,
      screenColorValue: screenColorValue ?? this.screenColorValue,
      screenBrightness: screenBrightness ?? this.screenBrightness,
      torchLevel: torchLevel ?? this.torchLevel,
      strobeIntervalMs: strobeIntervalMs ?? this.strobeIntervalMs,
      timerPresetMinutes: timerPresetMinutes ?? this.timerPresetMinutes,
      appLanguage: appLanguage ?? this.appLanguage,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      shakeEnabled: shakeEnabled ?? this.shakeEnabled,
      shakeSensitivity: shakeSensitivity ?? this.shakeSensitivity,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      backgroundTorchEnabled:
          backgroundTorchEnabled ?? this.backgroundTorchEnabled,
    );
  }

  @override
  List<Object?> get props => [
    selectedMode,
    screenColorValue,
    screenBrightness,
    torchLevel,
    strobeIntervalMs,
    timerPresetMinutes,
    appLanguage,
    hapticsEnabled,
    shakeEnabled,
    shakeSensitivity,
    keepScreenAwake,
    reduceAnimations,
    backgroundTorchEnabled,
  ];
}
