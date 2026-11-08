import 'package:flash_light_pro/features/lighting/domain/lighting_defaults.dart';
import 'package:flash_light_pro/features/morse/domain/morse_codec.dart';
import 'package:flash_light_pro/features/morse/domain/morse_pattern.dart';
import 'package:flash_light_pro/features/sequences/domain/light_step.dart';
import 'package:flash_light_pro/features/sos/domain/sos_pattern.dart';
import 'package:flash_light_pro/features/strobe/domain/strobe_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lighting defaults', () {
    test('clamps brightness, torch level, and strobe interval', () {
      expect(LightingDefaults.clampBrightness(0), 0.05);
      expect(LightingDefaults.clampBrightness(2), 1.0);
      expect(LightingDefaults.clampTorchLevel(-1), 0.0);
      expect(LightingDefaults.clampTorchLevel(2), 1.0);
      expect(LightingDefaults.clampStrobeInterval(10), 200);
      expect(LightingDefaults.clampStrobeInterval(5000), 1000);
    });

    test('forces colors to be opaque', () {
      expect(LightingDefaults.opaqueColor(0x00112233), 0xFF112233);
      expect(LightingDefaults.opaqueColor(0xFF445566), 0xFF445566);
    });

    test('converts strobe intervals to hertz', () {
      expect(LightingDefaults.strobeFrequencyHz(400), 2.5);
      expect(LightingDefaults.strobeFrequencyHz(1000), 1.0);
    });
  });

  group('SOS pattern', () {
    final steps = SosPattern.build();

    test('uses nine signals with standard durations', () {
      expect(steps.length, 18);
      expect(steps.where((step) => step.isOn).length, 9);
      expect(steps.where((step) => step.isOn).map((step) => step.duration), [
        ...List.filled(3, const Duration(milliseconds: 180)),
        ...List.filled(3, const Duration(milliseconds: 540)),
        ...List.filled(3, const Duration(milliseconds: 180)),
      ]);
    });

    test('ends with a cycle gap', () {
      expect(steps.last.isOn, isFalse);
      expect(steps.last.duration, const Duration(milliseconds: 1800));
    });

    test('keeps letter gaps between groups', () {
      expect(
        steps
            .where(
              (step) =>
                  !step.isOn &&
                  step.duration == const Duration(milliseconds: 540),
            )
            .length,
        2,
      );
    });
  });

  group('strobe pattern', () {
    test('splits the interval evenly between on and off', () {
      final steps = StrobePattern.build(400);
      expect(steps.length, 2);
      expect(steps[0].isOn, isTrue);
      expect(steps[0].duration, const Duration(milliseconds: 200));
      expect(steps[1].isOn, isFalse);
      expect(steps[1].duration, const Duration(milliseconds: 200));
    });

    test('keeps each visible pulse at least 50 ms', () {
      for (final interval in [50, 200, 400, 1000, 5000]) {
        final steps = StrobePattern.build(interval);
        final onMs = steps[0].duration.inMilliseconds;
        final totalMs = onMs + steps[1].duration.inMilliseconds;
        expect(onMs, greaterThanOrEqualTo(50));
        expect(totalMs, inInclusiveRange(200, 1000));
      }
    });
  });

  group('Morse codec', () {
    test('encodes letters and words', () {
      final result = MorseCodec.encode('hello world');
      expect(result.morse, '.... . .-.. .-.. --- / .-- --- .-. .-.. -..');
      expect(result.unsupported, isEmpty);
      expect(result.isPlayable, isTrue);
    });

    test('encodes digits and ignores case', () {
      final result = MorseCodec.encode('sos 123');
      expect(result.morse, '... --- ... / .---- ..--- ...--');
      expect(result.isPlayable, isTrue);
    });

    test('reports unsupported characters without blocking valid ones', () {
      final result = MorseCodec.encode('A@B#');
      expect(result.morse, '.- -...');
      expect(result.unsupported, ['#', '@']);
      expect(result.isPlayable, isFalse);
    });

    test('treats empty or invalid input as not playable', () {
      expect(MorseCodec.encode('   ').isPlayable, isFalse);
      expect(MorseCodec.encode('@').isPlayable, isFalse);
      expect(MorseCodec.encode('@').morse, isEmpty);
    });
  });

  group('Morse pattern', () {
    test('uses 1:3:7 unit timing', () {
      const unit = Duration(milliseconds: 200);
      final steps = MorsePattern.build('.- / -...', unit: unit);

      expect(
        steps.firstWhere((step) => step.isOn).duration,
        const Duration(milliseconds: 200),
      );
      expect(
        steps.where((step) => step.isOn).map((step) => step.duration),
        const [
          Duration(milliseconds: 200),
          Duration(milliseconds: 600),
          Duration(milliseconds: 600),
          Duration(milliseconds: 200),
          Duration(milliseconds: 200),
          Duration(milliseconds: 200),
        ],
      );
      expect(
        steps.where(
          (step) =>
              !step.isOn && step.duration == const Duration(milliseconds: 1400),
        ),
        hasLength(1),
      );
    });

    test('ends with a short silence so playback stops promptly', () {
      final steps = MorsePattern.build('...');
      expect(steps.last.isOn, isFalse);
      expect(steps.last.duration, LightingDefaults.morseUnit);
    });

    test('returns no steps for empty input', () {
      expect(MorsePattern.build('  '), isEmpty);
      expect(MorsePattern.build(''), isEmpty);
    });

    test('every step has a positive duration', () {
      final steps = MorsePattern.build('SOS 123 / TEST');
      expect(steps, isNotEmpty);
      expect(steps.every((step) => step.duration > Duration.zero), isTrue);
      expect(steps, everyElement(isA<LightStep>()));
    });
  });
}
