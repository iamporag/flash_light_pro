import 'package:flutter/foundation.dart';

import 'ad_models.dart';

/// Google's official sample ad unit IDs. They never earn revenue and are the
/// only IDs used by debug builds and tests.
abstract final class AdMobTestIds {
  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const Map<AdFormat, String> android = {
    AdFormat.banner: 'ca-app-pub-3940256099942544/6300978111',
    AdFormat.native: 'ca-app-pub-3940256099942544/2247696110',
    AdFormat.interstitial: 'ca-app-pub-3940256099942544/1033173712',
    AdFormat.rewarded: 'ca-app-pub-3940256099942544/5224354917',
    AdFormat.appOpen: 'ca-app-pub-3940256099942544/9257395921',
  };

  static const Map<AdFormat, String> ios = {
    AdFormat.banner: 'ca-app-pub-3940256099942544/2934735716',
    AdFormat.native: 'ca-app-pub-3940256099942544/3986624511',
    AdFormat.interstitial: 'ca-app-pub-3940256099942544/4411468910',
    AdFormat.rewarded: 'ca-app-pub-3940256099942544/1712485313',
    AdFormat.appOpen: 'ca-app-pub-3940256099942544/5662855259',
  };
}

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
/// Production unit IDs are supplied at build time. When they are absent the
/// app simply never requests ads, which keeps a misconfigured build safe and
/// keeps test IDs out of production.
class AdConfig {
  const AdConfig({
    required this.testMode,
    required this.androidUnitIds,
    required this.iosUnitIds,
    this.testDeviceIds = const [],
    this.interstitialMinInterval = const Duration(minutes: 5),
    this.interstitialDailyCap = 3,
    this.appOpenCooldown = const Duration(hours: 4),
  });

  factory AdConfig.test({List<String> testDeviceIds = const []}) {
    return AdConfig(
      testMode: true,
      androidUnitIds: AdMobTestIds.android,
      iosUnitIds: AdMobTestIds.ios,
      testDeviceIds: testDeviceIds,
    );
  }

  /// Debug and profile builds use Google's sample IDs. Release builds use only
  /// IDs supplied with `--dart-define`, so a production build can never serve
  /// test ads by accident.
  factory AdConfig.fromEnvironment() {
    const forceTest = bool.fromEnvironment('ADMOB_TEST_MODE');
    const deviceIds = String.fromEnvironment('ADMOB_TEST_DEVICE_IDS');
    final useTestIds = kDebugMode || (forceTest && !kReleaseMode);

    if (useTestIds) {
      return AdConfig.test(testDeviceIds: _splitIds(deviceIds));
    }

    return AdConfig(
      testMode: false,
      androidUnitIds: const {
        AdFormat.banner: _androidBannerId,
        AdFormat.native: _androidNativeId,
        AdFormat.interstitial: _androidInterstitialId,
        AdFormat.rewarded: _androidRewardedId,
        AdFormat.appOpen: _androidAppOpenId,
      },
      iosUnitIds: const {
        AdFormat.banner: _iosBannerId,
        AdFormat.native: _iosNativeId,
        AdFormat.interstitial: _iosInterstitialId,
        AdFormat.rewarded: _iosRewardedId,
        AdFormat.appOpen: _iosAppOpenId,
      },
      testDeviceIds: _splitIds(deviceIds),
    );
  }

  final bool testMode;
  final Map<AdFormat, String> androidUnitIds;
  final Map<AdFormat, String> iosUnitIds;
  final List<String> testDeviceIds;
  final Duration interstitialMinInterval;
  final int interstitialDailyCap;
  final Duration appOpenCooldown;

  String? unitIdFor(AdFormat format, {TargetPlatform? platform}) {
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

  bool get hasAnyUnitId =>
      androidUnitIds.values.any((id) => id.isNotEmpty) ||
      iosUnitIds.values.any((id) => id.isNotEmpty);

  static List<String> _splitIds(String raw) {
    return raw
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }
}
