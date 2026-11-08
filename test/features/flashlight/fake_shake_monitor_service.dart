import 'dart:async';

import 'package:flash_light_pro/features/shake/domain/shake_sensitivity.dart';
import 'package:flash_light_pro/features/shake/services/shake_monitor_service.dart';

class FakeShakeMonitorService implements ShakeMonitorService {
  FakeShakeMonitorService({
    this.supported = true,
    this.notificationsEnabled = true,
    this.startSucceeds = true,
  });

  bool supported;
  bool notificationsEnabled;
  bool startSucceeds;
  bool running = false;
  String? startError;

  int isSupportedCalls = 0;
  int startCalls = 0;
  int stopCalls = 0;
  int isRunningCalls = 0;
  int requestPermissionCalls = 0;
  int preferenceCalls = 0;
  bool? lastEnabled;
  ShakeSensitivity? lastSensitivity;
  bool? lastBlocked;

  final StreamController<ShakeMonitorStatus> _status =
      StreamController<ShakeMonitorStatus>.broadcast();

  @override
  Future<bool> isSupported() async {
    isSupportedCalls++;
    return supported;
  }

  @override
  Future<ShakeMonitorStartResult> start() async {
    startCalls++;
    running = startSucceeds;
    return ShakeMonitorStartResult(
      started: startSucceeds,
      notificationsEnabled: notificationsEnabled,
      error: startSucceeds ? null : (startError ?? 'failed'),
    );
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    running = false;
  }

  @override
  Future<bool> isRunning() async {
    isRunningCalls++;
    return running;
  }

  @override
  Future<bool> hasNotificationPermission() async => notificationsEnabled;

  @override
  Future<bool> requestNotificationPermission() async {
    requestPermissionCalls++;
    return notificationsEnabled;
  }

  @override
  Future<void> setPreference({
    required bool enabled,
    required ShakeSensitivity sensitivity,
    required bool blocked,
  }) async {
    preferenceCalls++;
    lastEnabled = enabled;
    lastSensitivity = sensitivity;
    lastBlocked = blocked;
  }

  @override
  Stream<ShakeMonitorStatus> get statusChanges => _status.stream;

  void emitStatus(ShakeMonitorStatus status) {
    if (!_status.isClosed) _status.add(status);
  }

  Future<void> dispose() => _status.close();
}
