import 'package:flash_light_pro/features/shake/domain/shake_detector.dart';
import 'package:flash_light_pro/features/shake/domain/shake_sensitivity.dart';
import 'package:flutter_test/flutter_test.dart';

const double _gravity = 9.80665;

ShakeDetector detector({
  ShakeSensitivity sensitivity = ShakeSensitivity.medium,
  Duration cooldown = const Duration(milliseconds: 1200),
}) {
  return ShakeDetector(sensitivity: sensitivity, cooldown: cooldown);
}

/// A sample whose magnitude differs from gravity by [deviation].
bool sample(ShakeDetector detector, double deviation, DateTime at) {
  return detector.addSample(0, 0, _gravity + deviation, at);
}

void main() {
  final start = DateTime(2026, 1, 1, 12);

  group('ShakeDetector', () {
    test('resting and slow movement never count as a shake', () {
      final subject = detector();

      expect(sample(subject, 0, start), isFalse);
      expect(
        sample(subject, 0.5, start.add(const Duration(milliseconds: 16))),
        isFalse,
      );
      expect(
        sample(subject, 2.9, start.add(const Duration(milliseconds: 32))),
        isFalse,
      );
    });

    test('a jolt below the sensitivity threshold does not count', () {
      final subject = detector();

      expect(sample(subject, 5, start), isFalse);
    });

    test('a deliberate jolt fires once', () {
      final subject = detector();

      expect(sample(subject, 14, start), isTrue);
      expect(
        sample(subject, 14, start.add(const Duration(milliseconds: 16))),
        isFalse,
      );
    });

    test('the phone must settle before another shake is armed', () {
      final subject = detector();

      expect(sample(subject, 14, start), isTrue);
      // Still shaking two seconds later, without a quiet sample in between.
      expect(
        sample(subject, 14, start.add(const Duration(seconds: 2))),
        isFalse,
      );

      expect(
        sample(subject, 0, start.add(const Duration(seconds: 3))),
        isFalse,
      );
      expect(
        sample(subject, 14, start.add(const Duration(seconds: 4))),
        isTrue,
      );
    });

    test('the cooldown suppresses shakes even after settling', () {
      final subject = detector();

      expect(sample(subject, 14, start), isTrue);
      expect(
        sample(subject, 0, start.add(const Duration(milliseconds: 100))),
        isFalse,
      );
      expect(
        sample(subject, 14, start.add(const Duration(milliseconds: 500))),
        isFalse,
      );
      expect(
        sample(subject, 14, start.add(const Duration(milliseconds: 1200))),
        isTrue,
      );
    });

    test('sensitivity changes how hard the phone must be shaken', () {
      final low = detector(sensitivity: ShakeSensitivity.low);
      final medium = detector(sensitivity: ShakeSensitivity.medium);
      final high = detector(sensitivity: ShakeSensitivity.high);

      expect(sample(low, 14, start), isFalse);
      expect(sample(medium, 14, start), isTrue);
      expect(sample(high, 10, start), isTrue);
      expect(sample(medium, 10, start), isFalse);
    });

    test('reset clears the cooldown and arms the detector again', () {
      final subject = detector();

      expect(sample(subject, 14, start), isTrue);
      subject.reset();
      expect(
        sample(subject, 14, start.add(const Duration(milliseconds: 10))),
        isTrue,
      );
    });

    test('small wobble above the rearm threshold does not rearm', () {
      final subject = detector();

      expect(sample(subject, 14, start), isTrue);
      // 4 m/s² is above rearmThreshold (3.0) and below the 13 threshold.
      expect(
        sample(subject, 4, start.add(const Duration(seconds: 2))),
        isFalse,
      );
      // Still disarmed, so even a hard jolt is ignored.
      expect(
        sample(subject, 14, start.add(const Duration(seconds: 3))),
        isFalse,
      );
      // A quiet sample rearms it.
      expect(
        sample(subject, 1, start.add(const Duration(seconds: 4))),
        isFalse,
      );
      expect(
        sample(subject, 14, start.add(const Duration(seconds: 5))),
        isTrue,
      );
    });
  });
}
