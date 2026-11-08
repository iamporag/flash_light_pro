import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../flashlight/services/torch_service.dart';
import '../domain/light_step.dart';

typedef SequenceDelay = Future<void> Function(Duration duration);

Future<void> _defaultDelay(Duration duration) => Future<void>.delayed(duration);

/// Runs a list of on/off steps against the torch or the screen.
///
/// The player owns exactly one session at a time. Starting or stopping bumps a
/// generation counter, so stale async work can never toggle the light again.
class SequencePlayer {
  SequencePlayer({required this.torchService, SequenceDelay? delay})
    : _delay = delay ?? _defaultDelay;

  final TorchService torchService;
  final SequenceDelay _delay;

  /// True while a screen-light fallback flash should be visible.
  final ValueNotifier<bool> screenFlash = ValueNotifier<bool>(false);

  int _session = 0;
  bool _running = false;
  bool _paused = false;
  bool _disposed = false;
  bool _claimedOutput = false;
  bool _useTorch = true;
  bool? _outputOn;
  Completer<void>? _pauseGate;

  bool get isRunning => _running;

  bool get isPaused => _paused;

  Future<void> play({
    required List<LightStep> steps,
    required bool useTorch,
    bool repeat = false,
    VoidCallback? onComplete,
    ValueChanged<TorchFailure>? onError,
  }) async {
    // Claim the session before the first await so a stop() issued while the
    // previous output is shutting down always wins over this new session.
    final session = ++_session;
    _running = false;
    await _forceOff();
    if (session != _session || steps.isEmpty || _disposed) return;

    _running = true;
    _paused = false;
    _useTorch = useTorch;
    _claimedOutput = true;
    _outputOn = null;

    try {
      do {
        for (final step in steps) {
          if (session != _session) return;

          await _setOutput(step.isOn, session);
          if (session != _session) return;

          await _delay(step.duration);
          if (session != _session) return;

          await _waitWhilePaused(session);
          if (session != _session) return;
        }
      } while (repeat);

      if (session != _session) return;
      _running = false;
      await _forceOff();
      onComplete?.call();
    } on TorchFailure catch (failure) {
      if (session != _session) return;
      _running = false;
      await _forceOff();
      onError?.call(failure);
    } catch (_) {
      if (session != _session) return;
      _running = false;
      await _forceOff();
      onError?.call(const TorchFailure(TorchFailureKind.unexpected));
    }
  }

  Future<void> pause() async {
    if (!_running || _paused || _disposed) return;
    _paused = true;
    _pauseGate = Completer<void>();
    try {
      // Do not hold a torch or a bright screen on while transmission is paused.
      await _setOutput(false, _session);
    } catch (_) {
      // The next session still forces the output off.
    }
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    final gate = _pauseGate;
    _pauseGate = null;
    if (gate != null && !gate.isCompleted) {
      gate.complete();
    }
  }

  Future<void> stop() async {
    _session++;
    _running = false;
    await _forceOff();
  }

  void dispose() {
    _disposed = true;
    _session++;
    _running = false;
    _pauseGate?.complete();
    _pauseGate = null;
    screenFlash.dispose();
  }

  Future<void> _setOutput(bool isOn, int session) async {
    if (session != _session || _outputOn == isOn) return;

    if (_useTorch) {
      if (isOn) {
        await torchService.enable();
      } else {
        await torchService.disable();
      }
    } else {
      _setScreenFlash(isOn);
    }
    _outputOn = isOn;
  }

  Future<void> _forceOff() async {
    _paused = false;
    final gate = _pauseGate;
    _pauseGate = null;
    if (gate != null && !gate.isCompleted) {
      gate.complete();
    }

    _outputOn = null;
    if (!_claimedOutput) {
      _setScreenFlash(false);
      return;
    }

    _claimedOutput = false;
    if (_useTorch) {
      try {
        await torchService.disable();
      } catch (_) {
        // Best effort; the next session re-checks hardware availability.
      }
    }
    _setScreenFlash(false);
  }

  Future<void> _waitWhilePaused(int session) async {
    while (_paused && session == _session) {
      final gate = _pauseGate;
      if (gate == null) return;
      await gate.future;
    }
  }

  void _setScreenFlash(bool value) {
    if (_disposed || screenFlash.value == value) return;
    screenFlash.value = value;
  }
}
