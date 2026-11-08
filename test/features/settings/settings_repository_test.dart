import 'package:flash_light_pro/features/lighting/domain/light_mode.dart';
import 'package:flash_light_pro/features/lighting/domain/lighting_defaults.dart';
import 'package:flash_light_pro/features/settings/data/app_settings.dart';
import 'package:flash_light_pro/features/settings/data/settings_repository.dart';
import 'package:flash_light_pro/features/settings/domain/app_language.dart';
import 'package:flash_light_pro/features/shake/domain/shake_sensitivity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NoopSettingsRepository', () {
    test('returns defaults and ignores saves', () async {
      const repository = NoopSettingsRepository();

      expect(await repository.load(), const AppSettings());

      await repository.save(
        const AppSettings(selectedMode: LightMode.sos, timerPresetMinutes: 5),
      );

      expect(await repository.load(), const AppSettings());
    });
  });

  group('SharedPreferencesSettingsRepository', () {
    const repository = SharedPreferencesSettingsRepository();

    test('returns defaults when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});

      final settings = await repository.load();

      expect(settings, const AppSettings());
      expect(settings.selectedMode, LightMode.torch);
      expect(settings.screenColorValue, LightingDefaults.screenColorValue);
      expect(settings.screenBrightness, LightingDefaults.screenBrightness);
      expect(settings.timerPresetMinutes, isNull);
      expect(settings.appLanguage, AppLanguage.english);
      expect(settings.hapticsEnabled, isTrue);
      expect(settings.shakeEnabled, isFalse);
      expect(settings.shakeSensitivity, ShakeSensitivity.medium);
      expect(settings.keepScreenAwake, isTrue);
      expect(settings.reduceAnimations, isFalse);
      expect(settings.backgroundTorchEnabled, isTrue);
    });

    test('round-trips every value', () async {
      SharedPreferences.setMockInitialValues({});

      const original = AppSettings(
        selectedMode: LightMode.morse,
        screenColorValue: 0xFFFFD9A0,
        screenBrightness: 0.4,
        torchLevel: 0.3,
        strobeIntervalMs: 700,
        timerPresetMinutes: 15,
        appLanguage: AppLanguage.bengali,
        hapticsEnabled: false,
        shakeEnabled: true,
        shakeSensitivity: ShakeSensitivity.high,
        keepScreenAwake: false,
        reduceAnimations: true,
        backgroundTorchEnabled: true,
      );
      await repository.save(original);

      expect(await repository.load(), original);
    });

    test('invalid language index falls back to English', () async {
      SharedPreferences.setMockInitialValues({'settings.language': 42});

      expect((await repository.load()).appLanguage, AppLanguage.english);
    });

    test('invalid shake sensitivity index falls back to medium', () async {
      SharedPreferences.setMockInitialValues({
        'settings.shake_sensitivity': -3,
      });

      expect(
        (await repository.load()).shakeSensitivity,
        ShakeSensitivity.medium,
      );
    });

    test('clearing the timer preset removes the stored value', () async {
      SharedPreferences.setMockInitialValues({});

      await repository.save(const AppSettings(timerPresetMinutes: 30));
      expect((await repository.load()).timerPresetMinutes, 30);

      await repository.save(
        const AppSettings(selectedMode: LightMode.screenLight),
      );
      expect((await repository.load()).timerPresetMinutes, isNull);
    });

    test('invalid mode index falls back to torch', () async {
      SharedPreferences.setMockInitialValues({'settings.selected_mode': 99});

      expect((await repository.load()).selectedMode, LightMode.torch);
    });

    test('wrongly typed values fall back to defaults per key', () async {
      SharedPreferences.setMockInitialValues({
        'settings.selected_mode': 'strobe',
        'settings.screen_color': 1.5,
        'settings.screen_brightness': 'bright',
        'settings.torch_level': 3,
        'settings.strobe_interval_ms': 0.5,
        'settings.timer_preset_minutes': 'soon',
      });

      final settings = await repository.load();

      expect(settings, const AppSettings());
    });

    test('out-of-range values are clamped, not rejected', () async {
      SharedPreferences.setMockInitialValues({
        'settings.screen_color': 0x00112233,
        'settings.screen_brightness': 5.0,
        'settings.torch_level': -2.0,
        'settings.strobe_interval_ms': 5,
        'settings.timer_preset_minutes': 9999,
      });

      final settings = await repository.load();

      expect(settings.screenColorValue, 0xFF112233);
      expect(settings.screenBrightness, LightingDefaults.maxScreenBrightness);
      expect(settings.torchLevel, 0.0);
      expect(settings.strobeIntervalMs, LightingDefaults.minStrobeIntervalMs);
      expect(
        settings.timerPresetMinutes,
        LightingDefaults.maxCustomTimerMinutes,
      );
    });

    test('non-positive timer preset loads as no timer', () async {
      SharedPreferences.setMockInitialValues({
        'settings.timer_preset_minutes': -5,
      });

      expect((await repository.load()).timerPresetMinutes, isNull);
    });

    test('a corrupt store returns defaults instead of throwing', () async {
      SharedPreferences.setMockInitialValues({
        'settings.selected_mode': <String>['not', 'an', 'int'],
      });

      expect(await repository.load(), const AppSettings());
    });
  });
}
