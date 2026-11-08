import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

/// Pattern modes that the Android foreground service can own natively, so they
/// keep running without a Flutter engine.
enum NativePatternMode { off, sos, strobe }

/// One authoritative snapshot of the native control panel state.
class NativeControlsSnapshot extends Equatable {
  const NativeControlsSnapshot({
    this.mode = NativePatternMode.off,
    this.paused = false,
    this.torchOn = false,
    this.available = true,
    this.shakeEnabled = false,
    this.shakeMonitoring = false,
    this.backgroundServiceRunning = false,
    this.notificationsEnabled = true,
  });

  factory NativeControlsSnapshot.fromMap(Object? value) {
    if (value is! Map) return const NativeControlsSnapshot();
    return NativeControlsSnapshot(
      mode: switch (value['mode']) {
        'sos' => NativePatternMode.sos,
        'strobe' => NativePatternMode.strobe,
        _ => NativePatternMode.off,
      },
      paused: value['paused'] == true,
      torchOn: value['torchOn'] == true,
      available: value['available'] != false,
      shakeEnabled: value['shakeEnabled'] == true,
      shakeMonitoring: value['shakeMonitoring'] == true,
      backgroundServiceRunning: value['backgroundServiceRunning'] == true,
      notificationsEnabled: value['notificationsEnabled'] != false,
    );
  }

  final NativePatternMode mode;
  final bool paused;
  final bool torchOn;
  final bool available;
  final bool shakeEnabled;
  final bool shakeMonitoring;
  final bool backgroundServiceRunning;
  final bool notificationsEnabled;

  @override
  List<Object?> get props => [
    mode,
    paused,
    torchOn,
    available,
    shakeEnabled,
    shakeMonitoring,
    backgroundServiceRunning,
    notificationsEnabled,
  ];
}

/// Stream of changes made by the notification panel, Quick Settings tile,
/// widget, or native shake listener.
abstract interface class NativeControlsSource {
  Stream<NativeControlsSnapshot> get changes;
}

class MethodChannelNativeControls implements NativeControlsSource {
  MethodChannelNativeControls();

  static const EventChannel _events = EventChannel(
    'io.github.iamporag.flashlightpro/native_controls_state',
  );

  Stream<NativeControlsSnapshot>? _stream;

  @override
  Stream<NativeControlsSnapshot> get changes => _stream ??= _events
      .receiveBroadcastStream()
      .map(NativeControlsSnapshot.fromMap)
      .handleError((Object _) {})
      .distinct();
}

/// Used on platforms and in tests where no native control panel exists.
class UnsupportedNativeControls implements NativeControlsSource {
  const UnsupportedNativeControls();

  @override
  Stream<NativeControlsSnapshot> get changes =>
      const Stream<NativeControlsSnapshot>.empty();
}
