import 'package:flash_light_pro/features/monetization/domain/ad_config.dart';
import 'package:flash_light_pro/features/monetization/domain/ad_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdConfig', () {
    test('test mode uses Google sample ids for every format', () {
      final config = AdConfig.test();

      expect(config.testMode, isTrue);
      expect(config.hasAnyUnitId, isTrue);
      for (final format in AdFormat.values) {
        expect(config.hasUnitId(format), isTrue, reason: '$format');
        expect(
          config.unitIdFor(format, platform: TargetPlatform.android),
          AdMobTestIds.android[format],
        );
        expect(
          config.unitIdFor(format, platform: TargetPlatform.iOS),
          AdMobTestIds.ios[format],
        );
      }
    });

    test('an empty id disables that format instead of requesting an ad', () {
      const config = AdConfig(
        testMode: false,
        androidUnitIds: {AdFormat.banner: ''},
        iosUnitIds: {},
      );

      expect(config.unitIdFor(AdFormat.banner), isNull);
      expect(config.hasAnyUnitId, isFalse);
    });

    test('a format missing from the platform map is unavailable', () {
      const config = AdConfig(
        testMode: false,
        androidUnitIds: {AdFormat.banner: 'android-banner'},
        iosUnitIds: {},
      );

      expect(config.unitIdFor(AdFormat.banner), 'android-banner');
      expect(
        config.unitIdFor(AdFormat.banner, platform: TargetPlatform.iOS),
        isNull,
      );
      expect(config.unitIdFor(AdFormat.native), isNull);
    });

    test('frequency defaults match the product requirements', () {
      final config = AdConfig.test();

      expect(config.interstitialMinInterval, const Duration(minutes: 5));
      expect(config.interstitialDailyCap, 3);
      expect(config.appOpenCooldown, const Duration(hours: 4));
    });

    test('debug builds resolve to test ids and never to production ids', () {
      final config = AdConfig.fromEnvironment();

      expect(kDebugMode, isTrue);
      expect(config.testMode, isTrue);
      expect(
        config.unitIdFor(
          AdFormat.interstitial,
          platform: TargetPlatform.android,
        ),
        AdMobTestIds.android[AdFormat.interstitial],
      );
    });
  });
}
