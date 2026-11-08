import 'package:flash_light_pro/features/updates/domain/app_version.dart';
import 'package:flash_light_pro/features/updates/domain/update_config.dart';
import 'package:flash_light_pro/features/updates/domain/update_models.dart';
import 'package:flash_light_pro/features/updates/domain/update_policy.dart';
import 'package:flutter_test/flutter_test.dart';

UpdateInfo available({
  int versionCode = 11,
  int priority = 0,
  bool immediate = false,
  bool flexible = true,
}) {
  return UpdateInfo(
    availability: UpdateAvailability.available,
    availableVersionCode: versionCode,
    updatePriority: priority,
    immediateAllowed: immediate,
    flexibleAllowed: flexible,
  );
}

void main() {
  final current = AppVersion.tryParse('1.2.3+10')!;

  UpdatePolicy policy({
    String minimum = '1.0.0',
    int mandatoryPriority = 5,
    int recommendedPriority = 3,
  }) {
    return UpdatePolicy(
      config: UpdateConfig(
        minimumSupportedVersion: minimum,
        mandatoryPriority: mandatoryPriority,
        recommendedPriority: recommendedPriority,
      ),
      currentVersion: current,
    );
  }

  group('UpdatePolicy levels', () {
    test('no update when Play reports none or an older build', () {
      expect(
        policy().evaluate(
          const UpdateInfo(availability: UpdateAvailability.unavailable),
        ),
        UpdateUrgency.none,
      );
      expect(
        policy().evaluate(available(versionCode: 10)),
        UpdateUrgency.none,
        reason: 'A version code equal to the installed build is not an update.',
      );
      expect(policy().evaluate(available(versionCode: 9)), UpdateUrgency.none);
    });

    test('optional update for a newer build with low priority', () {
      expect(policy().evaluate(available()), UpdateUrgency.optional);
    });

    test('recommended update at the configured priority', () {
      expect(
        policy().evaluate(available(priority: 3)),
        UpdateUrgency.recommended,
      );
    });

    test('mandatory update at the configured priority', () {
      expect(
        policy().evaluate(available(priority: 5)),
        UpdateUrgency.mandatory,
      );
    });

    test('mandatory when the installed version is below the minimum', () {
      final belowMinimum = UpdatePolicy(
        config: const UpdateConfig(minimumSupportedVersion: '2.0.0'),
        currentVersion: current,
      );

      expect(belowMinimum.isBelowMinimum, isTrue);
      expect(
        belowMinimum.evaluate(available(priority: 0)),
        UpdateUrgency.mandatory,
      );
    });

    test('invalid minimum version strings are ignored safely', () {
      final invalid = UpdatePolicy(
        config: const UpdateConfig(minimumSupportedVersion: 'not-a-version'),
        currentVersion: current,
      );

      expect(invalid.isBelowMinimum, isFalse);
      expect(invalid.evaluate(available()), UpdateUrgency.optional);
    });

    test('a build-number minimum is enforced', () {
      final buildMinimum = UpdatePolicy(
        config: const UpdateConfig(minimumSupportedVersion: '1.2.3+11'),
        currentVersion: current,
      );

      expect(buildMinimum.isBelowMinimum, isTrue);
    });
  });
}
