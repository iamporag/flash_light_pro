import '../../lighting/domain/lighting_defaults.dart';
import '../../sequences/domain/light_step.dart';

/// Turns a Morse string (dots, dashes, letter spaces, `/` word gaps) into
/// timed light steps. Timing follows the standard 1:3:7 unit ratio.
abstract final class MorsePattern {
  static List<LightStep> build(
    String morse, {
    Duration unit = LightingDefaults.morseUnit,
  }) {
    final trimmed = morse.trim();
    if (trimmed.isEmpty) return const [];

    final steps = <LightStep>[];

    void addSymbol(bool isOn, Duration duration) {
      steps.add(LightStep(isOn: isOn, duration: duration));
    }

    void replaceTrailingGap(Duration gap) {
      if (steps.isNotEmpty && !steps.last.isOn) {
        steps[steps.length - 1] = LightStep(isOn: false, duration: gap);
      } else {
        steps.add(LightStep(isOn: false, duration: gap));
      }
    }

    for (final token in trimmed.split(RegExp(r' +'))) {
      if (token == '/') {
        replaceTrailingGap(unit * 7);
        continue;
      }

      for (final symbol in token.split('')) {
        if (symbol == '.') {
          addSymbol(true, unit);
        } else if (symbol == '-') {
          addSymbol(true, unit * 3);
        }
        addSymbol(false, unit);
      }
      replaceTrailingGap(unit * 3);
    }

    // Keep the final silence short so the player stops promptly.
    replaceTrailingGap(unit);
    return List.unmodifiable(steps);
  }
}
