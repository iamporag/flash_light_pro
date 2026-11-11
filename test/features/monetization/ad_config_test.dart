import 'package:flash_light_pro/core/config/admob/admob_config.dart';
import 'package:flash_light_pro/core/config/admob/admob_ids.dart';
import 'package:flash_light_pro/core/config/admob/admob_policy.dart';
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
          AdMobIds.testAndroid[format.name],
        );
        expect(
          config.unitIdFor(format, platform: TargetPlatform.iOS),
          AdMobIds.testIos[format.name],
        );
      }
    });

    test('production ids are the exact five Android AdMob unit ids', () {
      const expected = {
        AdFormat.banner: 'ca-app-pub-8125551545712066/8706742446',
        AdFormat.native: 'ca-app-pub-8125551545712066/8911802759',
        AdFormat.interstitial: 'ca-app-pub-8125551545712066/2699562288',
        AdFormat.rewarded: 'ca-app-pub-8125551545712066/3906888086',
        AdFormat.appOpen: 'ca-app-pub-8125551545712066/9267025974',
      };

      expect(AdMobIds.banner, expected[AdFormat.banner]);
      expect(AdMobIds.native, expected[AdFormat.native]);
      expect(AdMobIds.interstitial, expected[AdFormat.interstitial]);
      expect(AdMobIds.rewarded, expected[AdFormat.rewarded]);
      expect(AdMobIds.appOpen, expected[AdFormat.appOpen]);
      expect(expected.values.toSet(), hasLength(5));
      for (final id in expected.values) {
        expect(id, startsWith('ca-app-pub-8125551545712066/'));
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

      expect(config.interstitialMinInterval, const Duration(minutes: 2));
      expect(config.interstitialDailyCap, 5);
      expect(config.interstitialActionInterval, 3);
      expect(config.appOpenCooldown, const Duration(hours: 4));
      expect(config.fullscreenCrossCooldown, const Duration(minutes: 2));
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
        AdMobIds.testAndroid['interstitial'],
      );
      expect(
        config.androidUnitIds.values,
        isNot(contains(AdMobIds.interstitial)),
      );
    });

    test('the master switch disables every format', () {
      final config = AdConfig.test().copyWithPolicy(
        const AdMobPolicy(adsEnabled: false),
      );

      expect(config.hasAnyUnitId, isFalse);
      for (final format in AdFormat.values) {
        expect(config.unitIdFor(format), isNull, reason: '$format');
      }
      expect(config.hasUnitId(AdFormat.banner), isFalse);
    });

    test('a disabled format is not requested but the others keep working', () {
      final config = AdConfig.test().copyWithPolicy(
        const AdMobPolicy(nativeEnabled: false),
      );

      expect(config.unitIdFor(AdFormat.native), isNull);
      expect(
        config.unitIdFor(AdFormat.banner, platform: TargetPlatform.android),
        AdMobIds.testAndroid['banner'],
      );
      expect(config.hasAnyUnitId, isTrue);
    });
  });
}
