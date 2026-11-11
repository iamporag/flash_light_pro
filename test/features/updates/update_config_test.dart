import 'package:flash_light_pro/features/updates/domain/update_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdateConfig', () {
    test('builds the Play Store URL from the application id', () {
      const config = UpdateConfig(playStoreId: 'com.claudysoft.flashlightpro');

      expect(
        config.playStoreUrl,
        'https://play.google.com/store/apps/details'
        '?id=com.claudysoft.flashlightpro',
      );
    });

    test('has no App Store link unless a real id is configured', () {
      expect(const UpdateConfig(appStoreId: '').appStoreUrl, isNull);
      expect(const UpdateConfig(appStoreId: '   ').appStoreUrl, isNull);
      expect(
        const UpdateConfig(appStoreId: '123456789').appStoreUrl,
        'https://apps.apple.com/app/id123456789',
      );
    });

    test('defaults keep only priority 5 mandatory', () {
      const config = UpdateConfig();

      expect(config.mandatoryPriority, 5);
      expect(config.recommendedPriority, 3);
      expect(config.recheckInterval, const Duration(hours: 6));
      expect(config.cachedPolicyTtl, const Duration(hours: 72));
      expect(config.bypassAfterFailedChecks, greaterThan(0));
    });
  });
}
