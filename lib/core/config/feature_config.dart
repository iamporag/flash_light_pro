/// Product feature switches and the defaults applied to first-run settings.
///
/// Every flag currently ships enabled, preserving the published behaviour.
/// Platform-only features (Quick Settings tile, notification controls) are
/// configured in the Android manifest and native resources, so they are not
/// repeated here as unused Dart flags.
abstract final class FeatureConfig {
  static const bool shakeToToggle = true;
  static const bool sosMode = true;
  static const bool strobeMode = true;
  static const bool morseMode = true;
  static const bool backgroundTorch = true;
  static const bool removeAds = true;
  static const bool appUpdates = true;

  static const bool hapticsEnabledByDefault = true;
  static const bool shakeEnabledByDefault = false;
  static const bool keepScreenAwakeByDefault = true;
  static const bool reduceAnimationsByDefault = false;
  static const bool backgroundTorchEnabledByDefault = true;
}
