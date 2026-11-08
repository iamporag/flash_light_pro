import 'package:flash_light_pro/features/device/services/device_controls.dart';

class FakeDeviceControls implements DeviceControls {
  bool levelSupported = false;
  bool setLevelResult = true;

  int supportCalls = 0;
  int setLevelCalls = 0;
  double? lastLevel;

  int screenBrightnessCalls = 0;
  double? lastBrightness;

  int restoreCalls = 0;
  int keepScreenOnCalls = 0;
  bool? lastKeepScreenOn;

  bool nativePatternSupported = false;
  bool nativePatternStartResult = true;
  final List<String> startModeCalls = [];
  int stopModeCalls = 0;
  int pauseModeCalls = 0;
  int resumeModeCalls = 0;
  int? lastStrobeInterval;
  bool pauseModeResult = true;
  bool resumeModeResult = true;

  @override
  Future<bool> isTorchLevelSupported() async {
    supportCalls++;
    return levelSupported;
  }

  @override
  Future<bool> setTorchLevel(double level) async {
    setLevelCalls++;
    lastLevel = level;
    return setLevelResult;
  }

  @override
  Future<void> setScreenBrightness(double brightness) async {
    screenBrightnessCalls++;
    lastBrightness = brightness;
  }

  @override
  Future<void> restoreScreenBrightness() async {
    restoreCalls++;
  }

  @override
  Future<void> setKeepScreenOn(bool enabled) async {
    keepScreenOnCalls++;
    lastKeepScreenOn = enabled;
  }

  @override
  Future<bool> startTorchMode(String mode) async {
    startModeCalls.add(mode);
    return nativePatternSupported && nativePatternStartResult;
  }

  @override
  Future<void> stopTorchMode() async {
    stopModeCalls++;
  }

  @override
  Future<bool> pauseTorchMode() async {
    pauseModeCalls++;
    return pauseModeResult;
  }

  @override
  Future<bool> resumeTorchMode() async {
    resumeModeCalls++;
    return resumeModeResult;
  }

  @override
  Future<void> setStrobeIntervalPreference(int milliseconds) async {
    lastStrobeInterval = milliseconds;
  }
}
