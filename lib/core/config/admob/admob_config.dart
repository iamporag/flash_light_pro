import 'package:flutter/foundation.dart';

import '../../../features/monetization/domain/ad_models.dart';
import 'admob_ids.dart';
import 'admob_policy.dart';

const String _androidBannerId = String.fromEnvironment(
  'ADMOB_ANDROID_BANNER_ID',
);
const String _androidNativeId = String.fromEnvironment(
  'ADMOB_ANDROID_NATIVE_ID',
);
const String _androidInterstitialId = String.fromEnvironment(
  'ADMOB_ANDROID_INTERSTITIAL_ID',
);
const String _androidRewardedId = String.fromEnvironment(
  'ADMOB_ANDROID_REWARDED_ID',
);
const String _androidAppOpenId = String.fromEnvironment(
  'ADMOB_ANDROID_APP_OPEN_ID',
);
const String _iosBannerId = String.fromEnvironment('ADMOB_IOS_BANNER_ID');
const String _iosNativeId = String.fromEnvironment('ADMOB_IOS_NATIVE_ID');
const String _iosInterstitialId = String.fromEnvironment(
  'ADMOB_IOS_INTERSTITIAL_ID',
);
const String _iosRewardedId = String.fromEnvironment('ADMOB_IOS_REWARDED_ID');
const String _iosAppOpenId = String.fromEnvironment('ADMOB_IOS_APP_OPEN_ID');

/// Central configuration for every ad format, placement limit, and test mode.
///
/// Production unit IDs come from [AdMobIds]. A `--dart-define` override can
/// replace any single format, which keeps the ability to test against a
/// different AdMob account without editing code.
class AdConfig {
  const AdConfig({
    required this.testMode,
    required this.androidUnitIds,
    required this.iosUnitIds,
    this.testDeviceIds = const [],
    this.policy = AdMobPolicy.production,
  });

  factory AdConfig.test({List<String> testDeviceIds = const []}) {
    return AdConfig(
      testMode: true,
      androidUnitIds: {
        for (final entry in AdMobIds.testAndroid.entries)
          AdFormat.values.byName(entry.key): entry.value,
      },
      iosUnitIds: {
        for (final entry in AdMobIds.testIos.entries)
          AdFormat.values.byName(entry.key): entry.value,
      },
      testDeviceIds: testDeviceIds,
    );
  }

  /// Debug and profile builds use Google's sample IDs. Release builds use the
  /// production IDs from [AdMobIds] unless `--dart-define` supplies different
  /// ones.
  factory AdConfig.fromEnvironment({
    AdMobPolicy policy = AdMobPolicy.production,
  }) {
    const forceTest = bool.fromEnvironment('ADMOB_TEST_MODE');
    const deviceIds = String.fromEnvironment('ADMOB_TEST_DEVICE_IDS');
    final useTestIds = kDebugMode || (forceTest && !kReleaseMode);

    if (useTestIds) {
      return AdConfig.test(testDeviceIds: _splitIds(deviceIds))
          .copyWithPolicy(policy);
    }

    return AdConfig(
      testMode: false,
      androidUnitIds: _merge(
        const {
          AdFormat.banner: _androidBannerId,
          AdFormat.native: _androidNativeId,
          AdFormat.interstitial: _androidInterstitialId,
          AdFormat.rewarded: _androidRewardedId,
          AdFormat.appOpen: _androidAppOpenId,
        },
        const {
          AdFormat.banner: AdMobIds.banner,
          AdFormat.native: AdMobIds.native,
          AdFormat.interstitial: AdMobIds.interstitial,
          AdFormat.rewarded: AdMobIds.rewarded,
          AdFormat.appOpen: AdMobIds.appOpen,
        },
      ),
      iosUnitIds: const {
        AdFormat.banner: _iosBannerId,
        AdFormat.native: _iosNativeId,
        AdFormat.interstitial: _iosInterstitialId,
        AdFormat.rewarded: _iosRewardedId,
        AdFormat.appOpen: _iosAppOpenId,
      },
      testDeviceIds: _splitIds(deviceIds),
      policy: policy,
    );
  }

  final bool testMode;
  final Map<AdFormat, String> androidUnitIds;
  final Map<AdFormat, String> iosUnitIds;
  final List<String> testDeviceIds;
  final AdMobPolicy policy;

  Duration get interstitialMinInterval => policy.interstitialMinInterval;
  int get interstitialDailyCap => policy.interstitialDailyCap;
  Duration get appOpenCooldown => policy.appOpenCooldown;
  Duration get fullscreenCrossCooldown => policy.fullscreenCrossCooldown;
  int get interstitialActionInterval => policy.interstitialActionInterval;

  AdConfig copyWithPolicy(AdMobPolicy policy) {
    return AdConfig(
      testMode: testMode,
      androidUnitIds: androidUnitIds,
      iosUnitIds: iosUnitIds,
      testDeviceIds: testDeviceIds,
      policy: policy,
    );
  }

  bool isFormatEnabled(AdFormat format) {
    if (!policy.adsEnabled) return false;
    return switch (format) {
      AdFormat.banner => policy.bannerEnabled,
      AdFormat.native => policy.nativeEnabled,
      AdFormat.interstitial => policy.interstitialEnabled,
      AdFormat.rewarded => policy.rewardedEnabled,
      AdFormat.appOpen => policy.appOpenEnabled,
    };
  }

  String? unitIdFor(AdFormat format, {TargetPlatform? platform}) {
    if (!isFormatEnabled(format)) return null;
    final target = platform ?? defaultTargetPlatform;
    final ids = switch (target) {
      TargetPlatform.android => androidUnitIds,
      TargetPlatform.iOS => iosUnitIds,
      _ => const <AdFormat, String>{},
    };
    final id = ids[format];
    return id == null || id.isEmpty ? null : id;
  }

  bool hasUnitId(AdFormat format) => unitIdFor(format) != null;

  bool get hasAnyUnitId {
    if (!policy.adsEnabled || !policy.hasAnyFormatEnabled) return false;
    return AdFormat.values.any((format) {
      return isFormatEnabled(format) &&
          ((androidUnitIds[format] ?? '').isNotEmpty ||
              (iosUnitIds[format] ?? '').isNotEmpty);
    });
  }

  static List<String> _splitIds(String raw) {
    return raw
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  /// `--dart-define` overrides win per format; otherwise the default is used.
  static Map<AdFormat, String> _merge(
    Map<AdFormat, String> overrides,
    Map<AdFormat, String> defaults,
  ) {
    return {
      for (final entry in defaults.entries)
        entry.key: (overrides[entry.key] ?? '').isEmpty
            ? entry.value
            : overrides[entry.key]!,
    };
  }
}
