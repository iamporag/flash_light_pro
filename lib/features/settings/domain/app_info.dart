/// Version values supplied by the Flutter tool at build time. The fallbacks
/// keep tests and debug runs working without a build context.
abstract final class AppInfo {
  static const String version = String.fromEnvironment(
    'FLUTTER_BUILD_NAME',
    defaultValue: '0.1.0',
  );

  static const String buildNumber = String.fromEnvironment(
    'FLUTTER_BUILD_NUMBER',
    defaultValue: '1',
  );

  static const String fullVersion = '$version+$buildNumber';
}
