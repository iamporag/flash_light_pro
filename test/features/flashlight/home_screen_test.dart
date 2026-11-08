import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flash_light_pro/features/flashlight/services/torch_service.dart';
import 'package:flash_light_pro/flash_light_pro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_device_controls.dart';
import 'fake_settings_repository.dart';
import 'fake_torch_service.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  required FakeTorchService torch,
  FakeDeviceControls? deviceControls,
  FakeSettingsRepository? settings,
  Size? size,
}) async {
  if (size != null) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  await tester.pumpWidget(
    FlashLightPro(
      torchService: torch,
      deviceControls: deviceControls ?? FakeDeviceControls(),
      settingsRepository: settings ?? FakeSettingsRepository(),
    ),
  );
}

Future<void> tapPower(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('power-button')));
  await tester.pumpAndSettle();
}

InkWell powerInk(WidgetTester tester) =>
    tester.widget<InkWell>(find.byKey(const Key('power-button')));

void main() {
  testWidgets('shows a loading state while checking the torch', (tester) async {
    final torch = FakeTorchService()..availabilityGate = Completer<void>();
    await pumpApp(tester, torch: torch);
    await tester.pump();

    expect(find.text('Checking flashlight...'), findsOneWidget);
    expect(powerInk(tester).onTap, isNull);

    torch.availabilityGate!.complete();
    await tester.pumpAndSettle();

    expect(find.text('Flash Light Off'), findsOneWidget);
    expect(powerInk(tester).onTap, isNotNull);
  });

  testWidgets('devices without a torch show it in the UI without a dialog', (
    tester,
  ) async {
    final torch = FakeTorchService()..available = false;
    await pumpApp(tester, torch: torch);
    await tester.pumpAndSettle();

    expect(find.text('Flashlight not available'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(powerInk(tester).onTap, isNull);

    await tester.tap(find.byKey(const Key('mode-screenLight')));
    await tester.pumpAndSettle();

    expect(find.text('Screen Light Off'), findsOneWidget);
    expect(powerInk(tester).onTap, isNotNull);
  });

  testWidgets('shows one error dialog with retry and dismiss actions', (
    tester,
  ) async {
    final torch = FakeTorchService()
      ..enableError = const TorchFailure(TorchFailureKind.cameraInUse);
    await pumpApp(tester, torch: torch);
    await tester.pumpAndSettle();

    await tapPower(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Lighting Error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.byKey(const Key('error-dismiss')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Flash Light Off'), findsOneWidget);
  });

  testWidgets('backgrounding turns the torch off and resume keeps it off', (
    tester,
  ) async {
    final torch = FakeTorchService();
    await pumpApp(tester, torch: torch);
    await tester.pumpAndSettle();

    await tapPower(tester);
    expect(find.text('Flash Light On'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(torch.disableCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(torch.enableCalls, 1);
    expect(find.text('Flash Light Off'), findsOneWidget);
  });

  testWidgets('screen light opens full screen and restores on exit', (
    tester,
  ) async {
    final torch = FakeTorchService();
    final device = FakeDeviceControls();
    await pumpApp(tester, torch: torch, deviceControls: device);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mode-screenLight')));
    await tester.pumpAndSettle();
    await tapPower(tester);

    expect(find.byKey(const Key('screen-light-off')), findsOneWidget);
    expect(find.byKey(const Key('screen-brightness-slider')), findsOneWidget);
    expect(device.screenBrightnessCalls, 1);
    expect(device.lastKeepScreenOn, isTrue);

    await tester.tap(find.byKey(const Key('screen-light-off')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen-light-off')), findsNothing);
    expect(find.text('Screen Light Off'), findsOneWidget);
    expect(device.restoreCalls, 1);
    expect(device.lastKeepScreenOn, isFalse);
  });

  testWidgets('mode selector reveals each mode panel', (tester) async {
    final torch = FakeTorchService();
    await pumpApp(tester, torch: torch);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('torch-strength-slider')), findsNothing);
    expect(
      find.text('Torch strength is not supported on this device.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('mode-sos')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sos-pattern')), findsOneWidget);
    expect(find.text('... --- ...'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mode-strobe')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('strobe-warning')), findsOneWidget);
    expect(find.byKey(const Key('strobe-speed-slider')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mode-morse')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('morse-input')), findsOneWidget);
  });

  testWidgets('torch strength slider appears only when supported', (
    tester,
  ) async {
    final torch = FakeTorchService();
    final device = FakeDeviceControls()..levelSupported = true;
    await pumpApp(tester, torch: torch, deviceControls: device);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('torch-strength-slider')), findsOneWidget);
    expect(device.supportCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('Morse input previews valid text and flags unsupported chars', (
    tester,
  ) async {
    final torch = FakeTorchService();
    await pumpApp(tester, torch: torch);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mode-morse')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('morse-input')), 'SOS 123');
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(const Key('morse-preview'))).data,
      '... --- ... / .---- ..--- ...--',
    );
    expect(find.byKey(const Key('morse-unsupported')), findsNothing);

    await tester.enterText(find.byKey(const Key('morse-input')), 'SOS @');
    await tester.pump();

    expect(find.byKey(const Key('morse-unsupported')), findsOneWidget);
    expect(find.textContaining('Unsupported: @'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('morse-play')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('auto-off timer sheet sets and clears a preset', (tester) async {
    final torch = FakeTorchService();
    final settings = FakeSettingsRepository();
    await pumpApp(tester, torch: torch, settings: settings);
    await tester.pumpAndSettle();

    expect(
      tester.widget<IconButton>(find.byKey(const Key('timer-button'))).tooltip,
      'Auto-off off',
    );

    await tester.tap(find.byKey(const Key('timer-button')));
    await tester.pumpAndSettle();

    expect(find.text('Auto-off timer'), findsOneWidget);
    expect(find.byKey(const Key('timer-cancel')), findsNothing);

    await tester.tap(find.byKey(const Key('timer-preset-5')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<IconButton>(find.byKey(const Key('timer-button'))).tooltip,
      'Auto-off 5 min',
    );
    expect(settings.settings.timerPresetMinutes, 5);

    await tester.tap(find.byKey(const Key('timer-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('timer-cancel')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<IconButton>(find.byKey(const Key('timer-button'))).tooltip,
      'Auto-off off',
    );
    expect(settings.settings.timerPresetMinutes, isNull);
  });

  testWidgets('power button exposes on/off semantics', (tester) async {
    final handle = tester.ensureSemantics();

    final torch = FakeTorchService();
    await pumpApp(tester, torch: torch);
    await tester.pumpAndSettle();

    final offData = tester
        .getSemantics(find.byKey(const Key('power-button')))
        .getSemanticsData();
    expect(offData.label, 'Flash Light Off');
    expect(offData.flagsCollection.isButton, isTrue);
    expect(offData.flagsCollection.isToggled, Tristate.isFalse);
    expect(offData.flagsCollection.isEnabled, Tristate.isTrue);

    await tapPower(tester);

    final onData = tester
        .getSemantics(find.byKey(const Key('power-button')))
        .getSemanticsData();
    expect(onData.label, 'Flash Light On');
    expect(onData.flagsCollection.isToggled, Tristate.isTrue);

    handle.dispose();
  });

  testWidgets('lays out without overflow on a 320px phone', (tester) async {
    await pumpApp(
      tester,
      torch: FakeTorchService(),
      size: const Size(320, 640),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Flash Light Pro'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('mode-morse')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mode-morse')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byKey(const Key('morse-input')), 'SOS');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out without overflow in landscape', (tester) async {
    await pumpApp(
      tester,
      torch: FakeTorchService(),
      size: const Size(720, 360),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('power-button')), findsOneWidget);
  });
}
