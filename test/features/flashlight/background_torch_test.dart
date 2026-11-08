import 'package:flash_light_pro/features/flashlight/services/background_torch_service.dart';
import 'package:flash_light_pro/features/lighting/domain/light_mode.dart';
import 'package:flash_light_pro/features/settings/data/app_settings.dart';
import 'package:flash_light_pro/src/bloc/flash_light/flash_light_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_background_torch_service.dart';
import 'fake_device_controls.dart';
import 'fake_settings_repository.dart';
import 'fake_torch_service.dart';

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

class _Harness {
  _Harness({
    this.initial = const AppSettings(),
    bool supported = true,
    bool notificationsEnabled = true,
    bool startSucceeds = true,
  }) : settings = FakeSettingsRepository(initial),
       background = FakeBackgroundTorchService(
         supported: supported,
         notificationsEnabled: notificationsEnabled,
         startSucceeds: startSucceeds,
       );

  final AppSettings initial;
  final FakeTorchService torch = FakeTorchService();
  final FakeDeviceControls controls = FakeDeviceControls();
  final FakeSettingsRepository settings;
  final FakeBackgroundTorchService background;
  late final FlashLightBloc bloc;

  FlashLightState get state => bloc.state;

  Future<void> start() async {
    bloc = FlashLightBloc(
      torchService: torch,
      deviceControls: controls,
      settingsRepository: settings,
      backgroundTorchService: background,
    );
    await waitForState(
      bloc,
      (state) =>
          state.availability == TorchAvailability.available ||
          state.availability == TorchAvailability.unavailable,
    );
  }

  Future<void> flush() async {
    final target = !state.hapticsEnabled;
    bloc.add(SetHapticsEnabled(target));
    await waitForState(bloc, (state) => state.hapticsEnabled == target);
  }

  Future<void> dispose() async {
    await bloc.close();
    await background.dispose();
  }
}

