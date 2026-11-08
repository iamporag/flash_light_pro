import 'dart:async';

import 'package:flash_light_pro/features/shake/domain/shake_sensitivity.dart';
import 'package:flash_light_pro/features/shake/services/shake_service.dart';

class FakeShakeService implements ShakeService {
  final StreamController<void> _controller = StreamController<void>.broadcast();

  int startCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;
  bool isRunning = false;
  ShakeSensitivity? lastSensitivity;

  @override
  Stream<void> get shakes => _controller.stream;

  @override
  void start({required ShakeSensitivity sensitivity}) {
    startCalls++;
    isRunning = true;
    lastSensitivity = sensitivity;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    isRunning = false;
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    isRunning = false;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  void shake() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
