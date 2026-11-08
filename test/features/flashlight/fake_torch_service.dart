import 'dart:async';

import 'package:flash_light_pro/features/flashlight/services/torch_service.dart';

class FakeTorchService implements TorchService {
  bool available = true;
  bool hardwareOn = false;
  Object? availabilityError;
  Object? enableError;
  Object? disableError;
  Object? stateError;

  Completer<void>? availabilityGate;
  Completer<void>? enableGate;
  Completer<void>? disableGate;

  int availabilityCalls = 0;
  int stateCalls = 0;
  int enableCalls = 0;
  int disableCalls = 0;

  @override
  Future<bool> isAvailable() async {
    availabilityCalls++;
    await availabilityGate?.future;
    final error = availabilityError;
    if (error != null) throw error;
    return available;
  }

  @override
  Future<bool> isOn() async {
    stateCalls++;
    final error = stateError;
    if (error != null) throw error;
    return hardwareOn;
  }

  @override
  Future<void> enable() async {
    enableCalls++;
    await enableGate?.future;
    final error = enableError;
    if (error != null) throw error;
    hardwareOn = true;
  }

  @override
  Future<void> disable() async {
    disableCalls++;
    await disableGate?.future;
    final error = disableError;
    if (error != null) throw error;
    hardwareOn = false;
  }
}
