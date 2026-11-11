import 'dart:async';

import 'package:flash_light_pro/core/config/app_info.dart';
import 'package:flutter/services.dart';

/// Native lifetime of the background flashlight foreground service.
enum BackgroundTorchStatus { stopped, running, failed }

class BackgroundStartResult {
  const BackgroundStartResult({
    required this.started,
    required this.notificationsEnabled,
    this.error,
  });

  const BackgroundStartResult.unsupported()
    : started = false,
      notificationsEnabled = false,
      error = 'unsupported';

  final bool started;

  /// False when Android 13+ notifications are denied. The service can still
  /// run, but the Stop action is not visible in the notification shade.
  final bool notificationsEnabled;

  final String? error;
}

/// Android-only bridge for keeping the torch alive while Flash Light Pro is in
/// the background. iOS returns "unsupported" because the system suspends the
/// app and releases the torch.
abstract interface class BackgroundTorchService {
  Future<bool> isSupported();

  Future<BackgroundStartResult> start();

  Future<void> stop();

  Future<bool> isRunning();

  Future<bool> hasNotificationPermission();

  Future<bool> requestNotificationPermission();

  /// Mirrors the user's background-mode choice for the native tile and widget,
  /// which can run without a Flutter engine.
  Future<void> setBackgroundPreference(bool enabled);

  Stream<BackgroundTorchStatus> get statusChanges;
}

class MethodChannelBackgroundTorchService implements BackgroundTorchService {
  MethodChannelBackgroundTorchService();

  static const MethodChannel _channel = MethodChannel(
    AppInfo.deviceControlsChannel,
  );

  static const EventChannel _events = EventChannel(
    AppInfo.backgroundTorchStateChannel,
  );

  static const Duration _timeout = Duration(seconds: 5);

  Stream<BackgroundTorchStatus>? _stream;

  @override
  Future<bool> isSupported() async {
    try {
      return await _channel
              .invokeMethod<bool>('isBackgroundModeSupported')
              .timeout(_timeout) ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<BackgroundStartResult> start() async {
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('startBackgroundMode')
          .timeout(_timeout);
      if (result == null) {
        return const BackgroundStartResult(
          started: false,
          notificationsEnabled: false,
          error: 'failed',
        );
      }
      return BackgroundStartResult(
        started: result['started'] == true,
        notificationsEnabled: result['notificationsEnabled'] != false,
        error: result['error'] as String?,
      );
    } on MissingPluginException {
      return const BackgroundStartResult.unsupported();
    } catch (_) {
      return const BackgroundStartResult(
        started: false,
        notificationsEnabled: false,
        error: 'failed',
      );
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stopBackgroundMode').timeout(_timeout);
    } catch (_) {
      // Stopping is best effort; explicit torch disable still happens first.
    }
  }

  @override
  Future<void> setBackgroundPreference(bool enabled) async {
    try {
      await _channel
          .invokeMethod<void>('setBackgroundModePreference', <String, Object?>{
            'enabled': enabled,
          })
          .timeout(_timeout);
    } catch (_) {
      // The native surfaces default to enabled.
    }
  }

  @override
  Future<bool> isRunning() async {
    try {
      return await _channel
              .invokeMethod<bool>('isBackgroundModeActive')
              .timeout(_timeout) ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasNotificationPermission() async {
    try {
      return await _channel
              .invokeMethod<bool>('hasNotificationPermission')
              .timeout(_timeout) ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestNotificationPermission() async {
    try {
      return await _channel
              .invokeMethod<bool>('requestNotificationPermission')
              .timeout(const Duration(seconds: 20)) ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<BackgroundTorchStatus> get statusChanges => _stream ??= _events
      .receiveBroadcastStream()
      .map(_statusFromWire)
      .handleError((Object _) {})
      .distinct();
}

/// Used on iOS and in tests where no native background service exists.
class UnsupportedBackgroundTorchService implements BackgroundTorchService {
  const UnsupportedBackgroundTorchService();

  @override
  Future<bool> isSupported() async => false;

  @override
  Future<BackgroundStartResult> start() async =>
      const BackgroundStartResult.unsupported();

  @override
  Future<void> stop() async {}

  @override
  Future<bool> isRunning() async => false;

  @override
  Future<bool> hasNotificationPermission() async => false;

  @override
  Future<bool> requestNotificationPermission() async => false;

  @override
  Future<void> setBackgroundPreference(bool enabled) async {}

  @override
  Stream<BackgroundTorchStatus> get statusChanges =>
      const Stream<BackgroundTorchStatus>.empty();
}

BackgroundTorchStatus _statusFromWire(Object? value) {
  return switch (value) {
    'running' => BackgroundTorchStatus.running,
    'failed' => BackgroundTorchStatus.failed,
    _ => BackgroundTorchStatus.stopped,
  };
}
