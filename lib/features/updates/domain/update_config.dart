import 'package:flash_light_pro/core/config/app_info.dart';

/// Central update policy configuration.
///
/// There is deliberately no default remote endpoint. The Play In-App Updates
/// API supplies availability and version codes; release priority is configured
/// through the Google Play Developer API. Bump [minimumSupportedVersion] only
/// for releases that must not be used any more.
class UpdateConfig {
  const UpdateConfig({
    this.playStoreId = defaultPlayStoreId,
    this.appStoreId = defaultAppStoreId,
    this.minimumSupportedVersion = AppInfo.version,
    this.mandatoryPriority = 5,
    this.recommendedPriority = 3,
    this.startupCheckDelay = const Duration(milliseconds: 1500),
    this.recheckInterval = const Duration(hours: 6),
    this.cachedPolicyTtl = const Duration(hours: 72),
    this.checkTimeout = const Duration(seconds: 10),
    this.bypassAfterFailedChecks = 2,
  }) : assert(mandatoryPriority >= 0 && mandatoryPriority <= 5),
       assert(recommendedPriority >= 0 && recommendedPriority <= 5),
       assert(bypassAfterFailedChecks > 0);

  /// Actual Android application id from `android/app/build.gradle`.
  static const String defaultPlayStoreId = String.fromEnvironment(
    'PLAY_STORE_ID',
    defaultValue: AppInfo.packageName,
  );

  /// Only used when a real numeric App Store id is supplied at build time.
  static const String defaultAppStoreId = String.fromEnvironment(
    'APP_STORE_ID',
  );

  final String playStoreId;
  final String appStoreId;
  final String minimumSupportedVersion;
  final int mandatoryPriority;
  final int recommendedPriority;
  final Duration startupCheckDelay;
  final Duration recheckInterval;
  final Duration cachedPolicyTtl;
  final Duration checkTimeout;
  final int bypassAfterFailedChecks;

  String get playStoreUrl =>
      'https://play.google.com/store/apps/details?id=$playStoreId';

  String? get appStoreUrl {
    final id = appStoreId.trim();
    return id.isEmpty ? null : 'https://apps.apple.com/app/id$id';
  }
}
