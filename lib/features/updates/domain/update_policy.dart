import 'app_version.dart';
import 'update_config.dart';
import 'update_models.dart';

/// Decides how urgently an update must be presented.
///
/// Only Play's verified availability (or the locally compiled minimum supported
/// version) can produce [UpdateUrgency.mandatory]. A network failure cannot.
class UpdatePolicy {
  UpdatePolicy({required this.config, required this.currentVersion})
    : _minimumSupported = AppVersion.tryParse(config.minimumSupportedVersion);

  final UpdateConfig config;
  final AppVersion currentVersion;
  final AppVersion? _minimumSupported;

  bool get isBelowMinimum {
    final minimum = _minimumSupported;
    return minimum != null && currentVersion.isOlderThan(minimum);
  }

  UpdateUrgency evaluate(UpdateInfo info) {
    if (info.availability != UpdateAvailability.available) {
      return UpdateUrgency.none;
    }

    if (!_isNewerThanInstalled(info.availableVersionCode)) {
      return UpdateUrgency.none;
    }

    if (isBelowMinimum) return UpdateUrgency.mandatory;
    if (info.updatePriority >= config.mandatoryPriority) {
      return UpdateUrgency.mandatory;
    }
    if (info.updatePriority >= config.recommendedPriority) {
      return UpdateUrgency.recommended;
    }
    return UpdateUrgency.optional;
  }

  bool _isNewerThanInstalled(int? availableVersionCode) {
    final installedBuild = currentVersion.build;
    if (availableVersionCode == null || installedBuild == null) return true;
    return availableVersionCode > installedBuild;
  }
}
