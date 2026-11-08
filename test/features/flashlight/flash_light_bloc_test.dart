import 'dart:async';

import 'package:flash_light_pro/features/flashlight/services/torch_service.dart';
import 'package:flash_light_pro/features/lighting/domain/light_mode.dart';
import 'package:flash_light_pro/src/bloc/flash_light/flash_light_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_torch_service.dart';

Future<void> waitForState(
  FlashLightBloc bloc,
  bool Function(FlashLightState state) predicate,
) async {
  if (predicate(bloc.state)) return;
  await bloc.stream.firstWhere(predicate).timeout(const Duration(seconds: 2));
}

Future<void> waitForAvailability(
  FlashLightBloc bloc,
  TorchAvailability availability,
) {
  return waitForState(bloc, (state) => state.availability == availability);
}

void main() {
  group('availability', () {
    test(
      'starts loading and becomes available after the startup check',
      () async {
        final service = FakeTorchService()
          ..availabilityGate = Completer<void>();
        final bloc = FlashLightBloc(torchService: service);
        addTearDown(bloc.close);

        expect(bloc.state.isLoading, isTrue);
        expect(bloc.state.isAvailable, isFalse);

        await waitForAvailability(bloc, TorchAvailability.checking);
        service.availabilityGate!.complete();

        await waitForAvailability(bloc, TorchAvailability.available);
        expect(bloc.state.isAvailable, isTrue);
        expect(bloc.state.isLoading, isFalse);
        expect(bloc.state.error, isNull);
      },
    );

    test(
      'device without a flashlight becomes unavailable without an error',
      () async {
        final service = FakeTorchService()..available = false;
        final bloc = FlashLightBloc(torchService: service);
        addTearDown(bloc.close);

        await waitForAvailability(bloc, TorchAvailability.unavailable);

        expect(bloc.state.isAvailable, isFalse);
        expect(bloc.state.isLoading, isFalse);
        expect(bloc.state.isTorchOn, isFalse);
        expect(bloc.state.error, isNull);
      },
    );

    test(
      'availability exception becomes unavailable without a dialog error',
      () async {
        final service = FakeTorchService()
          ..availabilityError = const TorchFailure(
            TorchFailureKind.availabilityFailed,
          );
        final bloc = FlashLightBloc(torchService: service);
        addTearDown(bloc.close);

        await waitForAvailability(bloc, TorchAvailability.unavailable);

        expect(bloc.state.isAvailable, isFalse);
        expect(bloc.state.isLoading, isFalse);
        expect(bloc.state.error, isNull);
      },
    );

    test(
      'does not repeat a successful availability check unnecessarily',
      () async {
        final service = FakeTorchService();
        final bloc = FlashLightBloc(torchService: service);
        addTearDown(bloc.close);

        await waitForAvailability(bloc, TorchAvailability.available);
        bloc.add(const CheckTorchAvailability());
        await Future<void>.delayed(Duration.zero);

        expect(service.availabilityCalls, 1);
      },
    );

    test('queued activation waits for availability confirmation', () async {
      final service = FakeTorchService()
        ..available = false
        ..availabilityGate = Completer<void>();
      final bloc = FlashLightBloc(torchService: service);
      addTearDown(bloc.close);

      bloc.add(const TurnOnFlashLight());
      service.availabilityGate!.complete();

      await waitForAvailability(bloc, TorchAvailability.unavailable);
      await Future<void>.delayed(Duration.zero);

      expect(service.enableCalls, 0);
      expect(bloc.state.isTorchOn, isFalse);
    });
  });

  group('activation', () {
    test('successfully enables the torch', () async {
      final service = FakeTorchService();
      final bloc = FlashLightBloc(torchService: service);
      addTearDown(bloc.close);

      await waitForAvailability(bloc, TorchAvailability.available);
      bloc.add(const TurnOnFlashLight());
      await waitForState(bloc, (state) => state.isTorchOn);

      expect(service.enableCalls, 1);
      expect(bloc.state.isBusy, isFalse);
      expect(bloc.state.error, isNull);
    });

    test('camera in use surfaces a cameraInUse error', () async {
      final service = FakeTorchService()
        ..enableError = const TorchFailure(TorchFailureKind.cameraInUse);
      final bloc = FlashLightBloc(torchService: service);
      addTearDown(bloc.close);

      await waitForAvailability(bloc, TorchAvailability.available);
      bloc.add(const TurnOnFlashLight());
      await waitForState(bloc, (state) => state.error != null);

      expect(bloc.state.error?.kind, TorchFailureKind.cameraInUse);
      expect(bloc.state.isTorchOn, isFalse);
      expect(bloc.state.isBusy, isFalse);
    });

    test('enable failure surfaces a retryable error and stays off', () async {
      final service = FakeTorchService()
        ..enableError = const TorchFailure(TorchFailureKind.enableFailed);
      final bloc = FlashLightBloc(torchService: service);
      addTearDown(bloc.close);

      await waitForAvailability(bloc, TorchAvailability.available);
      bloc.add(const TurnOnFlashLight());
      await waitForState(bloc, (state) => state.error != null);

      expect(bloc.state.error?.kind, TorchFailureKind.enableFailed);
      expect(bloc.state.isTorchOn, isFalse);
      expect(bloc.state.isBusy, isFalse);
    });

    test('unexpected activation exception is sanitized', () async {
      final service = FakeTorchService()
        ..enableError = Exception('native boom');
      final bloc = FlashLightBloc(torchService: service);
      addTearDown(bloc.close);

      await waitForAvailability(bloc, TorchAvailability.available);
      bloc.add(const TurnOnFlashLight());
      await waitForState(bloc, (state) => state.error != null);

      expect(bloc.state.error?.kind, TorchFailureKind.unexpected);
      expect(bloc.state.isTorchOn, isFalse);
    });
  });

  group('deactivation', () {
    Future<FlashLightBloc> turnedOnBloc(FakeTorchService service) async {
      final bloc = FlashLightBloc(torchService: service);
      await waitForAvailability(bloc, TorchAvailability.available);
      bloc.add(const TurnOnFlashLight());
      await waitForState(bloc, (state) => state.isTorchOn);
      return bloc;
    }

    test('successfully disables the torch', () async {
      final service = FakeTorchService();
      final bloc = await turnedOnBloc(service);
      addTearDown(bloc.close);

      bloc.add(const TurnOffFlashLight());
      await waitForState(bloc, (state) => !state.isTorchOn);

      expect(service.disableCalls, 1);
      expect(bloc.state.error, isNull);
      expect(bloc.state.isBusy, isFalse);
    });

    test(
      'disable failure keeps the last known on state and reports an error',
      () async {
        final service = FakeTorchService()
          ..disableError = const TorchFailure(TorchFailureKind.disableFailed);
        final bloc = await turnedOnBloc(service);
        addTearDown(bloc.close);

        bloc.add(const TurnOffFlashLight());
        await waitForState(bloc, (state) => state.error != null);

        expect(bloc.state.error?.kind, TorchFailureKind.disableFailed);
        expect(bloc.state.isTorchOn, isTrue);
        expect(bloc.state.isBusy, isFalse);
      },
    );

    test('unexpected deactivation exception is sanitized', () async {
      final service = FakeTorchService()
        ..disableError = Exception('native boom');
      final bloc = await turnedOnBloc(service);
      addTearDown(bloc.close);

      bloc.add(const TurnOffFlashLight());
      await waitForState(bloc, (state) => state.error != null);

      expect(bloc.state.error?.kind, TorchFailureKind.unexpected);
      expect(bloc.state.isTorchOn, isTrue);
    });
  });

  group('state', () {
    test('copyWith preserves existing values', () {
      const state = FlashLightState(
        availability: TorchAvailability.available,
        activeLight: LightMode.torch,
        isBusy: true,
        error: TorchFailure(TorchFailureKind.cameraInUse),
      );

      expect(state.copyWith(), state);
    });

    test('copyWith can clear the error explicitly', () {
      const state = FlashLightState(
        availability: TorchAvailability.available,
        error: TorchFailure(TorchFailureKind.enableFailed),
      );

      expect(state.copyWith(error: null).error, isNull);
    });

    test('copyWith keeps the error when it is not provided', () {
      const state = FlashLightState(
        availability: TorchAvailability.available,
        error: TorchFailure(TorchFailureKind.enableFailed),
      );

      expect(
        state.copyWith(isBusy: true).error,
        const TorchFailure(TorchFailureKind.enableFailed),
      );
    });

    test('becoming unavailable forces the torch off', () {
      const state = FlashLightState(
        availability: TorchAvailability.available,
        activeLight: LightMode.torch,
      );

      final next = state.copyWith(availability: TorchAvailability.unavailable);

      expect(next.isTorchOn, isFalse);
    });

    test('loading reflects checking and busy states', () {
      expect(const FlashLightState().isLoading, isTrue);
      expect(
        const FlashLightState(availability: TorchAvailability.checking)
            .isLoading,
        isTrue,
      );
      expect(
        const FlashLightState(
          availability: TorchAvailability.available,
          isBusy: true,
        ).isLoading,
        isTrue,
      );
      expect(
        const FlashLightState(availability: TorchAvailability.available)
            .isLoading,
        isFalse,
      );
    });
  });

  group('concurrency', () {
    test('rapid toggle requests never overlap hardware operations', () async {
      final service = FakeTorchService()..enableGate = Completer<void>();
      final bloc = FlashLightBloc(torchService: service);
      addTearDown(bloc.close);

      await waitForAvailability(bloc, TorchAvailability.available);
      bloc.add(const TurnOnFlashLight());
      await waitForState(bloc, (state) => state.isBusy);

      bloc.add(const TurnOffFlashLight());
      await Future<void>.delayed(Duration.zero);

      expect(service.enableCalls, 1);
      expect(service.disableCalls, 0);

      service.enableGate!.complete();
      await waitForState(bloc, (state) => !state.isBusy && !state.isTorchOn);

      expect(service.enableCalls, 1);
      expect(service.disableCalls, 1);
    });

    test('the final accepted operation determines the final state', () async {
      final service = FakeTorchService()..enableGate = Completer<void>();
      final bloc = FlashLightBloc(torchService: service);
      addTearDown(bloc.close);

      await waitForAvailability(bloc, TorchAvailability.available);
      bloc.add(const TurnOnFlashLight());
      await waitForState(bloc, (state) => state.isBusy);
      bloc.add(const TurnOffFlashLight());
      bloc.add(const TurnOnFlashLight());

      service.enableGate!.complete();
      await waitForState(bloc, (state) => state.isTorchOn && !state.isBusy);
      await Future<void>.delayed(Duration.zero);

      expect(service.enableCalls, 2);
      expect(service.disableCalls, 1);
      expect(bloc.state.isTorchOn, isTrue);
    });
  });

  group('lifecycle', () {
    test('backgrounding disables the torch exactly once', () async {
      final service = FakeTorchService();
      final bloc = FlashLightBloc(torchService: service);
      addTearDown(bloc.close);

      await waitForAvailability(bloc, TorchAvailability.available);
      bloc.add(const TurnOnFlashLight());
      await waitForState(bloc, (state) => state.isTorchOn);

      bloc.add(const AppPaused());
      await waitForState(bloc, (state) => !state.isTorchOn);

      bloc.add(const AppPaused());
      await Future<void>.delayed(Duration.zero);

      expect(service.disableCalls, 1);
    });

    test(
      'resume does not enable the torch or recheck when available',
      () async {
        final service = FakeTorchService();
        final bloc = FlashLightBloc(torchService: service);
        addTearDown(bloc.close);

        await waitForAvailability(bloc, TorchAvailability.available);
        bloc.add(const AppResumed());
        await Future<void>.delayed(Duration.zero);

        expect(service.enableCalls, 0);
        expect(service.availabilityCalls, 1);
        expect(bloc.state.isTorchOn, isFalse);
      },
    );

    test(
      'resume rechecks availability when it was unavailable but stays off',
      () async {
        final service = FakeTorchService()..available = false;
        final bloc = FlashLightBloc(torchService: service);
        addTearDown(bloc.close);

        await waitForAvailability(bloc, TorchAvailability.unavailable);
        service.available = true;

        bloc.add(const AppResumed());
        await waitForAvailability(bloc, TorchAvailability.available);

        expect(service.availabilityCalls, 2);
        expect(service.enableCalls, 0);
        expect(bloc.state.isTorchOn, isFalse);
      },
    );

    test('cleanup is safe when the torch is already off', () async {
      final service = FakeTorchService();
      final bloc = FlashLightBloc(torchService: service);
      addTearDown(bloc.close);

      await waitForAvailability(bloc, TorchAvailability.available);
      bloc.add(const AppDetached());
      await Future<void>.delayed(Duration.zero);

      expect(service.disableCalls, 0);
    });

    test('detached cleanup disables an active torch', () async {
      final service = FakeTorchService();
      final bloc = FlashLightBloc(torchService: service);
      addTearDown(bloc.close);

      await waitForAvailability(bloc, TorchAvailability.available);
      bloc.add(const TurnOnFlashLight());
      await waitForState(bloc, (state) => state.isTorchOn);

      bloc.add(const AppDetached());
      await waitForState(bloc, (state) => !state.isTorchOn);

      expect(service.disableCalls, 1);
    });
  });

  group('error clearing', () {
    test('clearing an error preserves the torch state', () async {
      final service = FakeTorchService()
        ..enableError = const TorchFailure(TorchFailureKind.cameraInUse);
      final bloc = FlashLightBloc(torchService: service);
      addTearDown(bloc.close);

      await waitForAvailability(bloc, TorchAvailability.available);
      bloc.add(const TurnOnFlashLight());
      await waitForState(bloc, (state) => state.error != null);

      bloc.add(const ClearFlashLightError());
      await waitForState(bloc, (state) => state.error == null);

      expect(bloc.state.isAvailable, isTrue);
      expect(bloc.state.isTorchOn, isFalse);
      expect(bloc.state.isBusy, isFalse);
    });
  });
}
