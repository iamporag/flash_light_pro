import 'package:fake_async/fake_async.dart';
import 'package:flash_light_pro/features/flashlight/services/torch_service.dart';
import 'package:flash_light_pro/features/lighting/domain/light_mode.dart';
import 'package:flash_light_pro/features/lighting/domain/lighting_defaults.dart';
import 'package:flash_light_pro/features/settings/data/app_settings.dart';
import 'package:flash_light_pro/src/bloc/flash_light/flash_light_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flashlight/fake_device_controls.dart';
import '../flashlight/fake_settings_repository.dart';
import '../flashlight/fake_torch_service.dart';

class _Harness {
  _Harness({
    FakeTorchService? service,
    FakeDeviceControls? controls,
    FakeSettingsRepository? settings,
  }) : service = service ?? FakeTorchService(),
       controls = controls ?? FakeDeviceControls(),
       settings = settings ?? FakeSettingsRepository() {
    bloc = FlashLightBloc(
      torchService: this.service,
      deviceControls: this.controls,
      settingsRepository: this.settings,
    );
  }

  final FakeTorchService service;
  final FakeDeviceControls controls;
  final FakeSettingsRepository settings;
  late final FlashLightBloc bloc;
}

void main() {
  group('settings loading', () {
    test('restores preferences without activating a light', () {
      fakeAsync((async) {
        final harness = _Harness(
          settings: FakeSettingsRepository(
            const AppSettings(
              selectedMode: LightMode.screenLight,
              screenColorValue: 0xFFFFD9A0,
              screenBrightness: 0.4,
              torchLevel: 0.5,
              strobeIntervalMs: 700,
              timerPresetMinutes: 5,
            ),
          ),
          controls: FakeDeviceControls()..levelSupported = true,
        );
        async.flushMicrotasks();

        final state = harness.bloc.state;
        expect(state.selectedMode, LightMode.screenLight);
        expect(state.screenColorValue, 0xFFFFD9A0);
        expect(state.screenBrightness, 0.4);
        expect(state.torchLevel, 0.5);
        expect(state.strobeIntervalMs, 700);
        expect(state.timerPresetMinutes, 5);
        expect(state.isTorchLevelSupported, isTrue);
        expect(state.isAvailable, isTrue);
        expect(state.activeLight, isNull);
        expect(state.timerSecondsRemaining, isNull);

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });

    test('persists mode, color, brightness, speed, and timer changes', () {
      fakeAsync((async) {
        final harness = _Harness();
        async.flushMicrotasks();

        harness.bloc.add(const SelectLightMode(LightMode.morse));
        async.flushMicrotasks();
        harness.bloc.add(const SetScreenLightColor(0xFF22CC88));
        async.flushMicrotasks();
        harness.bloc.add(const SetScreenBrightness(0.55));
        async.flushMicrotasks();
        harness.bloc.add(const SetStrobeInterval(900));
        async.flushMicrotasks();
        harness.bloc.add(const SetAutoOffTimer(15));
        async.flushMicrotasks();

        final saved = harness.settings.saved.last;
        expect(saved.selectedMode, LightMode.morse);
        expect(saved.screenColorValue, 0xFF22CC88);
        expect(saved.screenBrightness, 0.55);
        expect(saved.strobeIntervalMs, 900);
        expect(saved.timerPresetMinutes, 15);

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });
  });

  group('torch controls', () {
    test('applies torch strength and keeps the screen awake', () {
      fakeAsync((async) {
        final harness = _Harness(
          controls: FakeDeviceControls()..levelSupported = true,
        );
        async.flushMicrotasks();

        harness.bloc.add(const SetTorchLevel(0.35));
        async.flushMicrotasks();
        harness.bloc.add(const TurnOnFlashLight());
        async.flushMicrotasks();

        expect(harness.bloc.state.isTorchOn, isTrue);
        expect(harness.controls.setLevelCalls, 1);
        expect(harness.controls.lastLevel, 0.35);
        expect(harness.controls.lastKeepScreenOn, isTrue);

        harness.bloc.add(const SetTorchLevel(0.7));
        async.flushMicrotasks();
        expect(harness.controls.setLevelCalls, 2);
        expect(harness.controls.lastLevel, 0.7);

        harness.bloc.add(const TurnOffFlashLight());
        async.flushMicrotasks();

        expect(harness.bloc.state.isTorchOn, isFalse);
        expect(harness.controls.lastKeepScreenOn, isFalse);

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });

    test('does not call the strength channel when unsupported', () {
      fakeAsync((async) {
        final harness = _Harness(
          controls: FakeDeviceControls()..levelSupported = false,
        );
        async.flushMicrotasks();

        harness.bloc.add(const TurnOnFlashLight());
        async.flushMicrotasks();

        expect(harness.bloc.state.isTorchOn, isTrue);
        expect(harness.controls.setLevelCalls, 0);

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });
  });

  group('screen light', () {
    test('starts with saved color and brightness, then restores on stop', () {
      fakeAsync((async) {
        final harness = _Harness();
        async.flushMicrotasks();

        harness.bloc.add(const SetScreenBrightness(0.6));
        async.flushMicrotasks();
        harness.bloc.add(const StartScreenLight());
        async.flushMicrotasks();

        expect(harness.bloc.state.isScreenLightOn, isTrue);
        expect(harness.bloc.state.selectedMode, LightMode.screenLight);
        expect(harness.controls.lastKeepScreenOn, isTrue);
        expect(harness.controls.lastBrightness, 0.6);

        harness.bloc.add(const SetScreenBrightness(0.3));
        async.flushMicrotasks();
        expect(harness.controls.lastBrightness, 0.3);
        expect(harness.bloc.state.screenBrightness, 0.3);

        harness.bloc.add(const SetScreenLightColor(0x00ABCDEF));
        async.flushMicrotasks();
        expect(harness.bloc.state.screenColorValue, 0xFFABCDEF);

        harness.bloc.add(const StopActiveLight());
        async.flushMicrotasks();

        expect(harness.bloc.state.isScreenLightOn, isFalse);
        expect(harness.controls.restoreCalls, 1);
        expect(harness.controls.lastKeepScreenOn, isFalse);

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });

    test('switching to torch stops screen light first', () {
      fakeAsync((async) {
        final harness = _Harness();
        async.flushMicrotasks();

        harness.bloc.add(const StartScreenLight());
        async.flushMicrotasks();
        harness.bloc.add(const SelectLightMode(LightMode.torch));
        async.flushMicrotasks();

        expect(harness.bloc.state.activeLight, isNull);
        expect(harness.bloc.state.selectedMode, LightMode.torch);
        expect(harness.controls.restoreCalls, 1);
        expect(harness.controls.lastKeepScreenOn, isFalse);

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });
  });

  group('SOS and strobe', () {
    test(
      'SOS starts, toggles the torch, and stops without stale callbacks',
      () {
        fakeAsync((async) {
          final harness = _Harness();
          async.flushMicrotasks();

          harness.bloc.add(const StartSos());
          async.flushMicrotasks();

          expect(harness.bloc.state.activeLight, LightMode.sos);
          expect(harness.bloc.state.selectedMode, LightMode.sos);
          expect(harness.controls.lastKeepScreenOn, isTrue);
          expect(harness.service.enableCalls, 1);

          async.elapse(const Duration(milliseconds: 600));
          expect(harness.service.enableCalls, greaterThan(1));

          harness.bloc.add(const StopActiveLight());
          async.flushMicrotasks();

          expect(harness.bloc.state.activeLight, isNull);
          expect(harness.controls.lastKeepScreenOn, isFalse);

          final enablesAfterStop = harness.service.enableCalls;
          async.elapse(const Duration(seconds: 5));
          async.flushMicrotasks();
          expect(harness.service.enableCalls, enablesAfterStop);

          harness.bloc.close();
          async.flushMicrotasks();
        });
      },
    );

    test('SOS is rejected when the torch is unavailable', () {
      fakeAsync((async) {
        final harness = _Harness(
          service: FakeTorchService()..available = false,
        );
        async.flushMicrotasks();

        harness.bloc.add(const StartSos());
        async.flushMicrotasks();

        expect(harness.bloc.state.activeLight, isNull);
        expect(harness.service.enableCalls, 0);

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });

    test('strobe restarts with the new speed when adjusted', () {
      fakeAsync((async) {
        final harness = _Harness();
        async.flushMicrotasks();

        harness.bloc.add(const StartStrobe());
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 100));
        final enablesBefore = harness.service.enableCalls;

        harness.bloc.add(const SetStrobeInterval(1000));
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 100));

        expect(harness.bloc.state.strobeIntervalMs, 1000);
        expect(harness.bloc.state.activeLight, LightMode.strobe);
        expect(harness.service.enableCalls, greaterThan(enablesBefore));

        harness.bloc.add(const StopActiveLight());
        async.flushMicrotasks();
        harness.bloc.close();
        async.flushMicrotasks();
      });
    });

    test('pausing turns the output off and resume continues the sequence', () {
      fakeAsync((async) {
        final harness = _Harness();
        async.flushMicrotasks();

        harness.bloc.add(const StartSos());
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 100));

        harness.bloc.add(const PauseSequence());
        async.flushMicrotasks();

        expect(harness.bloc.state.sequencePaused, isTrue);
        expect(harness.service.disableCalls, greaterThanOrEqualTo(1));

        final enablesWhilePaused = harness.service.enableCalls;
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(harness.service.enableCalls, enablesWhilePaused);

        harness.bloc.add(const ResumeSequence());
        async.flushMicrotasks();
        expect(harness.bloc.state.sequencePaused, isFalse);

        async.elapse(const Duration(milliseconds: 500));
        expect(harness.service.enableCalls, greaterThan(enablesWhilePaused));

        harness.bloc.add(const StopActiveLight());
        async.flushMicrotasks();
        harness.bloc.close();
        async.flushMicrotasks();
      });
    });

    test('a sequence failure surfaces an error and releases the light', () {
      fakeAsync((async) {
        final harness = _Harness(
          service: FakeTorchService()
            ..enableError = const TorchFailure(TorchFailureKind.cameraInUse),
        );
        async.flushMicrotasks();

        harness.bloc.add(const StartSos());
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 10));
        async.flushMicrotasks();

        expect(harness.bloc.state.activeLight, isNull);
        expect(harness.bloc.state.error?.kind, TorchFailureKind.cameraInUse);
        expect(harness.bloc.state.sequencePaused, isFalse);
        expect(harness.controls.lastKeepScreenOn, isFalse);

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });

    test('manual torch cannot run at the same time as SOS', () {
      fakeAsync((async) {
        final harness = _Harness();
        async.flushMicrotasks();

        harness.bloc.add(const TurnOnFlashLight());
        async.flushMicrotasks();
        expect(harness.bloc.state.isTorchOn, isTrue);

        harness.bloc.add(const StartSos());
        async.flushMicrotasks();

        expect(harness.bloc.state.activeLight, LightMode.sos);
        expect(harness.service.disableCalls, greaterThanOrEqualTo(1));

        harness.bloc.add(const TurnOnFlashLight());
        async.flushMicrotasks();

        expect(harness.bloc.state.isTorchOn, isTrue);

        harness.bloc.add(const StopActiveLight());
        async.flushMicrotasks();
        harness.bloc.close();
        async.flushMicrotasks();
      });
    });
  });

  group('Morse', () {
    test('plays a message on the torch and stops when finished', () {
      fakeAsync((async) {
        final harness = _Harness();
        async.flushMicrotasks();

        harness.bloc.add(const StartMorse('E'));
        async.flushMicrotasks();

        expect(harness.bloc.state.activeLight, LightMode.morse);
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        expect(harness.bloc.state.activeLight, isNull);
        expect(harness.service.enableCalls, 1);
        expect(harness.service.disableCalls, greaterThanOrEqualTo(1));

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });

    test('rejects text with unsupported characters', () {
      fakeAsync((async) {
        final harness = _Harness();
        async.flushMicrotasks();

        harness.bloc.add(const StartMorse('A@#'));
        async.flushMicrotasks();

        expect(harness.bloc.state.activeLight, isNull);
        expect(harness.service.enableCalls, 0);

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });

    test('falls back to screen flashing when no torch exists', () {
      fakeAsync((async) {
        final harness = _Harness(
          service: FakeTorchService()..available = false,
        );
        async.flushMicrotasks();

        harness.bloc.add(const StartMorse('E'));
        async.flushMicrotasks();

        expect(harness.bloc.state.activeLight, LightMode.morse);
        expect(harness.bloc.sequencePlayer.screenFlash.value, isTrue);
        expect(harness.service.enableCalls, 0);

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();

        expect(harness.bloc.state.activeLight, isNull);
        expect(harness.bloc.sequencePlayer.screenFlash.value, isFalse);

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });
  });

  group('auto-off timer', () {
    test('arms without a light and counts down once a light is on', () {
      fakeAsync((async) {
        final harness = _Harness();
        async.flushMicrotasks();

        harness.bloc.add(const SetAutoOffTimer(1));
        async.flushMicrotasks();
        expect(harness.bloc.state.timerPresetMinutes, 1);
        expect(harness.bloc.state.timerSecondsRemaining, isNull);

        harness.bloc.add(const TurnOnFlashLight());
        async.flushMicrotasks();
        expect(harness.bloc.state.timerSecondsRemaining, 60);

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(harness.bloc.state.timerSecondsRemaining, 59);

        async.elapse(const Duration(seconds: 61));
        async.flushMicrotasks();

        expect(harness.bloc.state.isTorchOn, isFalse);
        expect(harness.bloc.state.timerSecondsRemaining, isNull);
        expect(harness.bloc.state.timerPresetMinutes, 1);
        expect(harness.service.disableCalls, 1);

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });

    test('cancelling stops the countdown without turning the light off', () {
      fakeAsync((async) {
        final harness = _Harness();
        async.flushMicrotasks();

        harness.bloc.add(const TurnOnFlashLight());
        async.flushMicrotasks();
        harness.bloc.add(const SetAutoOffTimer(5));
        async.flushMicrotasks();
        expect(harness.bloc.state.timerSecondsRemaining, 300);

        harness.bloc.add(const SetAutoOffTimer(null));
        async.flushMicrotasks();

        expect(harness.bloc.state.timerPresetMinutes, isNull);
        expect(harness.bloc.state.timerSecondsRemaining, isNull);

        async.elapse(const Duration(seconds: 10));
        expect(harness.bloc.state.isTorchOn, isTrue);
        expect(harness.service.disableCalls, 0);

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });

    test('manual off cancels stale ticks but keeps the preset', () {
      fakeAsync((async) {
        final harness = _Harness();
        async.flushMicrotasks();

        harness.bloc.add(const TurnOnFlashLight());
        async.flushMicrotasks();
        harness.bloc.add(const SetAutoOffTimer(5));
        async.flushMicrotasks();

        harness.bloc.add(const TurnOffFlashLight());
        async.flushMicrotasks();

        expect(harness.bloc.state.isTorchOn, isFalse);
        expect(harness.bloc.state.timerPresetMinutes, 5);
        expect(harness.bloc.state.timerSecondsRemaining, isNull);

        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();
        expect(harness.service.disableCalls, 1);

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });

    test('replacing the timer never leaves a stale ticker', () {
      fakeAsync((async) {
        final harness = _Harness();
        async.flushMicrotasks();

        harness.bloc.add(const TurnOnFlashLight());
        async.flushMicrotasks();
        harness.bloc.add(const SetAutoOffTimer(1));
        async.flushMicrotasks();
        harness.bloc.add(const SetAutoOffTimer(5));
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 61));
        async.flushMicrotasks();

        expect(harness.bloc.state.isTorchOn, isTrue);
        expect(harness.bloc.state.timerSecondsRemaining, lessThan(300));

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });

    test('custom preset values are clamped', () {
      fakeAsync((async) {
        final harness = _Harness();
        async.flushMicrotasks();

        harness.bloc.add(const SetAutoOffTimer(999));
        async.flushMicrotasks();
        expect(
          harness.bloc.state.timerPresetMinutes,
          LightingDefaults.maxCustomTimerMinutes,
        );

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });
  });

  group('lifecycle', () {
    test('backgrounding turns everything off and releases screen locks', () {
      fakeAsync((async) {
        final harness = _Harness();
        async.flushMicrotasks();

        harness.bloc.add(const StartScreenLight());
        async.flushMicrotasks();
        expect(harness.bloc.state.isScreenLightOn, isTrue);

        harness.bloc.add(const AppPaused());
        async.flushMicrotasks();

        expect(harness.bloc.state.activeLight, isNull);
        expect(harness.controls.restoreCalls, 1);
        expect(harness.controls.lastKeepScreenOn, isFalse);

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });

    test('backgrounding stops a running sequence', () {
      fakeAsync((async) {
        final harness = _Harness();
        async.flushMicrotasks();

        harness.bloc.add(const StartSos());
        async.flushMicrotasks();

        harness.bloc.add(const AppPaused());
        async.flushMicrotasks();

        expect(harness.bloc.state.activeLight, isNull);
        expect(harness.bloc.state.sequencePaused, isFalse);
        expect(harness.service.disableCalls, greaterThanOrEqualTo(1));

        final enablesAfterPause = harness.service.enableCalls;
        async.elapse(const Duration(seconds: 3));
        async.flushMicrotasks();
        expect(harness.service.enableCalls, enablesAfterPause);

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });

    test('detached cleanup disables an active torch and releases the lock', () {
      fakeAsync((async) {
        final harness = _Harness();
        async.flushMicrotasks();

        harness.bloc.add(const TurnOnFlashLight());
        async.flushMicrotasks();

        harness.bloc.add(const AppDetached());
        async.flushMicrotasks();

        expect(harness.bloc.state.isTorchOn, isFalse);
        expect(harness.service.disableCalls, 1);
        expect(harness.controls.lastKeepScreenOn, isFalse);

        harness.bloc.close();
        async.flushMicrotasks();
      });
    });
  });
}
