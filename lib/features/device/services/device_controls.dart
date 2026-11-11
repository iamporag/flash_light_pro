import 'package:flash_light_pro/core/config/app_info.dart';
import 'package:flutter/services.dart';

/// Platform controls that live outside the torch plugin: screen brightness,
/// keeping the display awake, and torch strength on supported hardware.
abstract interface class DeviceControls {
  Future<bool> isTorchLevelSupported();

  /// Returns whether the level was applied. Failure is non-fatal; the torch
  /// stays on at its default strength.
  Future<bool> setTorchLevel(double level);

  Future<void> setScreenBrightness(double brightness);

  Future<void> restoreScreenBrightness();

  Future<void> setKeepScreenOn(bool enabled);

  /// Starts a native pattern (`sos` or `strobe`) in the shared foreground
  /// service. Returns false when the platform cannot own playback, so the
  /// caller can fall back to the Dart sequence player.
  Future<bool> startTorchMode(String mode);

  Future<void> stopTorchMode();

  Future<bool> pauseTorchMode();

  Future<bool> resumeTorchMode();

  /// Keeps the native strobe speed in sync, including a pattern that was
  /// started from the notification panel without Flutter.
  Future<void> setStrobeIntervalPreference(int milliseconds);
}

class MethodChannelDeviceControls implements DeviceControls {
  const MethodChannelDeviceControls();

  static const MethodChannel _channel = MethodChannel(
    AppInfo.deviceControlsChannel,
  );

  @override
  Future<bool> isTorchLevelSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isTorchLevelSupported') ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> setTorchLevel(double level) async {
    try {
      return await _channel.invokeMethod<bool>('setTorchLevel', {
            'level': level.clamp(0.0, 1.0),
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setScreenBrightness(double brightness) async {
    try {
      await _channel.invokeMethod<void>('setScreenBrightness', {
        'brightness': brightness.clamp(0.01, 1.0),
      });
    } catch (_) {
      // Window brightness is a graceful enhancement on both platforms.
    }
  }

  @override
  Future<void> restoreScreenBrightness() async {
    try {
      await _channel.invokeMethod<void>('restoreScreenBrightness');
    } catch (_) {}
  }

  @override
  Future<void> setKeepScreenOn(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setKeepScreenOn', {
        'enabled': enabled,
      });
    } catch (_) {}
  }

  @override
  Future<bool> startTorchMode(String mode) async {
    if (mode != 'sos' && mode != 'strobe') return false;
    try {
      return await _channel.invokeMethod<bool>('startTorchMode', {
            'mode': mode,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> stopTorchMode() async {
    try {
      await _channel.invokeMethod<void>('stopTorchMode');
    } catch (_) {}
  }

  @override
  Future<bool> pauseTorchMode() async {
    try {
      return await _channel.invokeMethod<bool>('pauseTorchMode') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> resumeTorchMode() async {
    try {
      return await _channel.invokeMethod<bool>('resumeTorchMode') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setStrobeIntervalPreference(int milliseconds) async {
    try {
      await _channel.invokeMethod<void>('setStrobeIntervalPreference', {
        'milliseconds': milliseconds,
      });
    } catch (_) {}
  }
}
