import '../../lighting/domain/lighting_defaults.dart';
import '../../sequences/domain/light_step.dart';

abstract final class StrobePattern {
  static List<LightStep> build(int intervalMs) {
    final interval = LightingDefaults.clampStrobeInterval(intervalMs);
    final onMs = (interval / 2).round().clamp(50, interval - 50);
    return List.unmodifiable([
      LightStep(isOn: true, duration: Duration(milliseconds: onMs)),
      LightStep(isOn: false, duration: Duration(milliseconds: interval - onMs)),
    ]);
  }
}