void main() {
  group('background setting', () {
    test('is refreshed from supported native hardware', () async {
      final harness = _Harness(
        initial: const AppSettings(backgroundTorchEnabled: true),
      );
      addTearDown(harness.dispose);
      await harness.start();

      expect(harness.state.backgroundTorchSupported, isTrue);
      expect(harness.state.backgroundTorchEnabled, isTrue);
    });

    test('stays off when the platform cannot run it', () async {
      final harness = _Harness(
        supported: false,
        initial: const AppSettings(backgroundTorchEnabled: true),
      );
      addTearDown(harness.dispose);
      await harness.start();

      expect(harness.state.backgroundTorchSupported, isFalse);
      expect(harness.state.backgroundTorchEnabled, isFalse);

      harness.bloc.add(const SetBackgroundTorch(true));
      await harness.flush();

      expect(harness.state.backgroundTorchEnabled, isFalse);
      expect(harness.background.requestPermissionCalls, 0);
    });

    test(
      'enabling lights the service and requests notification access',
      () async {
        final harness = _Harness(
          initial: const AppSettings(backgroundTorchEnabled: false),
          notificationsEnabled: false,
        );
        addTearDown(harness.dispose);
        await harness.start();

        harness.bloc.add(const TurnOnFlashLight());
        await waitForState(harness.bloc, (state) => state.isTorchOn);
        expect(harness.background.startCalls, 0);

        harness.bloc.add(const SetBackgroundTorch(true));
        await waitForState(
          harness.bloc,
          (state) =>
              state.backgroundTorchActive && state.backgroundTorchEnabled,
        );

        expect(harness.background.requestPermissionCalls, 1);
        expect(harness.state.backgroundNotificationsEnabled, isFalse);
        await waitUntil(
          () =>
              harness.settings.saved.isNotEmpty &&
              harness.settings.saved.last.backgroundTorchEnabled,
        );
      },
    );

    test(
      'a failed service start is reported without claiming it runs',
      () async {
        final harness = _Harness(startSucceeds: false);
        addTearDown(harness.dispose);
        await harness.start();

        harness.bloc.add(const TurnOnFlashLight());
        await waitForState(harness.bloc, (state) => state.isTorchOn);
        harness.bloc.add(const SetBackgroundTorch(true));

        await waitUntil(() => harness.background.startCalls == 1);
        await harness.flush();

        expect(harness.state.backgroundTorchActive, isFalse);
        expect(harness.state.isTorchOn, isTrue);
      },
    );
  });

  group('lifecycle with background mode', () {
    test('the default mode keeps the torch through a pause', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      await harness.start();

      expect(harness.state.backgroundTorchEnabled, isTrue);

      harness.bloc.add(const TurnOnFlashLight());
      await waitForState(harness.bloc, (state) => state.isTorchOn);
      await waitForState(harness.bloc, (state) => state.backgroundTorchActive);

      harness.bloc.add(const AppPaused());
      await harness.flush();

      expect(harness.state.isTorchOn, isTrue);
      expect(harness.torch.disableCalls, 0);
      expect(harness.background.stopCalls, 0);
    });

    test('pausing keeps the steady torch and service alive', () async {
      final harness = _Harness(
        initial: const AppSettings(backgroundTorchEnabled: true),
      );
      addTearDown(harness.dispose);
      await harness.start();

      harness.bloc.add(const TurnOnFlashLight());
      await waitForState(harness.bloc, (state) => state.isTorchOn);
      await waitForState(harness.bloc, (state) => state.backgroundTorchActive);

      harness.bloc.add(const AppPaused());
      await harness.flush();

      expect(harness.state.isTorchOn, isTrue);
      expect(harness.torch.disableCalls, 0);
      expect(harness.background.stopCalls, 0);
    });

    test('detaching the activity keeps the default background torch', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      await harness.start();

      harness.bloc.add(const TurnOnFlashLight());
      await waitForState(harness.bloc, (state) => state.isTorchOn);
      await waitForState(harness.bloc, (state) => state.backgroundTorchActive);

      harness.bloc.add(const AppDetached());
      await waitForState(harness.bloc, (state) => !state.isBusy);
      await harness.flush();

      expect(harness.state.isTorchOn, isTrue);
      expect(harness.torch.disableCalls, 0);
      expect(harness.background.stopCalls, 0);
    });

    test(
      'pausing still turns the torch off when the mode is disabled',
      () async {
        final harness = _Harness(
          initial: const AppSettings(backgroundTorchEnabled: false),
        );
        addTearDown(harness.dispose);
        await harness.start();

        harness.bloc.add(const TurnOnFlashLight());
        await waitForState(harness.bloc, (state) => state.isTorchOn);

        harness.bloc.add(const AppPaused());
        await waitForState(harness.bloc, (state) => !state.isTorchOn);

        expect(harness.torch.disableCalls, 1);
      },
    );

    test('patterns stop safely when the app leaves the foreground', () async {
      final harness = _Harness(
        initial: const AppSettings(backgroundTorchEnabled: true),
      );
      addTearDown(harness.dispose);
      await harness.start();

      harness.bloc.add(const StartSos());
      await waitForState(
        harness.bloc,
        (state) => state.activeLight == LightMode.sos,
      );
      expect(harness.background.startCalls, 0);

      harness.bloc.add(const AppPaused());
      await waitForState(harness.bloc, (state) => state.activeLight == null);

      expect(harness.background.stopCalls, 0);
      final enablesAfterPause = harness.torch.enableCalls;
      await Future<void>.delayed(const Duration(seconds: 2));
      expect(harness.torch.enableCalls, enablesAfterPause);
    });

    test('an explicit stop disables the torch and stops the service', () async {
      final harness = _Harness(
        initial: const AppSettings(backgroundTorchEnabled: true),
      );
      addTearDown(harness.dispose);
      await harness.start();

      harness.bloc.add(const TurnOnFlashLight());
      await waitForState(harness.bloc, (state) => state.isTorchOn);
      await waitForState(harness.bloc, (state) => state.backgroundTorchActive);

      harness.bloc.add(const TurnOffFlashLight());
      await waitForState(harness.bloc, (state) => state.activeLight == null);
      await waitUntil(() => !harness.state.backgroundTorchActive);

      expect(harness.torch.disableCalls, 1);
      expect(harness.background.stopCalls, greaterThanOrEqualTo(1));
    });
  });

  group('state synchronization after returning', () {
    test('resume reads the native torch and never toggles it', () async {
      final harness = _Harness(
        initial: const AppSettings(backgroundTorchEnabled: true),
      );
      addTearDown(harness.dispose);
      await harness.start();

      harness.bloc.add(const TurnOnFlashLight());
      await waitForState(harness.bloc, (state) => state.isTorchOn);
      await waitForState(harness.bloc, (state) => state.backgroundTorchActive);

      // The notification Stop action turned the hardware off while the app was
      // not rendering, but the Flutter state still says on.
      harness.torch.hardwareOn = false;
      harness.background.running = false;

      harness.bloc.add(const AppResumed());
      await waitForState(harness.bloc, (state) => !state.isTorchOn);

      expect(harness.state.activeLight, isNull);
      expect(harness.torch.enableCalls, 1);
      expect(harness.torch.disableCalls, 0);
    });

    test(
      'a service stop event reconciles the torch without toggling',
      () async {
        final harness = _Harness(
          initial: const AppSettings(backgroundTorchEnabled: true),
        );
        addTearDown(harness.dispose);
        await harness.start();

        harness.bloc.add(const TurnOnFlashLight());
        await waitForState(harness.bloc, (state) => state.isTorchOn);
        await waitForState(
          harness.bloc,
          (state) => state.backgroundTorchActive,
        );

        harness.torch.hardwareOn = false;
        harness.background.emitStatus(BackgroundTorchStatus.stopped);
        await waitForState(harness.bloc, (state) => !state.isTorchOn);

        expect(harness.state.backgroundTorchActive, isFalse);
        expect(harness.torch.enableCalls, 1);
        expect(harness.torch.disableCalls, 0);
      },
    );

    test('resume restarts the service when the mode is enabled', () async {
      final harness = _Harness(
        initial: const AppSettings(backgroundTorchEnabled: true),
      );
      addTearDown(harness.dispose);
      await harness.start();

      harness.bloc.add(const TurnOnFlashLight());
      await waitForState(harness.bloc, (state) => state.isTorchOn);
      await waitForState(harness.bloc, (state) => state.backgroundTorchActive);

      harness.torch.hardwareOn = true;
      harness.background.running = false;

      harness.bloc.add(const AppResumed());
      await waitUntil(() => harness.background.startCalls >= 2);

      expect(harness.state.backgroundTorchActive, isTrue);
      expect(harness.state.isTorchOn, isTrue);
    });
  });
}
