import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flash_light_pro/core/config/app_info.dart';
import 'package:flutter/services.dart';

enum TorchFailureKind {
  unavailable,
  cameraInUse,
  enableFailed,
  disableFailed,
  availabilityFailed,
  platformUnavailable,
  unexpected,
}

/// A sanitized torch failure. Raw platform messages are intentionally not
/// exposed so they cannot leak into the UI.
class TorchFailure extends Equatable implements Exception {
  const TorchFailure(this.kind);

  final TorchFailureKind kind;

  @override
  List<Object?> get props => [kind];
}

/// Platform-independent torch control backed by the app's shared native
/// controller.
abstract interface class TorchService {
  Future<bool> isAvailable();

  /// Reads the authoritative native state without changing the hardware.
  Future<bool> isOn();

  Future<void> enable();

  Future<void> disable();
}

/// Emits the hardware torch state, including changes made by the Quick
/// Settings tile, home screen widget, or App Intents.
abstract interface class TorchStateSource {
  Stream<bool> get changes;
}

class MethodChannelTorchService implements TorchService {
  const MethodChannelTorchService();

  static const MethodChannel _channel = MethodChannel(
    AppInfo.deviceControlsChannel,
  );

  static const Duration _timeout = Duration(seconds: 5);

  @override
  Future<bool> isAvailable() async {
    try {
      return await _channel
              .invokeMethod<bool>('isTorchAvailable')
              .timeout(_timeout) ??
          false;
    } on MissingPluginException {
      throw const TorchFailure(TorchFailureKind.platformUnavailable);
    } on TimeoutException {
      throw const TorchFailure(TorchFailureKind.availabilityFailed);
    } catch (_) {
      throw const TorchFailure(TorchFailureKind.availabilityFailed);
    }
  }

  @override
  Future<bool> isOn() async {
    try {
      return await _channel
              .invokeMethod<bool>('getTorchState')
              .timeout(_timeout) ??
          false;
    } on MissingPluginException {
      throw const TorchFailure(TorchFailureKind.platformUnavailable);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> enable() => _setEnabled(true);

  @override
  Future<void> disable() => _setEnabled(false);

  Future<void> _setEnabled(bool enabled) async {
    final fallback = enabled
        ? TorchFailureKind.enableFailed
        : TorchFailureKind.disableFailed;

    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('setTorchEnabled', {
            'enabled': enabled,
          })
          .timeout(_timeout);
      if (result == null) {
        throw TorchFailure(fallback);
      }
      if (result['success'] != true) {
        throw TorchFailure(_kindFromWire(result['error'] as String?, fallback));
      }
    } on TorchFailure {
      rethrow;
    } on MissingPluginException {
      throw const TorchFailure(TorchFailureKind.platformUnavailable);
    } on TimeoutException {
      throw TorchFailure(fallback);
    } on PlatformException {
      throw TorchFailure(fallback);
    } catch (_) {
      throw const TorchFailure(TorchFailureKind.unexpected);
    }
  }

  TorchFailureKind _kindFromWire(String? error, TorchFailureKind fallback) {
    return switch (error) {
      'unavailable' => TorchFailureKind.unavailable,
      'cameraInUse' => TorchFailureKind.cameraInUse,
      'failed' => fallback,
      _ => fallback,
    };
  }
}

class EventChannelTorchStateSource implements TorchStateSource {
  EventChannelTorchStateSource();

  static const EventChannel _channel = EventChannel(AppInfo.torchStateChannel);

  Stream<bool>? _stream;

  @override
  Stream<bool> get changes => _stream ??= _channel
      .receiveBroadcastStream()
      .map((event) => event == true)
      .handleError((Object _) {})
      .distinct();
}
