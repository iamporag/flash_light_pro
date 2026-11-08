import 'package:flash_light_pro/features/lighting/domain/light_mode.dart';
import 'package:flash_light_pro/features/settings/data/app_settings.dart';
import 'package:flash_light_pro/features/settings/domain/app_language.dart';
import 'package:flash_light_pro/features/shake/domain/shake_sensitivity.dart';
import 'package:flash_light_pro/src/bloc/flash_light/flash_light_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_device_controls.dart';
import 'fake_settings_repository.dart';
import 'fake_shake_service.dart';
import 'fake_torch_service.dart';
import 'fake_torch_state_source.dart';

Future<void> waitForState(
  FlashLightBloc bloc,
  bool Function(FlashLightState state) predicate,
) async {
  if (predicate(bloc.state)) return;
  await bloc.stream.firstWhere(predicate).timeout(const Duration(seconds: 2));
}

Future<void> waitUntil(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for a condition.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

class Harness {
  Harness({
    this.initial = const AppSettings(),
    bool torchAvailable = true,
    bool withShake = true,
    bool withSource = true,
  }) : torch = FakeTorchService()..available = torchAvailable,
       controls = FakeDeviceControls(),
       settings = FakeSettingsRepository(initial),
       shake = withShake ? FakeShakeService() : null,
       source = withSource ? FakeTorchStateSource() : null;

  final AppSettings initial;
  final FakeTorchService torch;
  final FakeDeviceControls controls;
  final FakeSettingsRepository settings;
  final FakeShakeService? shake;
  final FakeTorchStateSource? source;
  late final FlashLightBloc bloc;

  FlashLightState get state => bloc.state;

  Future<void> start() async {
    bloc = FlashLightBloc(
      torchService: torch,
      deviceControls: controls,
      settingsRepository: settings,
      shakeService: shake,
      torchStateSource: source,
    );
    await waitForState(
      bloc,
      (state) =>
          state.availability == TorchAvailability.available ||
          state.availability == TorchAvailability.unavailable,
    );
  }

  /// Sends a harmless event and waits until it has been processed, which
  /// guarantees every event queued before it is done.
  Future<void> flush() async {
    final target = !state.hapticsEnabled;
    bloc.add(SetHapticsEnabled(target));
    await waitForState(bloc, (state) => state.hapticsEnabled == target);
  }

  Future<void> dispose() async {
    await bloc.close();
    await source?.dispose();
  }
}

void main() {
  group('shake detection lifecycle', () {
    test('an enabled setting starts the sensor on launch', () async {
      final harness = Harness(initial: const AppSettings(shakeEnabled: true));
      addTearDown(harness.dispose);

      await harness.start();

      expect(harness.state.shakeEnabled, isTrue);
      expect(harness.shake!.isRunning, isTrue);
      expect(harness.shake!.startCalls, 1);
      expect(harness.shake!.lastSensitivity, ShakeSensitivity.medium);
    });

    test('turning shake off stops the sensor', () async {
      final harness = Harness(initial: const AppSettings(shakeEnabled: true));
      addTearDown(harness.dispose);
      await harness.start();

      harness.bloc.add(const SetShakeEnabled(false));
      await waitForState(harness.bloc, (state) => !state.shakeEnabled);

      expect(harness.shake!.isRunning, isFalse);
      expect(harness.shake!.stopCalls, greaterThanOrEqualTo(1));
    });

    test(
      'changing sensitivity restarts the sensor with the new threshold',
      () async {
        final harness = Harness(initial: const AppSettings(shakeEnabled: true));
        addTearDown(harness.dispose);
        await harness.start();

        harness.bloc.add(const SetShakeSensitivity(ShakeSensitivity.high));
        await waitForState(
          harness.bloc,
          (state) => state.shakeSensitivity == ShakeSensitivity.high,
        );

        expect(harness.shake!.lastSensitivity, ShakeSensitivity.high);
        expect(harness.shake!.isRunning, isTrue);
      },
    );

    test('a shake toggles the torch when enabled', () async {
      final harness = Harness(initial: const AppSettings(shakeEnabled: true));
      addTearDown(harness.dispose);
      await harness.start();

      harness.shake!.shake();
      await waitForState(harness.bloc, (state) => state.isTorchOn);
      expect(harness.torch.enableCalls, 1);

      harness.shake!.shake();
      await waitForState(harness.bloc, (state) => !state.isTorchOn);
      expect(harness.torch.disableCalls, 1);
    });

    test('shake events are ignored while the setting is off', () async {
      final harness = Harness();
      addTearDown(harness.dispose);
      await harness.start();

      harness.shake!.shake();
      harness.bloc.add(const SetReduceAnimations(true));
      await waitForState(harness.bloc, (state) => state.reduceAnimations);

      expect(harness.state.isTorchOn, isFalse);
      expect(harness.torch.enableCalls, 0);
    });

    test('pausing stops detection and resuming restarts it', () async {
      final harness = Harness(initial: const AppSettings(shakeEnabled: true));
      addTearDown(harness.dispose);
      await harness.start();

      harness.bloc.add(const AppPaused());
      await waitUntil(() => !harness.shake!.isRunning);

      harness.shake!.shake();
      await harness.flush();
      expect(harness.state.isTorchOn, isFalse);
      expect(harness.torch.enableCalls, 0);

      harness.bloc.add(const AppResumed());
      await waitUntil(() => harness.shake!.isRunning);

      harness.shake!.shake();
      await waitForState(harness.bloc, (state) => state.isTorchOn);
    });

    test('closing the Bloc disposes the sensor', () async {
      final harness = Harness(initial: const AppSettings(shakeEnabled: true));
      await harness.start();

      await harness.bloc.close();

      expect(harness.shake!.disposeCalls, 1);
      await harness.source!.dispose();
    });
  });

  group('external torch synchronization', () {
    test(
      'a native turn-on updates Flutter without toggling the hardware',
      () async {
        final harness = Harness();
        addTearDown(harness.dispose);
        await harness.start();

        harness.source!.emit(true);
        await waitForState(harness.bloc, (state) => state.isTorchOn);

        expect(harness.state.activeLight, LightMode.torch);
        expect(harness.state.selectedMode, LightMode.torch);
        expect(harness.state.error, isNull);
        expect(harness.torch.enableCalls, 0);
        expect(harness.controls.lastKeepScreenOn, isTrue);
      },
    );

    test(
      'a native turn-off clears the torch without a duplicate hardware call',
      () async {
        final harness = Harness();
        addTearDown(harness.dispose);
        await harness.start();

        harness.bloc.add(const TurnOnFlashLight());
        await waitForState(harness.bloc, (state) => state.isTorchOn);
        final disableCalls = harness.torch.disableCalls;

        harness.source!.emit(false);
        await waitForState(harness.bloc, (state) => !state.isTorchOn);

        expect(harness.state.activeLight, isNull);
        expect(harness.torch.disableCalls, disableCalls);
        expect(harness.controls.lastKeepScreenOn, isFalse);
      },
    );

    test('a native turn-on replaces an active screen light', () async {
      final harness = Harness();
      addTearDown(harness.dispose);
      await harness.start();

      harness.bloc.add(const StartScreenLight());
      await waitForState(harness.bloc, (state) => state.isScreenLightOn);

      harness.source!.emit(true);
      await waitForState(harness.bloc, (state) => state.isTorchOn);

      expect(harness.state.isScreenLightOn, isFalse);
      expect(harness.controls.restoreCalls, 1);
      expect(harness.torch.disableCalls, 0);
    });

    test(
      'pausing does not switch off a torch started outside Flutter',
      () async {
        final harness = Harness();
        addTearDown(harness.dispose);
        await harness.start();

        harness.source!.emit(true);
        await waitForState(harness.bloc, (state) => state.isTorchOn);
        final disableCalls = harness.torch.disableCalls;

        harness.bloc.add(const AppPaused());
        await harness.flush();

        expect(harness.state.isTorchOn, isTrue);
        expect(harness.torch.disableCalls, disableCalls);
      },
    );

    test('native changes do not interrupt a running sequence', () async {
      final harness = Harness();
      addTearDown(harness.dispose);
      await harness.start();

      harness.bloc.add(const StartSos());
      await waitForState(
        harness.bloc,
        (state) => state.activeLight == LightMode.sos,
      );

      harness.source!.emit(false);
      await harness.flush();

      expect(harness.state.activeLight, LightMode.sos);

      harness.bloc.add(const StopActiveLight());
      await waitForState(harness.bloc, (state) => state.activeLight == null);
    });

    test('a native turn-on recovers from an unavailable check', () async {
      final harness = Harness(torchAvailable: false);
      addTearDown(harness.dispose);
      await harness.start();
      expect(harness.state.availability, TorchAvailability.unavailable);

      harness.source!.emit(true);
      await waitForState(harness.bloc, (state) => state.isTorchOn);

      expect(harness.state.availability, TorchAvailability.available);
    });
  });

  group('settings persistence', () {
    test('stored settings are restored on launch', () async {
      final harness = Harness(
        initial: const AppSettings(
          selectedMode: LightMode.strobe,
          appLanguage: AppLanguage.bengali,
          hapticsEnabled: false,
          shakeEnabled: true,
          shakeSensitivity: ShakeSensitivity.high,
          keepScreenAwake: false,
          reduceAnimations: true,
        ),
      );
      addTearDown(harness.dispose);
      await harness.start();

      final state = harness.state;
      expect(state.selectedMode, LightMode.strobe);
      expect(state.appLanguage, AppLanguage.bengali);
      expect(state.hapticsEnabled, isFalse);
      expect(state.shakeEnabled, isTrue);
      expect(state.shakeSensitivity, ShakeSensitivity.high);
      expect(state.keepScreenAwake, isFalse);
      expect(state.reduceAnimations, isTrue);
    });

    test('every Phase 3 setting is saved', () async {
      final harness = Harness();
      addTearDown(harness.dispose);
      await harness.start();

      harness.bloc.add(const SetAppLanguage(AppLanguage.bengali));
      harness.bloc.add(const SetHapticsEnabled(false));
      harness.bloc.add(const SetShakeEnabled(true));
      harness.bloc.add(const SetShakeSensitivity(ShakeSensitivity.low));
      harness.bloc.add(const SetKeepScreenAwake(false));
      harness.bloc.add(const SetReduceAnimations(true));
      await waitForState(harness.bloc, (state) => state.reduceAnimations);

      final saved = harness.settings.saved.last;
      expect(saved.appLanguage, AppLanguage.bengali);
      expect(saved.hapticsEnabled, isFalse);
      expect(saved.shakeEnabled, isTrue);
      expect(saved.shakeSensitivity, ShakeSensitivity.low);
      expect(saved.keepScreenAwake, isFalse);
      expect(saved.reduceAnimations, isTrue);
    });

    test('disabling keep-awake while lit applies it immediately', () async {
      final harness = Harness();
      addTearDown(harness.dispose);
      await harness.start();

      harness.bloc.add(const TurnOnFlashLight());
      await waitForState(harness.bloc, (state) => state.isTorchOn);
      expect(harness.controls.lastKeepScreenOn, isTrue);

      harness.bloc.add(const SetKeepScreenAwake(false));
      await waitForState(harness.bloc, (state) => !state.keepScreenAwake);
      await waitUntil(() => harness.controls.lastKeepScreenOn == false);

      expect(harness.controls.lastKeepScreenOn, isFalse);
      await waitUntil(
        () =>
            harness.settings.saved.isNotEmpty &&
            !harness.settings.saved.last.keepScreenAwake,
      );
      expect(harness.settings.saved.last.keepScreenAwake, isFalse);
    });

    test('the default mode is persisted when the user picks one', () async {
      final harness = Harness();
      addTearDown(harness.dispose);
      await harness.start();

      harness.bloc.add(const SelectLightMode(LightMode.morse));
      await waitForState(
        harness.bloc,
        (state) => state.selectedMode == LightMode.morse,
      );

      expect(harness.settings.saved.last.selectedMode, LightMode.morse);
    });
  });
}
