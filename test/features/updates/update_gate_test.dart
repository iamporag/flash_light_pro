import 'dart:async';

import 'package:flash_light_pro/features/settings/data/app_settings.dart';
import 'package:flash_light_pro/features/settings/domain/app_language.dart';
import 'package:flash_light_pro/features/updates/application/update_cubit.dart';
import 'package:flash_light_pro/features/updates/domain/app_version.dart';
import 'package:flash_light_pro/features/updates/domain/update_config.dart';
import 'package:flash_light_pro/features/updates/domain/update_models.dart';
import 'package:flash_light_pro/flash_light_pro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flashlight/fake_device_controls.dart';
import '../flashlight/fake_settings_repository.dart';
import '../flashlight/fake_torch_service.dart';
import 'fakes.dart';

DateTime testNow() => DateTime(2026, 11, 6, 12);

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

UpdateConfig testConfig({
  Duration startupCheckDelay = const Duration(hours: 1),
  int bypassAfterFailedChecks = 2,
}) {
  return UpdateConfig(
    startupCheckDelay: startupCheckDelay,
    bypassAfterFailedChecks: bypassAfterFailedChecks,
  );
}

void main() {
  late FakeUpdateGateway gateway;
  late FakeUpdatePolicyStore store;
  late FakeStoreLauncher launcher;
  late FakeSettingsRepository settings;

  UpdateCubit cubitOf(WidgetTester tester) {
    return BlocProvider.of<UpdateCubit>(
      tester.element(find.byKey(const Key('power-button'))),
    );
  }

  Future<UpdateCubit> pumpApp(
    WidgetTester tester, {
    UpdateConfig? config,
    AppSettings appSettings = const AppSettings(),
  }) async {
    await tester.pumpWidget(
      FlashLightPro(
        torchService: FakeTorchService(),
        deviceControls: FakeDeviceControls(),
        settingsRepository: settings..settings = appSettings,
        updateGateway: gateway,
        updatePolicyStore: store,
        storeLauncher: launcher,
        updateConfig: config ?? testConfig(),
        updateCurrentVersion: const AppVersion(1, 2, 3, build: 10),
        updateClock: testNow,
      ),
    );
    await tester.pumpAndSettle();
    return cubitOf(tester);
  }

  Future<void> forceCheck(WidgetTester tester, UpdateCubit cubit) async {
    await cubit.checkForUpdate(force: true);
    await tester.pumpAndSettle();
  }

  setUp(() {
    gateway = FakeUpdateGateway();
    store = FakeUpdatePolicyStore();
    launcher = FakeStoreLauncher();
    settings = FakeSettingsRepository();
  });

  tearDown(() async {
    await gateway.close();
  });

  group('optional update prompt', () {
    testWidgets('appears after startup and can be dismissed for that build', (
      tester,
    ) async {
      gateway.info = available();
      final cubit = await pumpApp(
        tester,
        config: testConfig(startupCheckDelay: Duration.zero),
      );

      expect(cubit.state.phase, UpdatePhase.available);
      expect(find.byKey(const Key('update-dialog')), findsOneWidget);
      expect(find.text('New Update Available'), findsOneWidget);
      expect(find.text('Installed: 1.2.3+10'), findsOneWidget);
      expect(find.text('Available build: 11'), findsOneWidget);
      expect(find.byKey(const Key('update-now')), findsOneWidget);
      expect(find.byKey(const Key('update-later')), findsOneWidget);

      await tester.tap(find.byKey(const Key('update-later')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('update-dialog')), findsNothing);
      expect(store.dismissedVersionCode, 11);

      await forceCheck(tester, cubit);
      expect(find.byKey(const Key('update-dialog')), findsNothing);

      gateway.info = available(versionCode: 12);
      await forceCheck(tester, cubit);

      expect(find.byKey(const Key('update-dialog')), findsOneWidget);
      expect(find.text('Available build: 12'), findsOneWidget);
    });

    testWidgets('system back dismisses it and remembers the build', (
      tester,
    ) async {
      gateway.info = available();
      final cubit = await pumpApp(
        tester,
        config: testConfig(startupCheckDelay: Duration.zero),
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('update-dialog')), findsNothing);
      expect(store.dismissedVersionCode, 11);

      await forceCheck(tester, cubit);
      expect(find.byKey(const Key('update-dialog')), findsNothing);
    });

    testWidgets('recommended updates stay dismissible and say so', (
      tester,
    ) async {
      gateway.info = available(priority: 3);
      await pumpApp(
        tester,
        config: testConfig(startupCheckDelay: Duration.zero),
      );

      expect(find.text('Update Recommended'), findsOneWidget);
      expect(find.byKey(const Key('update-later')), findsOneWidget);
      expect(find.byKey(const Key('update-bypass')), findsNothing);
    });

    testWidgets('waits while a light is active, including SOS patterns', (
      tester,
    ) async {
      final cubit = await pumpApp(tester);

      await tester.tap(find.byKey(const Key('mode-sos')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('power-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sos-pattern')), findsOneWidget);

      gateway.info = available();
      await forceCheck(tester, cubit);

      expect(find.byKey(const Key('update-dialog')), findsNothing);

      await tester.tap(find.byKey(const Key('power-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('update-dialog')), findsOneWidget);
    });

    testWidgets('does not prompt when Play reports no update', (tester) async {
      await pumpApp(
        tester,
        config: testConfig(startupCheckDelay: Duration.zero),
      );

      expect(find.byKey(const Key('update-dialog')), findsNothing);
      expect(gateway.checkCalls, 1);
    });

    testWidgets('repeated checks never stack a second dialog', (tester) async {
      gateway.info = available();
      final cubit = await pumpApp(
        tester,
        config: testConfig(startupCheckDelay: Duration.zero),
      );

      expect(find.byType(Dialog), findsOneWidget);

      await forceCheck(tester, cubit);
      await forceCheck(tester, cubit);

      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('lays out on a 320px phone in Bengali without overflow', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      gateway.info = available(priority: 5);
      await pumpApp(
        tester,
        config: testConfig(startupCheckDelay: Duration.zero),
        appSettings: const AppSettings(appLanguage: AppLanguage.bengali),
      );

      expect(find.byKey(const Key('update-dialog')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('mandatory update prompt', () {
    testWidgets('cannot be dismissed with back or a barrier tap', (
      tester,
    ) async {
      gateway.info = available(priority: 5, immediate: true);
      await pumpApp(
        tester,
        config: testConfig(startupCheckDelay: Duration.zero),
      );

      expect(find.text('Update Required'), findsOneWidget);
      expect(find.byKey(const Key('update-later')), findsNothing);
      expect(find.byKey(const Key('update-close')), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('update-dialog')), findsOneWidget);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('update-dialog')), findsOneWidget);
    });

    testWidgets('runs the immediate flow and confirms installation', (
      tester,
    ) async {
      gateway.info = available(priority: 5, immediate: true);
      await pumpApp(
        tester,
        config: testConfig(startupCheckDelay: Duration.zero),
      );

      await tester.tap(find.byKey(const Key('update-now')));
      await tester.pumpAndSettle();

      expect(gateway.immediateCalls, 1);
      expect(gateway.flexibleCalls, 0);
      expect(
        find.text(
          'The update is installed. Restart the app if it does not reopen '
          'automatically.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('update-close')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('update-dialog')), findsNothing);
    });

    testWidgets('offers the Play Store when no in-app flow is allowed', (
      tester,
    ) async {
      gateway.info = available(priority: 5, immediate: false, flexible: false);
      await pumpApp(
        tester,
        config: testConfig(startupCheckDelay: Duration.zero),
      );

      await tester.tap(find.byKey(const Key('update-now')));
      await tester.pumpAndSettle();

      expect(gateway.immediateCalls, 0);
      expect(gateway.flexibleCalls, 0);
      expect(launcher.opened, hasLength(1));
      expect(
        launcher.opened.single.toString(),
        'https://play.google.com/store/apps/details'
        '?id=com.claudysoft.flashlightpro',
      );
    });

    testWidgets(
      'a cached mandatory policy survives an outage and can be bypassed',
      (tester) async {
        final now = testNow();
        store.policy = TrustedUpdatePolicy(
          urgency: UpdateUrgency.mandatory,
          verifiedAt: now.subtract(const Duration(hours: 1)),
          availableVersionCode: 11,
          updatePriority: 5,
        );
        gateway.checkError = PlatformException(code: 'unavailable');

        await pumpApp(
          tester,
          config: testConfig(
            startupCheckDelay: Duration.zero,
            bypassAfterFailedChecks: 1,
          ),
        );

        expect(find.text('Update Required'), findsOneWidget);
        expect(
          find.text(
            'This update was verified earlier. Reconnect to confirm it.',
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('update-retry')), findsOneWidget);
        expect(find.byKey(const Key('update-bypass')), findsOneWidget);

        await tester.ensureVisible(find.byKey(const Key('update-bypass')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('update-bypass')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('update-dialog')), findsNothing);
        expect(find.text('Flash Light Off'), findsOneWidget);

        await tester.tap(find.byKey(const Key('power-button')));
        await tester.pumpAndSettle();
        expect(find.text('Flash Light On'), findsOneWidget);
      },
    );

    testWidgets('retry rechecks Play and recovers the in-app flow', (
      tester,
    ) async {
      final now = testNow();
      store.policy = TrustedUpdatePolicy(
        urgency: UpdateUrgency.mandatory,
        verifiedAt: now.subtract(const Duration(hours: 1)),
        availableVersionCode: 11,
        updatePriority: 5,
      );
      gateway.checkError = PlatformException(code: 'unavailable');

      await pumpApp(
        tester,
        config: testConfig(startupCheckDelay: Duration.zero),
      );

      expect(find.byKey(const Key('update-retry')), findsOneWidget);

      gateway.checkError = null;
      gateway.info = available(priority: 5, immediate: true);

      await tester.tap(find.byKey(const Key('update-retry')));
      await tester.pumpAndSettle();

      expect(gateway.checkCalls, 2);
      expect(find.byKey(const Key('update-now')), findsOneWidget);
      expect(find.byKey(const Key('update-retry')), findsNothing);

      await tester.tap(find.byKey(const Key('update-now')));
      await tester.pumpAndSettle();

      expect(gateway.immediateCalls, 1);
    });
  });

  group('flexible update', () {
    testWidgets('downloads in the background and offers Install when ready', (
      tester,
    ) async {
      final download = Completer<UpdateFlowResult>();
      gateway
        ..info = available()
        ..flexibleCompleter = download;

      final cubit = await pumpApp(
        tester,
        config: testConfig(startupCheckDelay: Duration.zero),
      );

      expect(find.byKey(const Key('update-dialog')), findsOneWidget);

      await tester.tap(find.byKey(const Key('update-now')));
      await tester.pump();

      expect(gateway.flexibleCalls, 1);
      expect(cubit.state.phase, UpdatePhase.downloading);
      expect(find.byKey(const Key('update-hide')), findsOneWidget);

      await tester.tap(find.byKey(const Key('update-hide')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('update-dialog')), findsNothing);

      download.complete(UpdateFlowResult.success);
      await tester.pumpAndSettle();

      expect(cubit.state.phase, UpdatePhase.downloaded);
      expect(find.byKey(const Key('update-dialog')), findsNothing);
      expect(find.text('Update ready to install.'), findsOneWidget);

      await tester.tap(find.widgetWithText(SnackBarAction, 'Install'));
      await tester.pumpAndSettle();

      expect(gateway.completeCalls, 1);
      expect(cubit.state.phase, UpdatePhase.installing);
    });

    testWidgets('a canceled download returns a retryable prompt', (
      tester,
    ) async {
      gateway
        ..info = available()
        ..flexibleResult = UpdateFlowResult.userDenied;
      final cubit = await pumpApp(
        tester,
        config: testConfig(startupCheckDelay: Duration.zero),
      );

      await tester.tap(find.byKey(const Key('update-now')));
      await tester.pumpAndSettle();

      expect(cubit.state.phase, UpdatePhase.available);
      expect(cubit.state.failure, UpdateFailure.userCanceled);
      expect(find.text('The update was canceled.'), findsOneWidget);
      expect(find.byKey(const Key('update-retry')), findsOneWidget);

      await tester.tap(find.byKey(const Key('update-later')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('update-dialog')), findsNothing);
      expect(store.dismissedVersionCode, 11);
    });

    testWidgets('a failed download surfaces an error inside the dialog', (
      tester,
    ) async {
      gateway
        ..info = available()
        ..flexibleResult = UpdateFlowResult.failed;
      final cubit = await pumpApp(
        tester,
        config: testConfig(startupCheckDelay: Duration.zero),
      );

      await tester.tap(find.byKey(const Key('update-now')));
      await tester.pumpAndSettle();

      expect(cubit.state.phase, UpdatePhase.available);
      expect(cubit.state.failure, UpdateFailure.installFailed);
      expect(
        find.text(
          'Google Play could not start the update. Check your connection '
          'and try again.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('update-retry')), findsOneWidget);
    });
  });

  group('lifecycle and settings', () {
    testWidgets('rechecks after returning from the Play Store', (tester) async {
      gateway.info = available(immediate: false, flexible: false);
      final cubit = await pumpApp(
        tester,
        config: testConfig(startupCheckDelay: Duration.zero),
      );

      await tester.tap(find.byKey(const Key('update-now')));
      await tester.pumpAndSettle();
      expect(launcher.opened, hasLength(1));
      expect(gateway.checkCalls, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(gateway.checkCalls, 2);
      expect(cubit.state.phase, UpdatePhase.available);
    });

    testWidgets('settings offers a manual check and update action', (
      tester,
    ) async {
      await pumpApp(tester, config: testConfig());

      await tester.tap(find.byKey(const Key('settings-button')));
      await tester.pumpAndSettle();

      final scroll = find.descendant(
        of: find.byKey(const Key('settings-scroll')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('settings-updates')),
        250,
        scrollable: scroll,
      );
      await tester.pumpAndSettle();

      expect(find.text('App updates'), findsWidgets);
      expect(find.text("You're using the latest version"), findsOneWidget);

      gateway.info = available();
      await tester.tap(find.byKey(const Key('settings-updates-action')));
      await tester.pumpAndSettle();

      expect(gateway.checkCalls, 1);
      expect(find.text('Update available (build 11)'), findsOneWidget);
      expect(find.byKey(const Key('update-dialog')), findsOneWidget);

      await tester.tap(find.byKey(const Key('update-later')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('update-dialog')), findsNothing);

      await tester.tap(find.byKey(const Key('settings-updates-action')));
      await tester.pumpAndSettle();

      expect(gateway.flexibleCalls, 1);
    });
  });
}
