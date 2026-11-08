import 'dart:async';

import 'package:flash_light_pro/features/updates/application/update_cubit.dart';
import 'package:flash_light_pro/features/updates/domain/app_version.dart';
import 'package:flash_light_pro/features/updates/domain/update_config.dart';
import 'package:flash_light_pro/features/updates/domain/update_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

UpdateInfo available({
  int versionCode = 11,
  int priority = 0,
  bool immediate = false,
  bool flexible = true,
}) {
  return UpdateInfo(
    availability: UpdateAvailability.available,
    availableVersionCode: versionCode,
    updatePriority: priority,
    immediateAllowed: immediate,
    flexibleAllowed: flexible,
  );
}

void main() {
  late FakeUpdateGateway gateway;
  late FakeUpdatePolicyStore store;
  late FakeStoreLauncher launcher;
  late DateTime now;
  late UpdateCubit cubit;

  UpdateCubit createCubit({
    UpdateConfig config = const UpdateConfig(),
    AppVersion currentVersion = const AppVersion(1, 2, 3, build: 10),
  }) {
    return UpdateCubit(
      gateway: gateway,
      store: store,
      storeLauncher: launcher,
      config: config,
      currentVersion: currentVersion,
      clock: () => now,
    );
  }

  setUp(() {
    gateway = FakeUpdateGateway();
    store = FakeUpdatePolicyStore();
    launcher = FakeStoreLauncher();
    now = DateTime(2026, 11, 6, 12);
    cubit = createCubit(
      config: const UpdateConfig(recheckInterval: Duration(hours: 6)),
    );
  });

  tearDown(() async {
    await cubit.close();
    await gateway.close();
  });

  group('availability checks', () {
    test('does nothing on platforms without the Play API', () async {
      gateway.isSupported = false;
      await cubit.close();
      cubit = createCubit();

      await cubit.checkForUpdate();

      expect(cubit.state.isSupported, isFalse);
      expect(gateway.checkCalls, 0);
      expect(cubit.state.shouldPrompt, isFalse);
    });

    test('reports an optional update', () async {
      gateway.info = available();

      await cubit.checkForUpdate();

      expect(cubit.state.urgency, UpdateUrgency.optional);
      expect(cubit.state.availableVersionCode, 11);
      expect(cubit.state.shouldPrompt, isTrue);
      expect(cubit.state.failure, isNull);
    });

    test('clears a cached policy when Play reports no update', () async {
      store.policy = TrustedUpdatePolicy(
        urgency: UpdateUrgency.mandatory,
        verifiedAt: now.subtract(const Duration(hours: 1)),
        availableVersionCode: 10,
      );
      gateway.info = const UpdateInfo(
        availability: UpdateAvailability.unavailable,
      );

      await cubit.checkForUpdate();

      expect(cubit.state.phase, UpdatePhase.upToDate);
      expect(cubit.state.urgency, UpdateUrgency.none);
      expect(store.policy, isNull);
    });

    test('resumes an in-progress downloaded flexible update', () async {
      store.policy = TrustedUpdatePolicy(
        urgency: UpdateUrgency.optional,
        verifiedAt: now.subtract(const Duration(minutes: 5)),
        availableVersionCode: 11,
      );
      gateway.info = const UpdateInfo(
        availability: UpdateAvailability.inProgress,
        availableVersionCode: 11,
        flexibleAllowed: true,
        installStatus: UpdateInstallStatus.downloaded,
      );

      await cubit.checkForUpdate();

      expect(cubit.state.phase, UpdatePhase.downloaded);
      expect(cubit.state.isReadyToInstall, isTrue);
      expect(cubit.state.urgency, UpdateUrgency.optional);
    });

    test('coalesces duplicate checks', () async {
      gateway.checkDelay = const Duration(milliseconds: 20);

      await Future.wait([
        cubit.checkForUpdate(),
        cubit.checkForUpdate(),
        cubit.checkForUpdate(),
      ]);

      expect(gateway.checkCalls, 1);
    });

    test('throttles repeated checks but allows a forced check', () async {
      await cubit.checkForUpdate();
      expect(gateway.checkCalls, 1);

      now = now.add(const Duration(hours: 1));
      await cubit.checkForUpdate();
      expect(gateway.checkCalls, 1);

      await cubit.checkForUpdate(force: true);
      expect(gateway.checkCalls, 2);
    });
  });

  group('failure handling', () {
    test('a timeout does not force an update', () async {
      gateway.checkError = TimeoutException('no response');

      await cubit.checkForUpdate();

      expect(cubit.state.failure, UpdateFailure.timeout);
      expect(cubit.state.urgency, UpdateUrgency.none);
      expect(cubit.state.shouldPrompt, isFalse);
    });

    test('a Play Store failure does not force an update', () async {
      gateway.checkError = PlatformException(code: 'ERROR_API_NOT_AVAILABLE');

      await cubit.checkForUpdate();

      expect(cubit.state.failure, UpdateFailure.playStoreUnavailable);
      expect(cubit.state.shouldPrompt, isFalse);
    });

    test('a fresh cached mandatory policy survives an offline check', () async {
      store.policy = TrustedUpdatePolicy(
        urgency: UpdateUrgency.mandatory,
        verifiedAt: now.subtract(const Duration(hours: 1)),
        availableVersionCode: 11,
        updatePriority: 5,
      );
      gateway.checkError = Exception('offline');

      await cubit.checkForUpdate();

      expect(cubit.state.urgency, UpdateUrgency.mandatory);
      expect(cubit.state.fromCache, isTrue);
      expect(cubit.state.shouldPrompt, isTrue);
      expect(cubit.state.canBypass, isFalse);
    });

    test('a cached mandatory policy expires', () async {
      store.policy = TrustedUpdatePolicy(
        urgency: UpdateUrgency.mandatory,
        verifiedAt: now.subtract(const Duration(hours: 73)),
        availableVersionCode: 11,
      );
      gateway.checkError = Exception('offline');

      await cubit.checkForUpdate();

      expect(cubit.state.shouldPrompt, isFalse);
      expect(cubit.state.urgency, UpdateUrgency.none);
    });

    test('repeated failed checks enable a temporary bypass', () async {
      store.policy = TrustedUpdatePolicy(
        urgency: UpdateUrgency.mandatory,
        verifiedAt: now.subtract(const Duration(hours: 1)),
        availableVersionCode: 11,
      );
      gateway.checkError = Exception('offline');

      await cubit.checkForUpdate();
      expect(cubit.state.canBypass, isFalse);

      await cubit.checkForUpdate(force: true);
      expect(cubit.state.canBypass, isTrue);

      cubit.continueWithoutUpdating();
      expect(cubit.state.shouldPrompt, isFalse);
      expect(cubit.state.bypassedForVersion, isTrue);
    });

    test('an offline local minimum never blocks the flashlight', () async {
      await cubit.close();
      cubit = createCubit(
        config: const UpdateConfig(minimumSupportedVersion: '2.0.0'),
      );
      gateway.checkError = Exception('offline');

      await cubit.checkForUpdate();

      expect(cubit.state.urgency, UpdateUrgency.none);
      expect(cubit.state.shouldPrompt, isFalse);
    });

    test('a failed check keeps a previously established prompt', () async {
      gateway.info = available();
      await cubit.checkForUpdate();
      expect(cubit.state.urgency, UpdateUrgency.optional);

      gateway.checkError = Exception('offline');
      await cubit.checkForUpdate(force: true);

      expect(cubit.state.urgency, UpdateUrgency.optional);
      expect(cubit.state.shouldPrompt, isTrue);
      expect(cubit.state.failure, UpdateFailure.unknown);
    });
  });

  group('policy levels', () {
    test(
      'Play update priority produces recommended and mandatory levels',
      () async {
        gateway.info = available(priority: 3);
        await cubit.checkForUpdate();
        expect(cubit.state.urgency, UpdateUrgency.recommended);

        gateway.info = available(priority: 5);
        await cubit.checkForUpdate(force: true);
        expect(cubit.state.urgency, UpdateUrgency.mandatory);
      },
    );

    test(
      'a compiled minimum is mandatory only when Play confirms an update',
      () async {
        await cubit.close();
        cubit = createCubit(
          config: const UpdateConfig(minimumSupportedVersion: '2.0.0'),
        );
        gateway.info = available(priority: 0);

        await cubit.checkForUpdate();

        expect(cubit.state.urgency, UpdateUrgency.mandatory);
      },
    );
  });

  group('dismissal', () {
    test(
      'remembers a dismissal for the same version and prompts for a newer one',
      () async {
        gateway.info = available();
        await cubit.checkForUpdate();

        await cubit.dismissOptional();
        expect(store.dismissedVersionCode, 11);
        expect(cubit.state.shouldPrompt, isFalse);

        await cubit.checkForUpdate(force: true);
        expect(cubit.state.shouldPrompt, isFalse);

        gateway.info = available(versionCode: 12);
        await cubit.checkForUpdate(force: true);
        expect(cubit.state.shouldPrompt, isTrue);
      },
    );

    test('mandatory updates ignore dismissal', () async {
      gateway.info = available(priority: 5);
      await cubit.checkForUpdate();

      await cubit.dismissOptional();

      expect(cubit.state.dismissedForVersion, isFalse);
      expect(cubit.state.shouldPrompt, isTrue);
    });
  });

  group('flexible updates', () {
    test('tracks download, install, and completion', () async {
      gateway.info = available(flexible: true);
      gateway.flexibleCompleter = Completer<UpdateFlowResult>();
      await cubit.checkForUpdate();

      final start = cubit.startUpdate();
      await pumpEventQueue();
      expect(gateway.flexibleCalls, 1);
      expect(cubit.state.phase, UpdatePhase.downloading);

      gateway.emitInstallStatus(UpdateInstallStatus.downloaded);
      expect(cubit.state.phase, UpdatePhase.downloaded);

      gateway.flexibleCompleter!.complete(UpdateFlowResult.success);
      await start;
      expect(cubit.state.phase, UpdatePhase.downloaded);

      await cubit.installFlexibleUpdate();
      expect(gateway.completeCalls, 1);
      expect(cubit.state.phase, UpdatePhase.installing);

      gateway.emitInstallStatus(UpdateInstallStatus.installed);
      expect(cubit.state.phase, UpdatePhase.installed);
    });

    test('surfaces a canceled download as a retryable prompt', () async {
      gateway.info = available(flexible: true);
      gateway.flexibleResult = UpdateFlowResult.userDenied;
      await cubit.checkForUpdate();

      await cubit.startUpdate();

      expect(cubit.state.phase, UpdatePhase.available);
      expect(cubit.state.failure, UpdateFailure.userCanceled);
      expect(cubit.state.shouldPrompt, isTrue);
    });

    test('surfaces a failed download', () async {
      gateway.info = available(flexible: true);
      gateway.flexibleResult = UpdateFlowResult.failed;
      await cubit.checkForUpdate();

      await cubit.startUpdate();

      expect(cubit.state.failure, UpdateFailure.installFailed);
      expect(cubit.state.shouldPrompt, isTrue);
    });
  });

  group('immediate updates', () {
    test('runs immediate only for a mandatory update', () async {
      gateway.info = available(priority: 5, immediate: true, flexible: true);
      gateway.immediateCompleter = Completer<UpdateFlowResult>();
      await cubit.checkForUpdate();

      final start = cubit.startUpdate();
      await pumpEventQueue();

      expect(gateway.immediateCalls, 1);
      expect(gateway.flexibleCalls, 0);
      expect(cubit.state.phase, UpdatePhase.installing);

      gateway.immediateCompleter!.complete(UpdateFlowResult.userDenied);
      await start;

      expect(cubit.state.phase, UpdatePhase.available);
      expect(cubit.state.failure, UpdateFailure.userCanceled);
      expect(cubit.state.shouldPrompt, isTrue);
    });

    test('a successful immediate update finishes the prompt', () async {
      gateway.info = available(priority: 5, immediate: true);
      await cubit.checkForUpdate();

      await cubit.startUpdate();

      expect(gateway.immediateCalls, 1);
      expect(cubit.state.phase, UpdatePhase.installed);
      expect(cubit.state.shouldPrompt, isFalse);
    });

    test('falls back to flexible when immediate is not allowed', () async {
      gateway.info = available(priority: 5, immediate: false, flexible: true);
      await cubit.checkForUpdate();

      await cubit.startUpdate();

      expect(gateway.immediateCalls, 0);
      expect(gateway.flexibleCalls, 1);
    });

    test(
      'falls back to the Play Store when no in-app flow is allowed',
      () async {
        gateway.info = available(
          priority: 5,
          immediate: false,
          flexible: false,
        );
        await cubit.checkForUpdate();

        await cubit.startUpdate();

        expect(gateway.flexibleCalls, 0);
        expect(
          launcher.opened.single.toString(),
          'https://play.google.com/store/apps/details?id=io.github.iamporag.flashlightpro',
        );
      },
    );
  });

  group('Play Store navigation', () {
    test('uses the actual Android application id', () async {
      await cubit.openStore();

      expect(
        launcher.opened.single.toString(),
        'https://play.google.com/store/apps/details?id=io.github.iamporag.flashlightpro',
      );
    });

    test('reports a store launch failure', () async {
      launcher.openResult = false;

      await cubit.openStore();

      expect(cubit.state.failure, UpdateFailure.openStoreFailed);
    });

    test('rechecks after returning from the store', () async {
      await cubit.checkForUpdate();
      expect(gateway.checkCalls, 1);

      now = now.add(const Duration(minutes: 5));
      await cubit.openStore();
      await cubit.onAppResumed();

      expect(gateway.checkCalls, 2);
    });

    test('optional updates with no flexible flow open the store', () async {
      gateway.info = available(flexible: false);
      await cubit.checkForUpdate();

      await cubit.startUpdate();

      expect(launcher.opened, hasLength(1));
    });
  });
}
