/// The only Dart source of truth for AdMob ad unit IDs.
///
/// Ad unit IDs are public identifiers, not secrets, so the production Android
/// IDs are compiled into the app. The AdMob **App ID** is native configuration
/// and lives in `android/gradle.properties`, which injects it into the
/// manifest. It is deliberately not repeated here: an App ID and an ad unit ID
/// are different things and must never be mixed up.
abstract final class AdMobIds {
  // Production Android unit IDs, recovered from the published AdMob account.
  static const String banner = 'ca-app-pub-8125551545712066/8706742446';
  static const String native = 'ca-app-pub-8125551545712066/8911802759';
  static const String interstitial = 'ca-app-pub-8125551545712066/2699562288';
  static const String rewarded = 'ca-app-pub-8125551545712066/3906888086';
  static const String appOpen = 'ca-app-pub-8125551545712066/9267025974';

  /// Google's official sample IDs. They never earn revenue and are used only by
  /// debug builds, the `ADMOB_TEST_MODE` opt-in, and tests.
  static const Map<String, String> testAndroid = {
    'banner': 'ca-app-pub-3940256099942544/6300978111',
    'native': 'ca-app-pub-3940256099942544/2247696110',
    'interstitial': 'ca-app-pub-3940256099942544/1033173712',
    'rewarded': 'ca-app-pub-3940256099942544/5224354917',
    'appOpen': 'ca-app-pub-3940256099942544/9257395921',
  };

  static const Map<String, String> testIos = {
    'banner': 'ca-app-pub-3940256099942544/2934735716',
    'native': 'ca-app-pub-3940256099942544/3986624511',
    'interstitial': 'ca-app-pub-3940256099942544/4411468910',
    'rewarded': 'ca-app-pub-3940256099942544/1712485313',
    'appOpen': 'ca-app-pub-3940256099942544/5662855259',
  };
}
