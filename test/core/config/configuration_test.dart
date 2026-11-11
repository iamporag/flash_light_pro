import 'dart:io';

import 'package:flash_light_pro/core/config/admob/admob_config.dart';
import 'package:flash_light_pro/core/config/admob/admob_ids.dart';
import 'package:flash_light_pro/core/config/admob/admob_policy.dart';
import 'package:flash_light_pro/core/config/app_info.dart';
import 'package:flash_light_pro/core/config/app_theme_config.dart';
import 'package:flash_light_pro/core/config/feature_config.dart';
import 'package:flash_light_pro/core/config/purchase_config.dart';
import 'package:flash_light_pro/features/monetization/application/ad_free_entitlement_service.dart';
import 'package:flash_light_pro/features/monetization/data/billing_gateway.dart';
import 'package:flash_light_pro/features/monetization/data/entitlement_store.dart';
import 'package:flash_light_pro/features/monetization/domain/ad_models.dart';
import 'package:flash_light_pro/features/monetization/domain/monetization_models.dart';
import 'package:flash_light_pro/features/settings/data/app_settings.dart';
import 'package:flash_light_pro/l10n/app_localizations_bn.dart';
import 'package:flash_light_pro/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final List<File> _libSources = Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .toList(growable: false);

bool _isGenerated(String path) =>
    path.endsWith('.g.dart') || path.contains('lib/l10n/app_localizations');

