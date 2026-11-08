import 'package:flash_light_pro/features/battery/services/battery_optimization_service.dart';
import 'package:flash_light_pro/l10n/app_localizations.dart';
import 'package:flash_light_pro/src/presentation/screens/settings/battery_optimization_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBatteryOptimizationService implements BatteryOptimizationService {
  FakeBatteryOptimizationService({
    this.statusValue = const BatteryOptimizationStatus(
      supported: true,
      ignoring: false,
    ),
    this.requestResult = true,
  });

  BatteryOptimizationStatus statusValue;
  bool requestResult;
  int statusCalls = 0;
  int requestCalls = 0;
  int openCalls = 0;

  @override
  Future<BatteryOptimizationStatus> status() async {
    statusCalls++;
    return statusValue;
  }

  @override
  Future<bool> requestIgnore() async {
    requestCalls++;
    return requestResult;
  }

  @override
  Future<bool> openSettings() async {
    openCalls++;
    return true;
  }
}

Widget app(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('battery optimization section', () {
    testWidgets('is hidden on platforms without the native service', (
      tester,
    ) async {
      final service = FakeBatteryOptimizationService(
        statusValue: const BatteryOptimizationStatus.unsupported(),
      );

      await tester.pumpWidget(
        app(BatteryOptimizationSection(service: service)),
      );
      await tester.pump();

      expect(find.byKey(const Key('settings-battery')), findsNothing);
    });

    testWidgets('explains the optimized state and asks before changing it', (
      tester,
    ) async {
      final service = FakeBatteryOptimizationService();

      await tester.pumpWidget(
        app(BatteryOptimizationSection(service: service)),
      );
      await tester.pump();

      expect(find.byKey(const Key('settings-battery')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('settings-battery-status')))
            .data,
        'Optimized by Android',
      );

      await tester.tap(find.byKey(const Key('settings-battery-allow')));
      await tester.pump();

      expect(service.requestCalls, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a denied request is explained without changing the setting', (
      tester,
    ) async {
      final service = FakeBatteryOptimizationService(requestResult: false);

      await tester.pumpWidget(
        app(BatteryOptimizationSection(service: service)),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('settings-battery-allow')));
      await tester.pump();

      expect(find.byKey(const Key('settings-battery-denied')), findsOneWidget);
      expect(service.statusCalls, 1);
    });

    testWidgets('shows the unrestricted state without a request button', (
      tester,
    ) async {
      final service = FakeBatteryOptimizationService(
        statusValue: const BatteryOptimizationStatus(
          supported: true,
          ignoring: true,
        ),
      );

      await tester.pumpWidget(
        app(BatteryOptimizationSection(service: service)),
      );
      await tester.pump();

      expect(
        tester
            .widget<Text>(find.byKey(const Key('settings-battery-status')))
            .data,
        'Unrestricted',
      );
      expect(find.byKey(const Key('settings-battery-allow')), findsNothing);
      expect(find.byKey(const Key('settings-battery-open')), findsOneWidget);
    });

    testWidgets('refreshes the status when the app resumes', (tester) async {
      final service = FakeBatteryOptimizationService();

      await tester.pumpWidget(
        app(BatteryOptimizationSection(service: service)),
      );
      await tester.pump();
      expect(service.statusCalls, 1);

      service.statusValue = const BatteryOptimizationStatus(
        supported: true,
        ignoring: true,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(service.statusCalls, 2);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('settings-battery-status')))
            .data,
        'Unrestricted',
      );
    });

    testWidgets('fits a 320 logical pixel screen without overflowing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        app(
          BatteryOptimizationSection(service: FakeBatteryOptimizationService()),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
