import 'package:flash_light_pro/features/monetization/application/monetization_start_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool canStart({
    bool updateSupported = true,
    bool sawUpdateCheck = true,
    bool updateCheckInProgress = false,
    bool mandatoryUpdateActive = false,
    bool lightActive = false,
    bool essentialInitialization = false,
    bool appResumed = true,
    bool allowBeforeFirstCheck = false,
  }) {
    return canStartMonetization(
      updateSupported: updateSupported,
      sawUpdateCheck: sawUpdateCheck,
      updateCheckInProgress: updateCheckInProgress,
      mandatoryUpdateActive: mandatoryUpdateActive,
      lightActive: lightActive,
      essentialInitialization: essentialInitialization,
      appResumed: appResumed,
      allowBeforeFirstCheck: allowBeforeFirstCheck,
    );
  }

  group('canStartMonetization', () {
    test('a settled check with no blockers allows ads', () {
      expect(canStart(), isTrue);
    });

    test('a mandatory update blocks ads even after the check settled', () {
      expect(canStart(mandatoryUpdateActive: true), isFalse);
    });

    test('an in-progress update check blocks ads', () {
      expect(canStart(updateCheckInProgress: true), isFalse);
    });

    test('ads wait for the first update check when supported', () {
      expect(canStart(sawUpdateCheck: false), isFalse);
      expect(
        canStart(sawUpdateCheck: false, allowBeforeFirstCheck: true),
        isTrue,
      );
    });

    test('unsupported platforms do not need an update check first', () {
      expect(canStart(updateSupported: false, sawUpdateCheck: false), isTrue);
    });

    test('an active light blocks ads', () {
      expect(canStart(lightActive: true), isFalse);
    });

    test('essential initialization and a backgrounded app block ads', () {
      expect(canStart(essentialInitialization: true), isFalse);
      expect(canStart(appResumed: false), isFalse);
    });
  });
}
