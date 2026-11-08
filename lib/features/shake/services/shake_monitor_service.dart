import 'dart:async';

import 'package:flutter/services.dart';

import '../domain/shake_sensitivity.dart';

/// Native lifetime of the background shake-monitor foreground service.
enum ShakeMonitorStatus { stopped, running, failed }

class ShakeMonitorStartResult {
  const ShakeMonitorStartResult({
    required this.started,
    required this.notificationsEnabled,
    this.error,
  });

  const ShakeMonitorStartResult.unsupported()
    : started = false,
      notificationsEnabled = false,
      error = 'unsupported';

  final bool started;

  /// False when Android 13+ notifications are denied. Monitoring can still
  /// run, but Android cannot show the required ongoing notification.
  final bool notificationsEnabled;

  final String? error;
}

/// Android-only bridge for accelerometer monitoring that survives the Flutter
/// UI closing. iOS has no equivalent, so it reports unsupported and the Bloc
/// keeps the foreground-only Dart listener.
abstract interface class ShakeMonitorService {
  Future<bool> isSupported();

  Future<ShakeMonitorStartResult> start();

  Future<void> stop();

  Future<bool> isRunning();

  Future<bool> hasNotificationPermission();

  Future<bool> requestNotificationPermission();

  /// Mirrors the user's choice, sensitivity, and busy state for the native
  /// listener, which runs without a Flutter engine.
  Future<void> setPreference({
    required bool enabled,
    required ShakeSensitivity sensitivity,
    required bool blocked,
  });

  Stream<ShakeMonitorStatus> get statusChanges;
}

class MethodChannelShakeMonitorService implements ShakeMonitorService {
  MethodChannelShakeMonitorService();

  static const MethodChannel _channel = MethodChannel(
    'com.claudysoft.flashlightpro/device_controls',
  );

  static const EventChannel _events = EventChannel(
    'com.claudysoft.flashlightpro/shake_monitor_state',
  );

  static const Duration _timeout = Duration(seconds: 5);

  Stream<ShakeMonitorStatus>? _stream;

  @override
  Future<bool> isSupported() async {
    try {
      return await _channel
              .invokeMethod<bool>('isShakeMonitoringSupported')
              .timeout(_timeout) ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ShakeMonitorStartResult> start() async {
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('startShakeMonitor')
          .timeout(_timeout);
      if (result == null) {
        return const ShakeMonitorStartResult(
          started: false,
          notificationsEnabled: false,
          error: 'failed',
        );
      }
      return ShakeMonitorStartResult(
        started: result['started'] == true,
        notificationsEnabled: result['notificationsEnabled'] != false,
        error: result['error'] as String?,
      );
    } on MissingPluginException {
      return const ShakeMonitorStartResult.unsupported();
    } catch (_) {
      return const ShakeMonitorStartResult(
        started: false,
        notificationsEnabled: false,
        error: 'failed',
      );
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stopShakeMonitor').timeout(_timeout);
    } catch (_) {
      // Stopping is best effort; the hardware torch state is unchanged.
    }
  }

  @override
  Future<bool> isRunning() async {
    try {
      return await _channel
              .invokeMethod<bool>('isShakeMonitorActive')
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
  Future<void> setPreference({
    required bool enabled,
    required ShakeSensitivity sensitivity,
    required bool blocked,
  }) async {
    try {
      await _channel
          .invokeMethod<void>('setShakePreference', <String, Object?>{
            'enabled': enabled,
            'sensitivity': sensitivity.index,
            'blocked': blocked,
          })
          .timeout(_timeout);
    } catch (_) {
      // Native defaults keep monitoring off until the next successful sync.
    }
  }

  @override
  Stream<ShakeMonitorStatus> get statusChanges => _stream ??= _events
      .receiveBroadcastStream()
      .map(_statusFromWire)
      .handleError((Object _) {})
      .distinct();
}

/// Used on iOS and in tests where no native sensor service exists.
class UnsupportedShakeMonitorService implements ShakeMonitorService {
  const UnsupportedShakeMonitorService();

  @override
  Future<bool> isSupported() async => false;

  @override
  Future<ShakeMonitorStartResult> start() async =>
      const ShakeMonitorStartResult.unsupported();

  @override
  Future<void> stop() async {}

  @override
  Future<bool> isRunning() async => false;

  @override
  Future<bool> hasNotificationPermission() async => false;

  @override
  Future<bool> requestNotificationPermission() async => false;

  @override
  Future<void> setPreference({
    required bool enabled,
    required ShakeSensitivity sensitivity,
    required bool blocked,
  }) async {}

  @override
  Stream<ShakeMonitorStatus> get statusChanges =>
      const Stream<ShakeMonitorStatus>.empty();
}

ShakeMonitorStatus _statusFromWire(Object? value) {
  return switch (value) {
    'running' => ShakeMonitorStatus.running,
    'failed' => ShakeMonitorStatus.failed,
    _ => ShakeMonitorStatus.stopped,
  };
}
