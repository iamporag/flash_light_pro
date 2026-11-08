import 'package:flash_light_pro/features/flashlight/services/background_torch_service.dart';
import 'package:flash_light_pro/features/settings/data/app_settings.dart';
import 'package:flash_light_pro/features/shake/domain/shake_sensitivity.dart';
import 'package:flash_light_pro/features/shake/services/shake_monitor_service.dart';
import 'package:flash_light_pro/features/lighting/domain/light_mode.dart';
import 'package:flash_light_pro/flash_light_pro.dart';
import 'package:flash_light_pro/src/presentation/screens/settings/privacy_policy_page.dart';
import 'package:flash_light_pro/src/presentation/screens/settings/terms_and_conditions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flashlight/fake_background_torch_service.dart';
import '../flashlight/fake_device_controls.dart';
import '../flashlight/fake_settings_repository.dart';
import '../flashlight/fake_shake_monitor_service.dart';
import '../flashlight/fake_shake_service.dart';
import '../flashlight/fake_torch_service.dart';
import '../flashlight/fake_torch_state_source.dart';

Future<FakeSettingsRepository> pumpSettings(
  WidgetTester tester, {
  AppSettings settings = const AppSettings(),
  BackgroundTorchService? backgroundService,
  ShakeMonitorService? shakeMonitorService,
}) async {
  final repository = FakeSettingsRepository(settings);
  await tester.pumpWidget(
    FlashLightPro(
      torchService: FakeTorchService(),
      deviceControls: FakeDeviceControls(),
      settingsRepository: repository,
      shakeService: FakeShakeService(),
      shakeMonitorService: shakeMonitorService,
      torchStateSource: FakeTorchStateSource(),
      backgroundTorchService:
          backgroundService ?? const UnsupportedBackgroundTorchService(),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('settings-button')));
  await tester.pumpAndSettle();
  return repository;
}

