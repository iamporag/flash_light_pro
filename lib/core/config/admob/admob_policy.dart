/// Feature switches and request limits for every ad format.
///
/// Values mirror the behaviour that shipped before centralization: all formats
/// are on, an interstitial can appear every third approved action with a
/// two-minute gap and five per day, App Open is limited to once every four
/// hours, and the two fullscreen formats never appear within two minutes of
/// each other.
class AdMobPolicy {
  const AdMobPolicy({
    this.adsEnabled = true,
    this.bannerEnabled = true,
    this.interstitialEnabled = true,
    this.appOpenEnabled = true,
    this.rewardedEnabled = true,
    this.nativeEnabled = true,
    this.interstitialMinInterval = const Duration(minutes: 2),
    this.interstitialDailyCap = 5,
    this.appOpenCooldown = const Duration(hours: 4),
    this.interstitialActionInterval = 3,
    this.fullscreenCrossCooldown = const Duration(minutes: 2),
    this.interstitialActionDelay = const Duration(milliseconds: 350),
    this.startRetryInterval = const Duration(seconds: 20),
    this.preloadRetryInterval = const Duration(seconds: 15),
  });

  static const AdMobPolicy production = AdMobPolicy();

  /// Master switch. When false no ad request, consent flow, or Remove Ads
  /// offer is started.
  final bool adsEnabled;

  final bool bannerEnabled;
  final bool interstitialEnabled;
  final bool appOpenEnabled;
  final bool rewardedEnabled;
  final bool nativeEnabled;

  final Duration interstitialMinInterval;
  final int interstitialDailyCap;
  final Duration appOpenCooldown;
  final int interstitialActionInterval;
  final Duration fullscreenCrossCooldown;

  /// Delay before an interstitial is shown after the qualifying action, so
  /// navigation completes first.
  final Duration interstitialActionDelay;

  /// Minimum gap between SDK start attempts while consent or the SDK is not
  /// ready.
  final Duration startRetryInterval;

  /// Minimum gap between preload attempts after an ad was blocked.
  final Duration preloadRetryInterval;

  bool get hasAnyFormatEnabled =>
      bannerEnabled ||
      interstitialEnabled ||
      appOpenEnabled ||
      rewardedEnabled ||
      nativeEnabled;
}
