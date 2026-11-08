import 'dart:async';

import 'package:flash_light_pro/features/device/services/native_controls.dart';
import 'package:flash_light_pro/features/lighting/domain/light_mode.dart';
import 'package:flash_light_pro/features/settings/data/app_settings.dart';
import 'package:flash_light_pro/src/bloc/flash_light/flash_light_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_background_torch_service.dart';
import 'fake_device_controls.dart';
import 'fake_settings_repository.dart';
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

class FakeNativeControls implements NativeControlsSource {
  final StreamController<NativeControlsSnapshot> _controller =
      StreamController<NativeControlsSnapshot>.broadcast();

  @override
  Stream<NativeControlsSnapshot> get changes => _controller.stream;

  void emit(NativeControlsSnapshot snapshot) => _controller.add(snapshot);

  Future<void> dispose() => _controller.close();
}

class Harness {
  Harness({
    bool nativePatternSupported = false,
    FakeBackgroundTorchService? background,
    AppSettings initial = const AppSettings(),
  }) : controls = FakeDeviceControls()
         ..nativePatternSupported = nativePatternSupported,
       background = background ?? FakeBackgroundTorchService(),
       settings = FakeSettingsRepository(initial);

  final FakeDeviceControls controls;
  final FakeBackgroundTorchService background;
  final FakeSettingsRepository settings;
  final FakeTorchService torch = FakeTorchService();
  final FakeTorchStateSource stateSource = FakeTorchStateSource();
  final FakeNativeControls nativeControls = FakeNativeControls();
  late final FlashLightBloc bloc;

  Future<void> start() async {
    bloc = FlashLightBloc(
      torchService: torch,
      deviceControls: controls,
      settingsRepository: settings,
      torchStateSource: stateSource,
      backgroundTorchService: background,
      nativeControlsSource: nativeControls,
    );
    await waitForState(
      bloc,
      (state) =>
          state.availability == TorchAvailability.available ||
          state.availability == TorchAvailability.unavailable,
    );
  }

  Future<void> emit(NativeControlsSnapshot snapshot) async {
    nativeControls.emit(snapshot);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> dispose() async {
    await bloc.close();
    await nativeControls.dispose();
    await stateSource.dispose();
    await background.dispose();
  }
}

void main() {
  group('native controls snapshot', () {
    test('parses the wire map the Android service publishes', () {
      final snapshot = NativeControlsSnapshot.fromMap({
        'mode': 'sos',
        'paused': true,
        'torchOn': true,
        'available': false,
        'shakeEnabled': true,
        'shakeMonitoring': true,
        'backgroundServiceRunning': true,
        'notificationsEnabled': false,
      });

      expect(snapshot.mode, NativePatternMode.sos);
      expect(snapshot.paused, isTrue);
      expect(snapshot.torchOn, isTrue);
      expect(snapshot.available, isFalse);
      expect(snapshot.shakeEnabled, isTrue);
      expect(snapshot.shakeMonitoring, isTrue);
      expect(snapshot.backgroundServiceRunning, isTrue);
      expect(snapshot.notificationsEnabled, isFalse);
    });

    test('missing or unknown values fall back to safe defaults', () {
      final snapshot = NativeControlsSnapshot.fromMap({
        'mode': 'morse',
        'available': null,
      });

      expect(snapshot.mode, NativePatternMode.off);
      expect(snapshot.paused, isFalse);
      expect(snapshot.available, isTrue);
      expect(snapshot.notificationsEnabled, isTrue);
      expect(
        NativeControlsSnapshot.fromMap('not a map').mode,
        NativePatternMode.off,
      );
    });
  });

  group('native pattern ownership', () {
    test('SOS starts the native player when the device supports it', () async {
      final harness = Harness(nativePatternSupported: true);
      addTearDown(harness.dispose);
      await harness.start();

      harness.bloc.add(const StartSos());
      await waitForState(
        harness.bloc,
        (state) => state.activeLight == LightMode.sos,
      );

      expect(harness.controls.startModeCalls, ['sos']);
      expect(harness.torch.enableCalls, 0);
    });

    test(
      'SOS falls back to the Dart sequence when native playback fails',
      () async {
        final harness = Harness();
        addTearDown(harness.dispose);
        await harness.start();

        harness.bloc.add(const StartSos());
        await waitForState(
          harness.bloc,
          (state) => state.activeLight == LightMode.sos,
        );

        expect(harness.controls.startModeCalls, ['sos']);
        await waitUntil(() => harness.torch.enableCalls > 0);
      },
    );

    test('the notification panel can pause a native strobe', () async {
      final harness = Harness(nativePatternSupported: true);
      addTearDown(harness.dispose);
      await harness.start();

      await harness.emit(
        const NativeControlsSnapshot(
          mode: NativePatternMode.strobe,
          torchOn: true,
          backgroundServiceRunning: true,
        ),
      );
      await waitForState(
        harness.bloc,
        (state) => state.activeLight == LightMode.strobe,
      );
      await harness.emit(
        const NativeControlsSnapshot(
          mode: NativePatternMode.strobe,
          paused: true,
          torchOn: true,
          backgroundServiceRunning: true,
        ),
      );

      expect(harness.bloc.state.sequencePaused, isTrue);
      expect(harness.bloc.state.activeLight, LightMode.strobe);
    });

    test(
      'a native stop clears the active mode and stops an idle service',
      () async {
        final harness = Harness(nativePatternSupported: true);
        addTearDown(harness.dispose);
        await harness.start();

        await harness.emit(
          const NativeControlsSnapshot(
            mode: NativePatternMode.sos,
            torchOn: true,
            backgroundServiceRunning: true,
          ),
        );
        await waitForState(
          harness.bloc,
          (state) => state.activeLight == LightMode.sos,
        );
        expect(harness.bloc.state.backgroundTorchActive, isTrue);

        await harness.emit(
          const NativeControlsSnapshot(
            mode: NativePatternMode.off,
            backgroundServiceRunning: true,
          ),
        );
        await waitForState(
          harness.bloc,
          (state) => state.activeLight == null && !state.backgroundTorchActive,
        );

        expect(harness.background.stopCalls, 1);
      },
    );

    test('native shake state is mirrored and persisted', () async {
      final harness = Harness();
      addTearDown(harness.dispose);
      await harness.start();

      await harness.emit(
        const NativeControlsSnapshot(
          shakeEnabled: true,
          shakeMonitoring: true,
          backgroundServiceRunning: true,
        ),
      );

      expect(harness.bloc.state.shakeEnabled, isTrue);
      expect(harness.bloc.state.shakeMonitoringActive, isTrue);
      expect(harness.bloc.state.backgroundTorchActive, isTrue);
      expect(harness.settings.saved.last.shakeEnabled, isTrue);
      expect(harness.background.stopCalls, 0);
    });
  });
}
