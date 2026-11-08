import 'package:shared_preferences/shared_preferences.dart';

import '../../lighting/domain/light_mode.dart';
import '../../lighting/domain/lighting_defaults.dart';
import '../../shake/domain/shake_sensitivity.dart';
import '../domain/app_language.dart';
import 'app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}

/// Used when persistence is not wired (unit tests and previews).
class NoopSettingsRepository implements SettingsRepository {
  const NoopSettingsRepository();

  @override
  Future<AppSettings> load() async => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async {}
}

class SharedPreferencesSettingsRepository implements SettingsRepository {
  const SharedPreferencesSettingsRepository();

  static const String _modeKey = 'settings.selected_mode';
  static const String _colorKey = 'settings.screen_color';
  static const String _screenBrightnessKey = 'settings.screen_brightness';
  static const String _torchLevelKey = 'settings.torch_level';
  static const String _strobeIntervalKey = 'settings.strobe_interval_ms';
  static const String _timerPresetKey = 'settings.timer_preset_minutes';
  static const String _languageKey = 'settings.language';
  static const String _hapticsKey = 'settings.haptics';
  static const String _shakeEnabledKey = 'settings.shake_enabled';
  static const String _shakeSensitivityKey = 'settings.shake_sensitivity';
  static const String _keepScreenAwakeKey = 'settings.keep_screen_awake';
  static const String _reduceAnimationsKey = 'settings.reduce_animations';
  static const String _backgroundTorchKey = 'settings.background_torch';

  @override
  Future<AppSettings> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final modeIndex = _readInt(preferences, _modeKey);
      final mode =
          modeIndex != null &&
              modeIndex >= 0 &&
              modeIndex < LightMode.values.length
          ? LightMode.values[modeIndex]
          : LightMode.torch;

      return AppSettings(
        selectedMode: mode,
        screenColorValue: LightingDefaults.opaqueColor(
          _readInt(preferences, _colorKey) ?? LightingDefaults.screenColorValue,
        ),
        screenBrightness: LightingDefaults.clampBrightness(
          _readDouble(preferences, _screenBrightnessKey) ??
              LightingDefaults.screenBrightness,
        ),
        torchLevel: LightingDefaults.clampTorchLevel(
          _readDouble(preferences, _torchLevelKey) ??
              LightingDefaults.torchLevel,
        ),
        strobeIntervalMs: LightingDefaults.clampStrobeInterval(
          _readInt(preferences, _strobeIntervalKey) ??
              LightingDefaults.strobeIntervalMs,
        ),
        timerPresetMinutes: _readTimerPreset(preferences),
        appLanguage: AppLanguage.fromIndex(_readInt(preferences, _languageKey)),
        hapticsEnabled: _readBool(preferences, _hapticsKey) ?? true,
        shakeEnabled: _readBool(preferences, _shakeEnabledKey) ?? false,
        shakeSensitivity: ShakeSensitivity.fromIndex(
          _readInt(preferences, _shakeSensitivityKey),
        ),
        keepScreenAwake: _readBool(preferences, _keepScreenAwakeKey) ?? true,
        reduceAnimations: _readBool(preferences, _reduceAnimationsKey) ?? false,
        backgroundTorchEnabled:
            _readBool(preferences, _backgroundTorchKey) ?? true,
      );
    } catch (_) {
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings settings) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt(_modeKey, settings.selectedMode.index);
      await preferences.setInt(_colorKey, settings.screenColorValue);
      await preferences.setDouble(
        _screenBrightnessKey,
        settings.screenBrightness,
      );
      await preferences.setDouble(_torchLevelKey, settings.torchLevel);
      await preferences.setInt(_strobeIntervalKey, settings.strobeIntervalMs);
      await preferences.setInt(_languageKey, settings.appLanguage.index);
      await preferences.setBool(_hapticsKey, settings.hapticsEnabled);
      await preferences.setBool(_shakeEnabledKey, settings.shakeEnabled);
      await preferences.setInt(
        _shakeSensitivityKey,
        settings.shakeSensitivity.index,
      );
      await preferences.setBool(_keepScreenAwakeKey, settings.keepScreenAwake);
      await preferences.setBool(
        _reduceAnimationsKey,
        settings.reduceAnimations,
      );
      await preferences.setBool(
        _backgroundTorchKey,
        settings.backgroundTorchEnabled,
      );

      final preset = settings.timerPresetMinutes;
      if (preset == null) {
        await preferences.remove(_timerPresetKey);
      } else {
        await preferences.setInt(_timerPresetKey, preset);
      }
    } catch (_) {
      // Persistence is best effort; preferences must never break the UI.
    }
  }

  int? _readInt(SharedPreferences preferences, String key) {
    try {
      return preferences.getInt(key);
    } catch (_) {
      return null;
    }
  }

  double? _readDouble(SharedPreferences preferences, String key) {
    try {
      return preferences.getDouble(key);
    } catch (_) {
      return null;
    }
  }

  bool? _readBool(SharedPreferences preferences, String key) {
    try {
      return preferences.getBool(key);
    } catch (_) {
      return null;
    }
  }

  int? _readTimerPreset(SharedPreferences preferences) {
    final value = _readInt(preferences, _timerPresetKey);
    if (value == null || value <= 0) return null;
    return value.clamp(1, LightingDefaults.maxCustomTimerMinutes);
  }
}
