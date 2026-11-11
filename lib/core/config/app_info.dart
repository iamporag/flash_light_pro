/// Canonical application identity and runtime build metadata.
///
/// The version name and build number in `pubspec.yaml` are the single source of
/// truth. The Flutter tool injects them as `FLUTTER_BUILD_NAME` and
/// `FLUTTER_BUILD_NUMBER`; the fallbacks exist only for tests and IDE runs
/// without a build context. Increasing the build number (`versionCode`) is
/// required for every Play Store upload.
///
/// Localized UI text, including the visible app name, comes from the ARB files.
/// The native Android label remains in `res/values/strings.xml`. The values
/// here describe the product for code that needs identity without a build
/// context; they do not replace either source.
abstract final class AppInfo {
  static const String name = 'Flash Light Pro';
  static const String developer = 'ClaudySoft';
  static const String tagline = 'A reliable torch in your pocket.';
  static const String description =
      'Offline flashlight with screen light, SOS, strobe, Morse, timer, and '
      'system integrations.';

  /// Android applicationId. Native builds read the same value from
  /// `android/app/build.gradle`; a `--dart-define` override exists only for
  /// white-label builds.
  static const String packageName = String.fromEnvironment(
    'APP_PACKAGE_NAME',
    defaultValue: 'com.claudysoft.flashlightpro',
  );

  static const String supportEmail = 'sakibporag24@gmail.com';
  static const String website = 'https://iamporag.github.io/flash_light_pro/';
  static const String privacyPolicyUrl =
      'https://iamporag.github.io/flash_light_pro/privacy.html';
  static const String termsUrl =
      'https://iamporag.github.io/flash_light_pro/terms.html';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$packageName';

  // Kept in sync with pubspec.yaml by the fallback value; real builds always
  // receive the pubspec values through the Flutter tool.
  static const String version = String.fromEnvironment(
    'FLUTTER_BUILD_NAME',
    defaultValue: '0.1.1',
  );

  static const String buildNumber = String.fromEnvironment(
    'FLUTTER_BUILD_NUMBER',
    defaultValue: '2',
  );

  static const String fullVersion = '$version+$buildNumber';

  // MethodChannel names must match the Kotlin/Swift registrations, which
  // necessarily repeat the package prefix.
  static const String deviceControlsChannel = '$packageName/device_controls';
  static const String torchStateChannel = '$packageName/torch_state';
  static const String backgroundTorchStateChannel =
      '$packageName/background_torch_state';
  static const String shakeMonitorStateChannel =
      '$packageName/shake_monitor_state';
  static const String nativeControlsStateChannel =
      '$packageName/native_controls_state';
}
