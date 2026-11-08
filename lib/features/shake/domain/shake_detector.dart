import 'dart:math' as math;

import 'shake_sensitivity.dart';

/// Pure, timestamp-driven shake detection. Keeping this free of platform code
/// makes the debounce and threshold behaviour unit-testable.
class ShakeDetector {
  ShakeDetector({
    required this.sensitivity,
    this.cooldown = const Duration(milliseconds: 1200),
    this.rearmThreshold = 3.0,
  });

  static const double _gravity = 9.80665;

  ShakeSensitivity sensitivity;
  final Duration cooldown;

  /// The phone must settle below this deviation before another shake counts.
  final double rearmThreshold;

  DateTime? _lastShakeAt;
  bool _armed = true;

  /// Returns true at most once per [cooldown], and only after the phone has
  /// settled since the previous shake.
  bool addSample(double x, double y, double z, DateTime at) {
    final magnitude = math.sqrt(x * x + y * y + z * z);
    final deviation = (magnitude - _gravity).abs();

    if (deviation <= rearmThreshold) {
      _armed = true;
      return false;
    }

    if (!_armed || deviation < sensitivity.threshold) return false;

    final last = _lastShakeAt;
    if (last != null && at.difference(last) < cooldown) return false;

    _lastShakeAt = at;
    _armed = false;
    return true;
  }

  void reset() {
    _lastShakeAt = null;
    _armed = true;
  }
}
