import 'package:flash_light_pro/features/settings/data/app_settings.dart';
import 'package:flash_light_pro/features/shake/domain/shake_sensitivity.dart';
import 'package:flash_light_pro/features/shake/services/shake_monitor_service.dart';
import 'package:flash_light_pro/src/bloc/flash_light/flash_light_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_device_controls.dart';
import 'fake_settings_repository.dart';
import 'fake_shake_monitor_service.dart';
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

class MonitorHarness {
  MonitorHarness({
    this.initial = const AppSettings(),
    FakeShakeMonitorService? monitor,
  }) : torch = FakeTorchService(),
       controls = FakeDeviceControls(),
       settings = FakeSettingsRepository(initial),
       monitor = monitor ?? FakeShakeMonitorService(),
       shake = FakeShakeService(),
       source = FakeTorchStateSource();

  final AppSettings initial;
  final FakeTorchService torch;
  final FakeDeviceControls controls;
  final FakeSettingsRepository settings;
  final FakeShakeMonitorService monitor;
  final FakeShakeService shake;
  final FakeTorchStateSource source;
  late final FlashLightBloc bloc;

  FlashLightState get state => bloc.state;

  Future<void> start() async {
    bloc = FlashLightBloc(
      torchService: torch,
      deviceControls: controls,
      settingsRepository: settings,
      shakeService: shake,
      shakeMonitorService: monitor,
      torchStateSource: source,
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
    await source.dispose();
    await monitor.dispose();
  }
}

void main() {
  group('native background shake monitoring', () {
    test(
      'an enabled setting starts the native monitor, not the SDK one',
      () async {
        final harness = MonitorHarness(
          initial: const AppSettings(shakeEnabled: true),
        );
        addTearDown(harness.dispose);

        await harness.start();
        await waitUntil(() => harness.state.shakeMonitoringActive);

        expect(harness.monitor.startCalls, 1);
        expect(harness.monitor.lastEnabled, isTrue);
        expect(harness.state.shakeMonitoringSupported, isTrue);
        expect(harness.shake.isRunning, isFalse);
      },
    );

    test('monitoring stays off until the user enables shake', () async {
      final harness = MonitorHarness();
      addTearDown(harness.dispose);

      await harness.start();
      await harness.flush();

      expect(harness.monitor.startCalls, 0);
      expect(harness.state.shakeMonitoringActive, isFalse);
      expect(harness.shake.isRunning, isFalse);
    });

    test('enabling asks for notification permission once', () async {
      final monitor = FakeShakeMonitorService(notificationsEnabled: false);
      final harness = MonitorHarness(monitor: monitor);
      addTearDown(harness.dispose);
      await harness.start();

      harness.bloc.add(const SetShakeEnabled(true));
      await waitForState(harness.bloc, (state) => state.shakeEnabled);
      await waitUntil(() => harness.state.shakeMonitoringActive);

      expect(harness.state.shakeNotificationsEnabled, isFalse);
      expect(monitor.requestPermissionCalls, 1);

      harness.bloc.add(const SetShakeSensitivity(ShakeSensitivity.high));
      await waitForState(
        harness.bloc,
        (state) => state.shakeSensitivity == ShakeSensitivity.high,
      );
      await harness.flush();

      expect(monitor.requestPermissionCalls, 1);
      expect(monitor.lastSensitivity, ShakeSensitivity.high);
    });

    test('disabling stops monitoring but leaves the torch running', () async {
      final harness = MonitorHarness(
        initial: const AppSettings(shakeEnabled: true),
      );
      addTearDown(harness.dispose);
      await harness.start();
      await waitUntil(() => harness.state.shakeMonitoringActive);

      harness.bloc.add(const TurnOnFlashLight());
      await waitForState(harness.bloc, (state) => state.isTorchOn);
      final disableCalls = harness.torch.disableCalls;

      harness.bloc.add(const SetShakeEnabled(false));
      await waitForState(harness.bloc, (state) => !state.shakeEnabled);
      await waitUntil(() => harness.monitor.stopCalls == 1);

      expect(harness.state.isTorchOn, isTrue);
      expect(harness.torch.disableCalls, disableCalls);
      expect(harness.state.shakeMonitoringActive, isFalse);
      expect(harness.monitor.lastEnabled, isFalse);
    });

    test(
      'a failed native start falls back to the visible-app listener',
      () async {
        final monitor = FakeShakeMonitorService(startSucceeds: false);
        final harness = MonitorHarness(
          initial: const AppSettings(shakeEnabled: true),
          monitor: monitor,
        );
        addTearDown(harness.dispose);
        await harness.start();

        await waitUntil(() => monitor.startCalls == 1);
        await waitUntil(() => harness.shake.isRunning);

        expect(harness.state.shakeMonitoringActive, isFalse);
        expect(harness.state.shakeEnabled, isTrue);
      },
    );

    test(
      'a running status event owns detection and stops the fallback',
      () async {
        final monitor = FakeShakeMonitorService(startSucceeds: false);
        final harness = MonitorHarness(
          initial: const AppSettings(shakeEnabled: true),
          monitor: monitor,
        );
        addTearDown(harness.dispose);
        await harness.start();
        await waitUntil(() => harness.shake.isRunning);

        monitor.emitStatus(ShakeMonitorStatus.running);
        await waitForState(
          harness.bloc,
          (state) => state.shakeMonitoringActive,
        );
        await waitUntil(() => !harness.shake.isRunning);

        expect(harness.state.shakeMonitoringSupported, isTrue);
      },
    );

    test('resuming reconciles the hardware without toggling it', () async {
      final harness = MonitorHarness(
        initial: const AppSettings(shakeEnabled: true),
      );
      addTearDown(harness.dispose);
      await harness.start();
      await waitUntil(() => harness.state.shakeMonitoringActive);

      harness.bloc.add(const AppPaused());
      await harness.flush();
      final enableCalls = harness.torch.enableCalls;
      final disableCalls = harness.torch.disableCalls;

      // A background shake turned the hardware on while no UI was visible.
      harness.torch.hardwareOn = true;
      harness.bloc.add(const AppResumed());
      await waitForState(harness.bloc, (state) => state.isTorchOn);

      expect(harness.torch.enableCalls, enableCalls);
      expect(harness.torch.disableCalls, disableCalls);
      expect(harness.state.shakeMonitoringActive, isTrue);
      expect(harness.monitor.isRunningCalls, greaterThanOrEqualTo(1));
    });

    test('resuming refreshes the notification permission note', () async {
      final monitor = FakeShakeMonitorService();
      final harness = MonitorHarness(
        initial: const AppSettings(shakeEnabled: true),
        monitor: monitor,
      );
      addTearDown(harness.dispose);
      await harness.start();
      await waitUntil(() => harness.state.shakeMonitoringActive);
      expect(harness.state.shakeNotificationsEnabled, isTrue);

      monitor.notificationsEnabled = false;
      harness.bloc.add(const AppPaused());
      await harness.flush();

      harness.bloc.add(const AppResumed());
      await waitForState(
        harness.bloc,
        (state) => !state.shakeNotificationsEnabled,
      );

      expect(harness.state.shakeMonitoringActive, isTrue);
      expect(monitor.startCalls, 1);
    });

    test('sequences and screen light are mirrored as blocked', () async {
      final harness = MonitorHarness(
        initial: const AppSettings(shakeEnabled: true),
      );
      addTearDown(harness.dispose);
      await harness.start();
      await waitUntil(() => harness.state.shakeMonitoringActive);
      await waitUntil(() => harness.monitor.lastBlocked == false);

      harness.bloc.add(const StartScreenLight());
      await waitForState(harness.bloc, (state) => state.isScreenLightOn);
      await waitUntil(() => harness.monitor.lastBlocked == true);

      harness.bloc.add(const StopActiveLight());
      await waitForState(harness.bloc, (state) => state.activeLight == null);
      await waitUntil(() => harness.monitor.lastBlocked == false);
    });

    test('closing the Bloc leaves native monitoring running', () async {
      final harness = MonitorHarness(
        initial: const AppSettings(shakeEnabled: true),
      );
      await harness.start();
      await waitUntil(() => harness.state.shakeMonitoringActive);

      final monitor = harness.monitor;
      final source = harness.source;
      await harness.bloc.close();

      expect(monitor.stopCalls, 0);
      expect(monitor.running, isTrue);
      await source.dispose();
      await monitor.dispose();
    });

    test('unsupported devices keep the foreground fallback', () async {
      final monitor = FakeShakeMonitorService(supported: false);
      final harness = MonitorHarness(
        initial: const AppSettings(shakeEnabled: true),
        monitor: monitor,
      );
      addTearDown(harness.dispose);
      await harness.start();

      await waitUntil(() => harness.shake.isRunning);

      expect(monitor.startCalls, 0);
      expect(harness.state.shakeMonitoringSupported, isFalse);
      expect(harness.state.shakeMonitoringActive, isFalse);
    });
  });
}