void main() {
  group('AdMob centralization', () {
    const productionIds = [
      AdMobIds.banner,
      AdMobIds.native,
      AdMobIds.interstitial,
      AdMobIds.rewarded,
      AdMobIds.appOpen,
    ];

    test('all five production unit ids are non-empty and unique', () {
      expect(productionIds, hasLength(5));
      expect(productionIds.toSet(), hasLength(5));
      for (final id in productionIds) {
        expect(id, startsWith('ca-app-pub-8125551545712066/'));
      }
    });

    test('production unit ids appear in exactly one Dart source', () {
      for (final id in productionIds) {
        final files = _libSources.where(
          (file) => file.readAsStringSync().contains(id),
        );
        expect(files.map((file) => file.path), [
          'lib/core/config/admob/admob_ids.dart',
        ], reason: id);
      }
    });

    test('Google test ids are confined to the AdMob id file', () {
      for (final id in AdMobIds.testAndroid.values) {
        final files = _libSources.where(
          (file) => file.readAsStringSync().contains(id),
        );
        expect(files.map((file) => file.path), [
          'lib/core/config/admob/admob_ids.dart',
        ], reason: id);
      }
    });

    test('the AdMob App ID stays out of Dart and in native configuration', () {
      final appId = RegExp(r'ca-app-pub-\d+~\d+');
      for (final file in _libSources.where(
        (file) => !_isGenerated(file.path),
      )) {
        expect(
          appId.hasMatch(file.readAsStringSync()),
          isFalse,
          reason: file.path,
        );
      }
      expect(
        File('android/gradle.properties').readAsStringSync(),
        contains('admobAppId=ca-app-pub-8125551545712066~2052695027'),
      );
    });

    test('production builds keep the compiled production ids', () {
      const config = AdConfig(
        testMode: false,
        androidUnitIds: {
          AdFormat.banner: AdMobIds.banner,
          AdFormat.native: AdMobIds.native,
          AdFormat.interstitial: AdMobIds.interstitial,
          AdFormat.rewarded: AdMobIds.rewarded,
          AdFormat.appOpen: AdMobIds.appOpen,
        },
        iosUnitIds: {},
      );

      expect(config.hasAnyUnitId, isTrue);
      for (final format in AdFormat.values) {
        expect(
          config.unitIdFor(format, platform: TargetPlatform.android),
          isNotNull,
          reason: '$format',
        );
      }
    });

    test('policy flags gate requests per format', () {
      final config = AdConfig.test().copyWithPolicy(
        const AdMobPolicy(
          bannerEnabled: false,
          interstitialEnabled: false,
          appOpenEnabled: false,
          rewardedEnabled: false,
        ),
      );

      for (final format in [
        AdFormat.banner,
        AdFormat.interstitial,
        AdFormat.appOpen,
        AdFormat.rewarded,
      ]) {
        expect(config.unitIdFor(format), isNull, reason: '$format');
      }
      expect(config.unitIdFor(AdFormat.native), isNotNull);
      expect(config.hasAnyUnitId, isTrue);
    });

    test('frequency and retry defaults are centralized and unchanged', () {
      const policy = AdMobPolicy.production;

      expect(policy.adsEnabled, isTrue);
      expect(policy.hasAnyFormatEnabled, isTrue);
      expect(policy.interstitialMinInterval, const Duration(minutes: 2));
      expect(policy.interstitialDailyCap, 5);
      expect(policy.interstitialActionInterval, 3);
      expect(policy.appOpenCooldown, const Duration(hours: 4));
      expect(policy.fullscreenCrossCooldown, const Duration(minutes: 2));
      expect(policy.interstitialActionDelay, const Duration(milliseconds: 350));
      expect(policy.startRetryInterval, const Duration(seconds: 20));
      expect(policy.preloadRetryInterval, const Duration(seconds: 15));
    });
  });

  group('Purchase centralization', () {
    test('the product id has one Dart source', () {
      expect(PurchaseConfig.removeAdsProductId, isNotEmpty);
      expect(
        AdFreeEntitlementService.productId,
        PurchaseConfig.removeAdsProductId,
      );

      final files = _libSources.where(
        (file) =>
            file.readAsStringSync().contains(PurchaseConfig.removeAdsProductId),
      );
      expect(files.map((file) => file.path), [
        'lib/core/config/purchase_config.dart',
      ]);
      expect(
        File(
          'lib/features/monetization/application/ad_free_entitlement_service.dart',
        ).readAsStringSync(),
        contains('PurchaseConfig.removeAdsProductId'),
      );
    });

    test('service timing defaults come from PurchaseConfig', () {
      final service = AdFreeEntitlementService(
        store: _NullStore(),
        gateway: _UnsupportedGateway(),
      );
      addTearDown(service.dispose);

      expect(service.restoreGrace, PurchaseConfig.restoreGrace);
      expect(service.purchaseTimeout, PurchaseConfig.purchaseTimeout);
      expect(PurchaseConfig.purchaseTimeout, const Duration(minutes: 10));
    });
  });

  group('AppInfo', () {
    test('exposes product metadata', () {
      expect(AppInfo.name, 'Flash Light Pro');
      expect(AppInfo.developer, 'ClaudySoft');
      expect(AppInfo.tagline, isNotEmpty);
      expect(AppInfo.description, isNotEmpty);
      expect(AppInfo.supportEmail, contains('@'));
      expect(AppInfo.website, startsWith('https://'));
      expect(AppInfo.privacyPolicyUrl, endsWith('/privacy.html'));
      expect(AppInfo.termsUrl, endsWith('/terms.html'));
    });

    test('package name matches the Android applicationId', () {
      final gradle = File('android/app/build.gradle').readAsStringSync();
      final applicationId = RegExp(r'applicationId\s*=\s*"([^"]+)"')
          .firstMatch(gradle)
          ?.group(1);
      expect(AppInfo.packageName, applicationId);
      expect(AppInfo.playStoreUrl, contains('id=${AppInfo.packageName}'));
    });

    test('version comes from the build and keeps a valid shape', () {
      expect(AppInfo.fullVersion, matches(RegExp(r'^\d+\.\d+\.\d+\+\d+$')));
      expect(AppInfo.fullVersion, '${AppInfo.version}+${AppInfo.buildNumber}');
      final pubspecVersion = RegExp(
        r'^version:\s*(\S+)\s*$',
        multiLine: true,
      ).firstMatch(File('pubspec.yaml').readAsStringSync())?.group(1);
      expect(pubspecVersion, isNotNull);
      expect(AppInfo.fullVersion, pubspecVersion);
    });

    test('all method channels use the package prefix', () {
      for (final channel in [
        AppInfo.deviceControlsChannel,
        AppInfo.torchStateChannel,
        AppInfo.backgroundTorchStateChannel,
        AppInfo.shakeMonitorStateChannel,
        AppInfo.nativeControlsStateChannel,
      ]) {
        expect(channel, startsWith('${AppInfo.packageName}/'));
      }
    });
  });

  group('Theme and features', () {
    test('theme keeps the published palette and shared tokens', () {
      expect(AppColors.accent, const Color(0xFFFFC94D));
      expect(AppColors.background, const Color(0xFF0A0F1E));
      expect(AppColors.surface, const Color(0xFF161D31));
      expect(AppColors.textPrimary, const Color(0xFFF4F6FF));
      expect(AppColors.textMuted, const Color(0xFF9BA5C2));
      expect(AppRadii.xl, 16);
      expect(AppSpacing.lg, 16);
    });

    test('buildAppTheme reflects the centralized colors', () {
      final theme = buildAppTheme();
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.colorScheme.primary, AppColors.accent);
      expect(theme.colorScheme.secondary, AppColors.accentAlt);
      expect(theme.colorScheme.surface, AppColors.surface);
      expect(theme.dividerTheme.color, AppColors.divider);
    });

    test('feature flags do not disable shipped features', () {
      expect(FeatureConfig.shakeToToggle, isTrue);
      expect(FeatureConfig.sosMode, isTrue);
      expect(FeatureConfig.strobeMode, isTrue);
      expect(FeatureConfig.morseMode, isTrue);
      expect(FeatureConfig.backgroundTorch, isTrue);
      expect(FeatureConfig.removeAds, isTrue);
      expect(FeatureConfig.appUpdates, isTrue);
    });

    test('first-run settings defaults come from FeatureConfig', () {
      const settings = AppSettings();
      expect(settings.hapticsEnabled, FeatureConfig.hapticsEnabledByDefault);
      expect(settings.shakeEnabled, FeatureConfig.shakeEnabledByDefault);
      expect(settings.keepScreenAwake, FeatureConfig.keepScreenAwakeByDefault);
      expect(
        settings.reduceAnimations,
        FeatureConfig.reduceAnimationsByDefault,
      );
      expect(
        settings.backgroundTorchEnabled,
        FeatureConfig.backgroundTorchEnabledByDefault,
      );
    });
  });

  group('Localization', () {
    test('the policy footer takes the version from AppInfo', () {
      final en = AppLocalizationsEn();
      final bn = AppLocalizationsBn();

      expect(en.privacyPolicyFooter('9.9.9'), contains('9.9.9'));
      expect(bn.privacyPolicyFooter('9.9.9'), contains('9.9.9'));
      expect(en.privacyPolicyFooter('9.9.9'), isNot(contains('0.1.0')));
    });

    test('no ARB file hardcodes the application version', () {
      for (final path in ['lib/l10n/app_en.arb', 'lib/l10n/app_bn.arb']) {
        expect(File(path).readAsStringSync(), isNot(contains('version 0.1')));
        expect(File(path).readAsStringSync(), isNot(contains('সংস্করণ 0.1')));
      }
    });

    test('screen color presets are translated in both languages', () {
      final en = AppLocalizationsEn();
      final bn = AppLocalizationsBn();

      expect(en.screenColorWarm, 'Warm');
      expect(bn.screenColorWarm, isNot(en.screenColorWarm));
      expect(en.screenColorSemantics('Warm'), 'Warm screen color');
      expect(bn.screenColorSemantics('উষ্ণ'), isNotEmpty);
    });
  });
}

class _NullStore implements AdFreeStore {
  @override
  Future<bool> loadOwned() async => false;

  @override
  Future<void> saveOwned(bool owned) async {}
}

class _UnsupportedGateway implements BillingGateway {
  @override
  bool get isSupported => false;

  @override
  Stream<BillingPurchase> get purchases => const Stream.empty();

  @override
  String? get lastQueryError => null;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<RemoveAdsProduct?> queryProduct(String productId) async => null;

  @override
  Future<void> buy(String productId) async {}

  @override
  Future<void> restore() async {}

  @override
  Future<void> complete(BillingPurchase purchase) async {}

  @override
  Future<void> dispose() async {}
}
