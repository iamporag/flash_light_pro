import 'dart:async';

import 'package:flash_light_pro/features/flashlight/services/background_torch_service.dart';

class FakeBackgroundTorchService implements BackgroundTorchService {
  FakeBackgroundTorchService({
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
  int permissionCalls = 0;
  int requestPermissionCalls = 0;
  int preferenceCalls = 0;
  bool? backgroundPreference;

  final StreamController<BackgroundTorchStatus> _status =
      StreamController<BackgroundTorchStatus>.broadcast();

  @override
  Future<bool> isSupported() async {
    isSupportedCalls++;
    return supported;
  }

  @override
  Future<BackgroundStartResult> start() async {
    startCalls++;
    running = startSucceeds;
    return BackgroundStartResult(
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
  Future<bool> hasNotificationPermission() async {
    permissionCalls++;
    return notificationsEnabled;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    requestPermissionCalls++;
    return notificationsEnabled;
  }

  @override
  Future<void> setBackgroundPreference(bool enabled) async {
    preferenceCalls++;
    backgroundPreference = enabled;
  }

  @override
  Stream<BackgroundTorchStatus> get statusChanges => _status.stream;

  void emitStatus(BackgroundTorchStatus status) {
    if (!_status.isClosed) _status.add(status);
  }

  Future<void> dispose() => _status.close();
}
