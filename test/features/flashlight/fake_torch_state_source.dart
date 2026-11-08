import 'dart:async';

import 'package:flash_light_pro/features/flashlight/services/torch_service.dart';

class FakeTorchStateSource implements TorchStateSource {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> get changes => _controller.stream;

  void emit(bool isOn) {
    if (!_controller.isClosed) {
      _controller.add(isOn);
    }
  }

  Future<void> dispose() => _controller.close();
}
