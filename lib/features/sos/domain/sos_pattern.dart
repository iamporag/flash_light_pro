import '../../lighting/domain/lighting_defaults.dart';
import '../../sequences/domain/light_step.dart';

/// Standard Morse SOS (... --- ...) with letter and cycle gaps.
abstract final class SosPattern {
  static List<LightStep> build({
    Duration unit = LightingDefaults.sosUnit,
    Duration cycleGap = const Duration(milliseconds: 1800),
  }) {
    final steps = <LightStep>[];

    void addLetter(List<Duration> symbols) {
      for (var index = 0; index < symbols.length; index++) {
        steps.add(LightStep(isOn: true, duration: symbols[index]));
        steps.add(
          LightStep(
            isOn: false,
            duration: index == symbols.length - 1 ? unit * 3 : unit,
          ),
        );
      }
    }

    addLetter([unit, unit, unit]);
    addLetter([unit * 3, unit * 3, unit * 3]);
    addLetter([unit, unit, unit]);

    // The final gap separates repeated SOS cycles.
    steps[steps.length - 1] = LightStep(isOn: false, duration: cycleGap);
    return List.unmodifiable(steps);
  }
}
