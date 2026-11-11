import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flash_light_pro/core/config/app_info.dart';
import 'package:flutter/services.dart';

class BatteryOptimizationStatus extends Equatable {
  const BatteryOptimizationStatus({
    required this.supported,
    required this.ignoring,
  });

  const BatteryOptimizationStatus.unsupported()
    : supported = false,
      ignoring = true;

  final bool supported;

  /// True when Android already exempts the app from battery optimization.
  final bool ignoring;

  @override
  List<Object?> get props => [supported, ignoring];
}

/// Android-only bridge for the system battery optimization exemption. The app
/// never changes the setting itself: it only opens the system dialog or list.
abstract interface class BatteryOptimizationService {
  Future<BatteryOptimizationStatus> status();

  /// Opens the system request dialog. The user can still deny it.
  Future<bool> requestIgnore();

  /// Opens the system list where the user can change the exemption manually.
  Future<bool> openSettings();
}

class MethodChannelBatteryOptimizationService
    implements BatteryOptimizationService {
  const MethodChannelBatteryOptimizationService();

  static const MethodChannel _channel = MethodChannel(
    AppInfo.deviceControlsChannel,
  );

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<BatteryOptimizationStatus> status() async {
    if (!_supported) return const BatteryOptimizationStatus.unsupported();
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getBatteryOptimizationStatus',
      );
      if (result == null) return const BatteryOptimizationStatus.unsupported();
      return BatteryOptimizationStatus(
        supported: result['supported'] == true,
        ignoring: result['ignoring'] == true,
      );
    } catch (_) {
      return const BatteryOptimizationStatus.unsupported();
    }
  }

  @override
  Future<bool> requestIgnore() async {
    if (!_supported) return false;
    try {
      return await _channel
              .invokeMethod<bool>('requestIgnoreBatteryOptimizations')
              .timeout(const Duration(seconds: 20)) ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> openSettings() async {
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'openBatteryOptimizationSettings',
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }
}

class UnsupportedBatteryOptimizationService
    implements BatteryOptimizationService {
  const UnsupportedBatteryOptimizationService();

  @override
  Future<BatteryOptimizationStatus> status() async =>
      const BatteryOptimizationStatus.unsupported();

  @override
  Future<bool> requestIgnore() async => false;

  @override
  Future<bool> openSettings() async => false;
}
