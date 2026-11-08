import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart' as play;

import '../domain/update_models.dart';

/// Thin boundary around the Google Play In-App Updates API so the update state
/// machine can be tested without platform channels.
abstract interface class UpdateGateway {
  bool get isSupported;

  Future<UpdateInfo> checkForUpdate();

  Future<UpdateFlowResult> startImmediateUpdate();

  Future<UpdateFlowResult> startFlexibleUpdate();

  Future<void> completeFlexibleUpdate();

  Stream<UpdateInstallStatus> get installStatusStream;
}

class PlayUpdateGateway implements UpdateGateway {
  const PlayUpdateGateway();

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<UpdateInfo> checkForUpdate() async {
    if (!isSupported) return const UpdateInfo.unsupported();

    final info = await play.InAppUpdate.checkForUpdate();
    return UpdateInfo(
      availability: _mapAvailability(info.updateAvailability),
      availableVersionCode: info.availableVersionCode,
      updatePriority: info.updatePriority,
      immediateAllowed: info.immediateUpdateAllowed,
      flexibleAllowed: info.flexibleUpdateAllowed,
      stalenessDays: info.clientVersionStalenessDays,
      installStatus: _mapInstallStatus(info.installStatus),
    );
  }

  @override
  Future<UpdateFlowResult> startImmediateUpdate() async {
    final result = await play.InAppUpdate.performImmediateUpdate();
    return _mapFlowResult(result);
  }

  @override
  Future<UpdateFlowResult> startFlexibleUpdate() async {
    final result = await play.InAppUpdate.startFlexibleUpdate();
    return _mapFlowResult(result);
  }

  @override
  Future<void> completeFlexibleUpdate() {
    return play.InAppUpdate.completeFlexibleUpdate();
  }

  @override
  Stream<UpdateInstallStatus> get installStatusStream {
    if (!isSupported) {
      return const Stream<UpdateInstallStatus>.empty();
    }
    return play.InAppUpdate.installUpdateListener.map(_mapInstallStatus);
  }

  UpdateAvailability _mapAvailability(play.UpdateAvailability value) {
    return switch (value) {
      play.UpdateAvailability.updateAvailable => UpdateAvailability.available,
      play.UpdateAvailability.updateNotAvailable =>
        UpdateAvailability.unavailable,
      play.UpdateAvailability.developerTriggeredUpdateInProgress =>
        UpdateAvailability.inProgress,
      play.UpdateAvailability.unknown => UpdateAvailability.unavailable,
    };
  }

  UpdateInstallStatus _mapInstallStatus(play.InstallStatus value) {
    return switch (value) {
      play.InstallStatus.unknown => UpdateInstallStatus.unknown,
      play.InstallStatus.pending => UpdateInstallStatus.pending,
      play.InstallStatus.downloading => UpdateInstallStatus.downloading,
      play.InstallStatus.installing => UpdateInstallStatus.installing,
      play.InstallStatus.installed => UpdateInstallStatus.installed,
      play.InstallStatus.failed => UpdateInstallStatus.failed,
      play.InstallStatus.canceled => UpdateInstallStatus.canceled,
      play.InstallStatus.downloaded => UpdateInstallStatus.downloaded,
    };
  }

  UpdateFlowResult _mapFlowResult(play.AppUpdateResult result) {
    return switch (result) {
      play.AppUpdateResult.success => UpdateFlowResult.success,
      play.AppUpdateResult.userDeniedUpdate => UpdateFlowResult.userDenied,
      play.AppUpdateResult.inAppUpdateFailed => UpdateFlowResult.failed,
    };
  }
}
