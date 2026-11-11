import 'package:flash_light_pro/features/flashlight/services/background_torch_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.claudysoft.flashlightpro/device_controls');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('isSupported reflects the native capability', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'isBackgroundModeSupported');
      return true;
    });

    expect(await MethodChannelBackgroundTorchService().isSupported(), isTrue);
  });

  test('start maps the native payload', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'startBackgroundMode');
      return <String, dynamic>{
        'started': true,
        'notificationsEnabled': false,
        'error': null,
      };
    });

    final result = await MethodChannelBackgroundTorchService().start();

    expect(result.started, isTrue);
    expect(result.notificationsEnabled, isFalse);
    expect(result.error, isNull);
  });

  test('a native start failure keeps the failure reason', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      return <String, dynamic>{
        'started': false,
        'notificationsEnabled': true,
        'error': 'failed',
      };
    });

    final result = await MethodChannelBackgroundTorchService().start();

    expect(result.started, isFalse);
    expect(result.error, 'failed');
  });

  test('missing platform support is not reported as running', () async {
    final service = MethodChannelBackgroundTorchService();

    expect(await service.isSupported(), isFalse);
    final result = await service.start();
    expect(result.started, isFalse);
    expect(result.error, 'unsupported');
    expect(await service.isRunning(), isFalse);
    expect(await service.hasNotificationPermission(), isFalse);
    expect(await service.requestNotificationPermission(), isFalse);
    await service.setBackgroundPreference(true);
    await service.stop();
  });

  test('the background preference is mirrored for native surfaces', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    await MethodChannelBackgroundTorchService().setBackgroundPreference(false);

    expect(calls.single.method, 'setBackgroundModePreference');
    expect(calls.single.arguments, <String, Object?>{'enabled': false});
  });

  test('queries use the documented method names', () async {
    final methods = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      methods.add(call.method);
      return switch (call.method) {
        'isBackgroundModeActive' => true,
        'hasNotificationPermission' => true,
        'requestNotificationPermission' => true,
        _ => null,
      };
    });

    final service = MethodChannelBackgroundTorchService();

    expect(await service.isRunning(), isTrue);
    expect(await service.hasNotificationPermission(), isTrue);
    expect(await service.requestNotificationPermission(), isTrue);
    await service.stop();

    expect(methods, [
      'isBackgroundModeActive',
      'hasNotificationPermission',
      'requestNotificationPermission',
      'stopBackgroundMode',
    ]);
  });
}
