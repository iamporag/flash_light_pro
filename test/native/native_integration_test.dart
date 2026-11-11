import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String read(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    fail('Expected $path to exist.');
  }
  return file.readAsStringSync();
}

void main() {
  group('Android Quick Settings tile and widget registration', () {
    final manifest = read('android/app/src/main/AndroidManifest.xml');

    test('the tile service is exported with the system permission', () {
      expect(manifest, contains('android:name=".TorchTileService"'));
      expect(manifest, contains('android:exported="true"'));
      expect(manifest, contains('android.permission.BIND_QUICK_SETTINGS_TILE'));
      expect(
        manifest,
        contains('android.service.quicksettings.action.QS_TILE'),
      );
      expect(
        manifest,
        contains('android.service.quicksettings.TOGGLEABLE_TILE'),
      );
    });

    test('the widget receiver is registered without being exported', () {
      expect(manifest, contains('android:name=".TorchWidgetProvider"'));
      expect(manifest, contains('android:exported="false"'));
      expect(manifest, contains('android.appwidget.action.APPWIDGET_UPDATE'));
      expect(manifest, contains('@xml/torch_widget_info'));
    });

    test('exactly one foreground service is declared and it is specialUse', () {
      final services = RegExp(
        r'<service\b[^>]*android:name="\.TorchForegroundService"',
      ).allMatches(manifest);

      expect(services, hasLength(1));
      expect(manifest, contains('android:foregroundServiceType="specialUse"'));
      expect(manifest, isNot(contains('foregroundServiceType="camera"')));
      expect(manifest, isNot(contains('ShakeMonitorService')));
      expect(
        manifest,
        isNot(contains('android.permission.FOREGROUND_SERVICE_CAMERA')),
      );
    });

    test('battery exemption is requested only through the system dialog', () {
      expect(
        manifest,
        contains('android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS'),
      );
      expect(manifest, isNot(contains('android.permission.WAKE_LOCK')));
    });

    test('the flash feature is optional and the camera is never opened', () {
      expect(manifest, contains('android.hardware.camera.flash'));
      expect(manifest, contains('android:required="false"'));
      expect(manifest, isNot(contains('android.permission.CAMERA')));
    });

    test('AdMob and Play Billing declare only the permissions they need', () {
      expect(manifest, contains('android.permission.INTERNET'));
      expect(manifest, contains('android.permission.ACCESS_NETWORK_STATE'));
      expect(manifest, contains('com.android.vending.BILLING'));
      expect(manifest, contains('com.google.android.gms.ads.APPLICATION_ID'));
      expect(manifest, contains(r'android:value="${admobAppId}"'));
    });

    test('the AdMob app id is injected, never hardcoded in the manifest', () {
      final gradle = read('android/app/build.gradle');

      expect(gradle, contains('project.findProperty("admobAppId")'));
      expect(gradle, contains('ADMOB_APP_ID'));
      expect(gradle, contains('manifestPlaceholders.admobAppId = admobAppId'));
      expect(gradle, isNot(contains('manifestPlaceholders = [')));
      expect(manifest, isNot(contains('ca-app-pub-')));
    });

    test(
      'the tile toggles through the shared controller and exposes state',
      () {
        final tile = read(
          'android/app/src/main/kotlin/com/claudysoft/flashlightpro/'
          'TorchTileService.kt',
        );

        expect(tile, contains('class TorchTileService : TileService()'));
        expect(tile, contains('override fun onStartListening()'));
        expect(tile, contains('override fun onClick()'));
        expect(tile, contains('TorchManager.get(this).toggle()'));
        expect(tile, contains('Tile.STATE_ACTIVE'));
        expect(tile, contains('Tile.STATE_INACTIVE'));
        expect(tile, contains('Tile.STATE_UNAVAILABLE'));
        expect(tile, contains('requestListeningState'));
      },
    );

    test('the tile stops an active pattern instead of toggling a blink', () {
      final tile = read(
        'android/app/src/main/kotlin/com/claudysoft/flashlightpro/'
        'TorchTileService.kt',
      );

      expect(tile, contains('TorchPatternPlayer.isActive()'));
      expect(tile, contains('TorchForegroundService.stopPattern(this)'));
      // The tile is a permanent system affordance; stopping a mode must not
      // hide or unregister it.
      expect(tile, isNot(contains('setComponentEnabledSetting')));
      expect(tile, isNot(contains('COMPONENT_ENABLED_STATE_DISABLED')));
    });

    test('the widget stops an active pattern instead of toggling a blink', () {
      final widget = read(
        'android/app/src/main/kotlin/com/claudysoft/flashlightpro/'
        'TorchWidgetProvider.kt',
      );

      expect(widget, contains('TorchPatternPlayer.isActive()'));
      expect(widget, contains('TorchForegroundService.stopPattern(context)'));
      expect(widget, isNot(contains('setComponentEnabledSetting')));
    });

    test('the widget toggles without starting a background service', () {
      final widget = read(
        'android/app/src/main/kotlin/com/claudysoft/flashlightpro/'
        'TorchWidgetProvider.kt',
      );

      expect(
        widget,
        contains('class TorchWidgetProvider : AppWidgetProvider()'),
      );
      expect(widget, contains('ACTION_TOGGLE'));
      expect(widget, contains('goAsync()'));
      expect(widget, contains('RemoteViews'));
      expect(widget, contains('PendingIntent'));
      expect(widget, contains('TorchManager.get(context).toggle()'));
      expect(widget, isNot(contains('startService')));
      expect(widget, isNot(contains('startForegroundService')));
    });

    test('the notification panel uses RemoteViews with every control', () {
      final notification = read(
        'android/app/src/main/kotlin/com/claudysoft/flashlightpro/'
        'FlashlightNotification.kt',
      );
      final expanded = read(
        'android/app/src/main/res/layout/notification_flashlight_expanded.xml',
      );

      expect(notification, contains('RemoteViews('));
      expect(notification, contains('setOnClickPendingIntent'));
      expect(notification, isNot(contains('NotificationCompat')));
      expect(expanded, contains('@+id/notification_control_flashlight'));
      expect(expanded, contains('@+id/notification_control_shake'));
      expect(expanded, contains('@+id/notification_control_sos'));
      expect(expanded, contains('@+id/notification_control_strobe'));
      expect(expanded, contains('@+id/notification_action_open'));
      expect(expanded, contains('@+id/notification_action_stop'));
    });

    test('one stable notification and one sensor listener serve all modes', () {
      final service = read(
        'android/app/src/main/kotlin/com/claudysoft/flashlightpro/'
        'TorchForegroundService.kt',
      );

      expect(service, contains('NOTIFICATION_ID = 4101'));
      expect(service, contains('CHANNEL_ID = "flashlight_background"'));
      expect(RegExp(r'\.notify\(').allMatches(service), hasLength(1));
      expect(RegExp(r'\.registerListener\(').allMatches(service), hasLength(1));
      expect(service, contains('START_STICKY'));
      expect(service, contains('ACTION_TOGGLE_SHAKE'));
      expect(service, contains('ACTION_START_SOS'));
      expect(service, contains('ACTION_START_STROBE'));
      expect(service, contains('ACTION_STOP_ALL'));
    });

    test('native control and battery state are bridged to Flutter', () {
      final activity = read(
        'android/app/src/main/kotlin/com/claudysoft/flashlightpro/'
        'MainActivity.kt',
      );

      expect(
        activity,
        contains('com.claudysoft.flashlightpro/native_controls_state'),
      );
      expect(activity, contains('"getNativeControlState"'));
      expect(activity, contains('"getBatteryOptimizationStatus"'));
      expect(activity, contains('"requestIgnoreBatteryOptimizations"'));
      expect(activity, contains('"openBatteryOptimizationSettings"'));
      expect(activity, contains('isIgnoringBatteryOptimizations(packageName)'));
      expect(
        activity,
        contains('Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS'),
      );
      expect(
        activity,
        contains('Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS'),
      );
    });

    test('one process-wide controller backs every surface', () {
      final manager = read(
        'android/app/src/main/kotlin/com/claudysoft/flashlightpro/'
        'TorchManager.kt',
      );
      final activity = read(
        'android/app/src/main/kotlin/com/claudysoft/flashlightpro/'
        'MainActivity.kt',
      );

      expect(manager, contains('object TorchManager'));
      expect(manager, contains('TorchWidgetProvider.updateAll'));
      expect(manager, contains('TorchTileService.requestRefresh'));
      expect(activity, contains('TorchManager.get(this)'));
      expect(
        activity,
        contains('com.claudysoft.flashlightpro/device_controls'),
      );
      expect(activity, contains('com.claudysoft.flashlightpro/torch_state'));
    });

    test(
      'the camera hardware uses the torch API, not a camera capture session',
      () {
        final hardware = read(
          'android/app/src/main/kotlin/com/claudysoft/flashlightpro/'
          'CameraTorchHardware.kt',
        );

        expect(hardware, contains('setTorchMode'));
        expect(hardware, contains('registerTorchCallback'));
        expect(hardware, contains('CameraAccessException.CAMERA_IN_USE'));
        expect(hardware, isNot(contains('CameraCaptureSession')));
      },
    );

    test('the controller has JVM unit tests for toggle and error paths', () {
      final tests = read(
        'android/app/src/test/kotlin/com/claudysoft/flashlightpro/'
        'TorchControllerTest.kt',
      );

      expect(tests, contains('TorchControllerTest'));
      expect(tests, contains('UNAVAILABLE'));
      expect(tests, contains('CAMERA_IN_USE'));
    });
  });

  group('iOS Shortcuts and state sync registration', () {
    final info = read('ios/Runner/Info.plist');
    final delegate = read('ios/Runner/AppDelegate.swift');
    final intents = read('ios/Runner/TorchIntents.swift');
    final controller = read('ios/Runner/TorchController.swift');
    final project = read('ios/Runner.xcodeproj/project.pbxproj');

    test('motion access is declared only for shake detection', () {
      expect(info, contains('NSMotionUsageDescription'));
      expect(info, contains('Shake to toggle'));
      expect(info, contains('<key>CFBundleLocalizations</key>'));
      expect(info, contains('<string>en</string>'));
      expect(info, contains('<string>bn</string>'));
      expect(info, isNot(contains('UIBackgroundModes')));
    });

    test('App Intents expose on, off, and toggle without opening the app', () {
      expect(intents, contains('struct ControlTorchIntent: AppIntent'));
      expect(intents, contains('enum TorchAction: String, AppEnum'));
      expect(intents, contains('case on'));
      expect(intents, contains('case off'));
      expect(intents, contains('case toggle'));
      expect(intents, contains('openAppWhenRun: Bool = false'));
      expect(
        intents,
        contains('struct FlashlightShortcuts: AppShortcutsProvider'),
      );
      expect(intents, contains('TorchController.shared'));
    });

    test('shortcut parameters are refreshed and channels are registered', () {
      expect(
        delegate,
        contains('FlashlightShortcuts.updateAppShortcutParameters'),
      );
      expect(delegate, contains('#available(iOS 16.0, *)'));
      expect(
        delegate,
        contains('com.claudysoft.flashlightpro/device_controls'),
      );
      expect(delegate, contains('com.claudysoft.flashlightpro/torch_state'));
      expect(delegate, contains('TorchController.shared'));
    });

    test(
      'the Swift controller uses the torch property, not camera capture',
      () {
        expect(controller, contains('AVCaptureDevice.default(for: .video)'));
        expect(controller, contains('device.hasTorch'));
        expect(controller, contains('setTorchModeOn'));
        expect(controller, contains('NSLock'));
        expect(controller, contains('stateDidChange'));
        expect(controller, isNot(contains('AVCaptureSession')));
        expect(controller, isNot(contains('requestAccess')));
      },
    );

    test('both Swift sources are compiled into the Runner target', () {
      expect(project, contains('TorchController.swift'));
      expect(project, contains('TorchIntents.swift'));
      expect(project, contains('TorchController.swift in Sources'));
      expect(project, contains('TorchIntents.swift in Sources'));
    });
  });

  group('Dependency boundary', () {
    final pubspec = read('pubspec.yaml');
    final adConfig = read('lib/core/config/admob/admob_config.dart');
    final adMobIds = read('lib/core/config/admob/admob_ids.dart');

    test('monetization uses the official SDKs and no extra network stack', () {
      expect(pubspec, contains('sensors_plus:'));
      expect(pubspec, contains('google_mobile_ads:'));
      expect(pubspec, contains('in_app_purchase:'));
      expect(pubspec, isNot(contains('firebase')));
      expect(pubspec, isNot(contains('sentry')));
      expect(pubspec, isNot(contains('amplitude')));
      expect(pubspec, isNot(contains('camera:')));
      expect(pubspec, isNot(contains('http:')));
      expect(pubspec, isNot(contains('dio:')));
      expect(pubspec, isNot(contains('connectivity_plus')));
    });

    test(
      'AdMob unit ids live in one Dart source with build-time overrides',
      () {
        for (final id in [
          'ca-app-pub-8125551545712066/8706742446',
          'ca-app-pub-8125551545712066/8911802759',
          'ca-app-pub-8125551545712066/2699562288',
          'ca-app-pub-8125551545712066/3906888086',
          'ca-app-pub-8125551545712066/9267025974',
        ]) {
          expect(adMobIds, contains(id));
        }
        expect(adMobIds, contains('ca-app-pub-3940256099942544'));
        expect(adMobIds, isNot(contains('~2052695027')));
        expect(adConfig, contains('String.fromEnvironment'));
        expect(adConfig, contains("'ADMOB_ANDROID_BANNER_ID'"));
        expect(adConfig, contains('kDebugMode'));
        expect(adConfig, contains('kReleaseMode'));
        expect(adConfig, isNot(contains('ca-app-pub-8125551545712066')));
        expect(adConfig, isNot(contains('ca-app-pub-3940256099942544')));
      },
    );

    test('Play updates use the store API rather than an app network stack', () {
      expect(pubspec, contains('in_app_update:'));
      expect(pubspec, contains('url_launcher:'));
    });

    test('the Play Store URL matches the installed application id', () {
      final buildGradle = read('android/app/build.gradle');
      final appInfo = read('lib/core/config/app_info.dart');
      final config = read('lib/features/updates/domain/update_config.dart');

      final applicationId = RegExp(r'applicationId\s*=\s*"([^"]+)"')
          .firstMatch(buildGradle)
          ?.group(1);

      expect(applicationId, 'com.claudysoft.flashlightpro');
      expect(appInfo, contains("defaultValue: '$applicationId'"));
      expect(
        appInfo,
        contains('https://play.google.com/store/apps/details?id=\$packageName'),
      );
      expect(config, contains('defaultValue: AppInfo.packageName'));
    });
  });
}
