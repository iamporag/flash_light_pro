import 'package:flash_light_pro/features/settings/data/app_settings.dart';
import 'package:flash_light_pro/features/settings/domain/app_language.dart';
import 'package:flash_light_pro/flash_light_pro.dart';
import 'package:flash_light_pro/l10n/app_localizations.dart';
import 'package:flash_light_pro/src/presentation/utils/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flashlight/fake_device_controls.dart';
import '../flashlight/fake_settings_repository.dart';
import '../flashlight/fake_shake_service.dart';
import '../flashlight/fake_torch_service.dart';
import '../flashlight/fake_torch_state_source.dart';

Future<FakeSettingsRepository> pumpApp(
  WidgetTester tester, {
  AppSettings settings = const AppSettings(),
  Size? size,
}) async {
  if (size != null) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  final repository = FakeSettingsRepository(settings);
  await tester.pumpWidget(
    FlashLightPro(
      torchService: FakeTorchService(),
      deviceControls: FakeDeviceControls(),
      settingsRepository: repository,
      shakeService: FakeShakeService(),
      torchStateSource: FakeTorchStateSource(),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

Locale appLocale(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).locale!;

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('settings-button')));
  await tester.pumpAndSettle();
}

Widget localizedProbe(
  Widget Function(BuildContext context) builder,
  String locale,
) {
  return MaterialApp(
    locale: Locale(locale),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: Builder(builder: builder)),
  );
}

void main() {
  group('App language', () {
    testWidgets('English is the default regardless of stored settings', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(appLocale(tester), const Locale('en'));
      expect(find.text('Flash Light Pro'), findsOneWidget);
      expect(find.text('Flash Light Off'), findsOneWidget);
    });

    testWidgets('a stored Bengali preference is restored on launch', (
      tester,
    ) async {
      await pumpApp(
        tester,
        settings: const AppSettings(appLanguage: AppLanguage.bengali),
      );

      expect(appLocale(tester), const Locale('bn'));
      expect(find.text('ফ্ল্যাশ লাইট প্রো'), findsOneWidget);
      expect(find.text('ফ্ল্যাশলাইট বন্ধ'), findsOneWidget);
      expect(find.text('Flash Light Off'), findsNothing);
    });

    testWidgets('the language can be changed manually and persists', (
      tester,
    ) async {
      final repository = await pumpApp(tester);
      await openSettings(tester);

      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings-language-bn')));
      await tester.pumpAndSettle();

      expect(appLocale(tester), const Locale('bn'));
      expect(find.text('সেটিংস'), findsOneWidget);
      expect(repository.saved.last.appLanguage, AppLanguage.bengali);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('ফ্ল্যাশলাইট বন্ধ'), findsOneWidget);
      expect(find.text('টর্চ'), findsOneWidget);
      expect(find.text('মোর্স'), findsOneWidget);

      await openSettings(tester);
      await tester.tap(find.byKey(const Key('settings-language-en')));
      await tester.pumpAndSettle();

      expect(appLocale(tester), const Locale('en'));
      expect(find.text('Settings'), findsOneWidget);
      expect(repository.saved.last.appLanguage, AppLanguage.english);
    });
  });

  group('Number formatting', () {
    testWidgets('countdowns use the active locale digits', (tester) async {
      await tester.pumpWidget(
        localizedProbe(
          (context) =>
              Column(children: [Text('bn:${formatCountdown(context, 65)}')]),
          'bn',
        ),
      );

      expect(find.text('bn:১:০৫'), findsOneWidget);
    });

    testWidgets('English countdowns keep Latin digits', (tester) async {
      await tester.pumpWidget(
        localizedProbe(
          (context) => Text('en:${formatCountdown(context, 65)}'),
          'en',
        ),
      );

      expect(find.text('en:1:05'), findsOneWidget);
    });

    testWidgets('percentages and integers are localized', (tester) async {
      await tester.pumpWidget(
        localizedProbe(
          (context) => Text(
            '${localizedPercent(context, 0.5)}|${localizedNumber(context, 12)}',
          ),
          'bn',
        ),
      );

      expect(find.text('৫০%|১২'), findsOneWidget);
    });
  });

  group('Small-screen Bengali layout', () {
    testWidgets('home and settings fit 320 logical pixels without overflow', (
      tester,
    ) async {
      await pumpApp(
        tester,
        settings: const AppSettings(appLanguage: AppLanguage.bengali),
        size: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);

      await openSettings(tester);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings-privacy')),
        250,
        scrollable: find.descendant(
          of: find.byKey(const Key('settings-scroll')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('গোপনীয়তা নীতি'), findsOneWidget);

      final settingsScrollable = find.descendant(
        of: find.byKey(const Key('settings-scroll')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('settings-terms')),
        250,
        scrollable: settingsScrollable,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-terms')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('শর্তাবলি ও নিয়মাবলি'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('দায়বদ্ধতার সীমা'),
        250,
        scrollable: find.descendant(
          of: find.byKey(const Key('terms-scroll')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
