enum UpdateAvailability { unavailable, available, inProgress, unsupported }

enum UpdateUrgency { none, optional, recommended, mandatory }

enum UpdateInstallStatus {
  unknown,
  pending,
  downloading,
  installing,
  installed,
  failed,
  canceled,
  downloaded,
}

enum UpdateFlowResult { success, userDenied, failed }

enum UpdateFailure {
  unsupported,
  network,
  timeout,
  playStoreUnavailable,
  invalidResponse,
  flowFailed,
  installFailed,
  userCanceled,
  openStoreFailed,
  unknown,
}

/// Platform-neutral snapshot of what Google Play reports.
class UpdateInfo {
  const UpdateInfo({
    required this.availability,
    this.availableVersionCode,
    this.updatePriority = 0,
    this.immediateAllowed = false,
    this.flexibleAllowed = false,
    this.stalenessDays,
    this.installStatus = UpdateInstallStatus.unknown,
  });

  const UpdateInfo.unsupported()
    : availability = UpdateAvailability.unsupported,
      availableVersionCode = null,
      updatePriority = 0,
      immediateAllowed = false,
      flexibleAllowed = false,
      stalenessDays = null,
      installStatus = UpdateInstallStatus.unknown;

  final UpdateAvailability availability;
  final int? availableVersionCode;
  final int updatePriority;
  final bool immediateAllowed;
  final bool flexibleAllowed;
  final int? stalenessDays;
  final UpdateInstallStatus installStatus;
}

/// Last successful decision, kept so a temporary network failure cannot turn a
/// verified mandatory update into an unverified one.
class TrustedUpdatePolicy {
  const TrustedUpdatePolicy({
    required this.urgency,
    required this.verifiedAt,
    this.availableVersionCode,
    this.updatePriority = 0,
  });

  final UpdateUrgency urgency;
  final DateTime verifiedAt;
  final int? availableVersionCode;
  final int updatePriority;

  bool isFresh(DateTime now, Duration ttl) {
    final age = now.difference(verifiedAt);
    return !age.isNegative && age <= ttl;
  }
}