Finder settingsScrollable() => find.descendant(
  of: find.byKey(const Key('settings-scroll')),
  matching: find.byType(Scrollable),
);

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: settingsScrollable(),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens from home and shows the settings sections', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Shake to toggle'), findsOneWidget);
    expect(find.byKey(const Key('settings-language-en')), findsOneWidget);
    expect(find.byKey(const Key('settings-language-bn')), findsOneWidget);

    await reveal(tester, find.byKey(const Key('settings-default-mode')));
    expect(find.text('Default mode'), findsOneWidget);

    await reveal(tester, find.byKey(const Key('settings-privacy')));
    expect(find.text('About'), findsOneWidget);
    expect(find.textContaining('Version '), findsOneWidget);
  });

  testWidgets('switches update state and persist every choice', (tester) async {
    final repository = await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('settings-haptics')));
    await tester.pumpAndSettle();
    expect(repository.saved.last.hapticsEnabled, isFalse);

    await tester.tap(find.byKey(const Key('settings-reduce-animations')));
    await tester.pumpAndSettle();
    expect(repository.saved.last.reduceAnimations, isTrue);

    await reveal(tester, find.byKey(const Key('settings-shake')));
    await tester.tap(find.byKey(const Key('settings-shake')));
    await tester.pumpAndSettle();

    expect(repository.saved.last.shakeEnabled, isTrue);
    expect(find.byKey(const Key('settings-sensitivity-high')), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-sensitivity-high')));
    await tester.pumpAndSettle();
    expect(repository.saved.last.shakeSensitivity, ShakeSensitivity.high);

    await tester.tap(find.byKey(const Key('settings-shake')));
    await tester.pumpAndSettle();
    expect(repository.saved.last.shakeEnabled, isFalse);
    expect(find.byKey(const Key('settings-sensitivity-high')), findsNothing);

    await reveal(tester, find.byKey(const Key('settings-keep-awake')));
    await tester.tap(find.byKey(const Key('settings-keep-awake')));
    await tester.pumpAndSettle();
    expect(repository.saved.last.keepScreenAwake, isFalse);
  });

  testWidgets('the default operating mode can be changed', (tester) async {
    final repository = await pumpSettings(tester);

    await reveal(tester, find.byKey(const Key('settings-default-mode')));
    await tester.tap(find.byKey(const Key('settings-default-mode')));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(DropdownMenuItem<LightMode>, 'Morse'));
    await tester.pumpAndSettle();

    expect(repository.saved.last.selectedMode, LightMode.morse);
  });

  testWidgets('the privacy policy and open-source licenses open', (
    tester,
  ) async {
    await pumpSettings(tester);

    await reveal(tester, find.byKey(const Key('settings-privacy')));
    await tester.tap(find.byKey(const Key('settings-privacy')));
    await tester.pumpAndSettle();

    expect(find.text('Privacy policy'), findsWidgets);
    expect(find.text('Data stored on your device'), findsOneWidget);

    final privacyScrollable = find.descendant(
      of: find.byType(PrivacyPolicyPage),
      matching: find.byType(Scrollable),
    );

    await tester.scrollUntilVisible(
      find.text('Advertising'),
      250,
      scrollable: privacyScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Advertising'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Remove ads purchase'),
      250,
      scrollable: privacyScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Remove ads purchase'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('No analytics or crash uploads'),
      250,
      scrollable: privacyScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('No analytics or crash uploads'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await reveal(tester, find.byKey(const Key('settings-licenses')));
    await tester.tap(find.byKey(const Key('settings-licenses')));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('the terms and conditions page opens from settings', (
    tester,
  ) async {
    await pumpSettings(tester);

    await reveal(tester, find.byKey(const Key('settings-terms')));
    await tester.tap(find.byKey(const Key('settings-terms')));
    await tester.pumpAndSettle();

    expect(find.byType(TermsAndConditionsPage), findsOneWidget);
    expect(find.text('Terms and conditions'), findsOneWidget);
    expect(find.text('Effective 8 November 2026'), findsOneWidget);
    expect(find.text('Licence to use the app'), findsOneWidget);

    final termsScrollable = find.descendant(
      of: find.byType(TermsAndConditionsPage),
      matching: find.byType(Scrollable),
    );

    await tester.scrollUntilVisible(
      find.text('Disclaimers and liability'),
      250,
      scrollable: termsScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Disclaimers and liability'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-scroll')), findsOneWidget);
  });

  testWidgets('the background setting is honest about platform support', (
    tester,
  ) async {
    await pumpSettings(tester);

    await reveal(tester, find.byKey(const Key('settings-background-torch')));

    expect(find.text('Keep Flashlight On in Background'), findsOneWidget);
    final tile = tester.widget<SwitchListTile>(
      find.byKey(const Key('settings-background-torch')),
    );
    expect(tile.onChanged, isNull);
    expect(find.textContaining('Not available on iOS'), findsOneWidget);
  });

  testWidgets('enabling background mode persists and requests notifications', (
    tester,
  ) async {
    final background = FakeBackgroundTorchService();
    addTearDown(background.dispose);
    final repository = await pumpSettings(
      tester,
      settings: const AppSettings(backgroundTorchEnabled: false),
      backgroundService: background,
    );

    await reveal(tester, find.byKey(const Key('settings-background-torch')));
    await tester.tap(find.byKey(const Key('settings-background-torch')));
    await tester.pumpAndSettle();

    expect(repository.saved.last.backgroundTorchEnabled, isTrue);
    expect(background.requestPermissionCalls, 1);
  });

  testWidgets('enabling shake starts background monitoring and explains it', (
    tester,
  ) async {
    final monitor = FakeShakeMonitorService();
    addTearDown(monitor.dispose);
    await pumpSettings(tester, shakeMonitorService: monitor);

    await reveal(tester, find.byKey(const Key('settings-shake')));
    await tester.tap(find.byKey(const Key('settings-shake')));
    await tester.pumpAndSettle();

    expect(monitor.startCalls, 1);

    await reveal(tester, find.textContaining('Background monitoring is on'));
    expect(
      find.text(
        'Shake your phone to turn the flashlight on or off, even when the app is in the background.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('persistent notification'), findsOneWidget);
  });

  testWidgets('denied notifications are explained without disabling shake', (
    tester,
  ) async {
    final monitor = FakeShakeMonitorService(notificationsEnabled: false);
    addTearDown(monitor.dispose);
    await pumpSettings(tester, shakeMonitorService: monitor);

    await reveal(tester, find.byKey(const Key('settings-shake')));
    await tester.tap(find.byKey(const Key('settings-shake')));
    await tester.pumpAndSettle();

    expect(monitor.requestPermissionCalls, 1);
    expect(monitor.startCalls, 1);

    await reveal(tester, find.textContaining('Notifications are off'));
    expect(find.textContaining('Monitoring still runs'), findsOneWidget);
  });

  testWidgets('devices without the native service say so honestly', (
    tester,
  ) async {
    final monitor = FakeShakeMonitorService(supported: false);
    addTearDown(monitor.dispose);
    await pumpSettings(
      tester,
      settings: const AppSettings(shakeEnabled: true),
      shakeMonitorService: monitor,
    );

    await reveal(tester, find.byKey(const Key('settings-shake')));
    await reveal(
      tester,
      find.textContaining('does not support background shake monitoring'),
    );

    expect(monitor.startCalls, 0);
    expect(find.byKey(const Key('settings-sensitivity-high')), findsOneWidget);
  });

  testWidgets('device notes document volume buttons and iOS limitations', (
    tester,
  ) async {
    await pumpSettings(tester);

    await reveal(tester, find.byKey(const Key('settings-device-notes')));
    await tester.tap(find.byKey(const Key('settings-device-notes')));
    await tester.pumpAndSettle();

    expect(find.text('Volume buttons'), findsOneWidget);
    expect(find.text('iOS integration'), findsOneWidget);
    expect(find.textContaining('Quick Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
