import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/store_launcher.dart';
import '../data/update_gateway.dart';
import '../data/update_policy_store.dart';
import '../domain/app_version.dart';
import '../domain/update_config.dart';
import '../domain/update_models.dart';
import '../domain/update_policy.dart';

enum UpdatePhase {
  idle,
  checking,
  available,
  downloading,
  downloaded,
  installing,
  installed,
  upToDate,
}

class UpdateState extends Equatable {
  const UpdateState({
    required this.currentVersion,
    this.phase = UpdatePhase.idle,
    this.urgency = UpdateUrgency.none,
    this.availableVersionCode,
    this.updatePriority = 0,
    this.immediateAllowed = false,
    this.flexibleAllowed = false,
    this.dismissedForVersion = false,
    this.bypassedForVersion = false,
    this.canBypass = false,
    this.fromCache = false,
    this.verifiedAt,
    this.failure,
    this.isSupported = true,
  });

  static const Object _unset = Object();

  final AppVersion currentVersion;
  final UpdatePhase phase;
  final UpdateUrgency urgency;
  final int? availableVersionCode;
  final int updatePriority;
  final bool immediateAllowed;
  final bool flexibleAllowed;
  final bool dismissedForVersion;
  final bool bypassedForVersion;
  final bool canBypass;
  final bool fromCache;
  final DateTime? verifiedAt;
  final UpdateFailure? failure;
  final bool isSupported;

  bool get isMandatory => urgency == UpdateUrgency.mandatory;

  bool get shouldPrompt =>
      urgency != UpdateUrgency.none &&
      !dismissedForVersion &&
      !bypassedForVersion &&
      (phase == UpdatePhase.available ||
          phase == UpdatePhase.downloading ||
          phase == UpdatePhase.downloaded ||
          phase == UpdatePhase.installing);

  bool get isDownloading => phase == UpdatePhase.downloading;

  bool get isReadyToInstall => phase == UpdatePhase.downloaded;

  UpdateState copyWith({
    AppVersion? currentVersion,
    UpdatePhase? phase,
    UpdateUrgency? urgency,
    Object? availableVersionCode = _unset,
    int? updatePriority,
    bool? immediateAllowed,
    bool? flexibleAllowed,
    bool? dismissedForVersion,
    bool? bypassedForVersion,
    bool? canBypass,
    bool? fromCache,
    Object? verifiedAt = _unset,
    Object? failure = _unset,
    bool? isSupported,
  }) {
    return UpdateState(
      currentVersion: currentVersion ?? this.currentVersion,
      phase: phase ?? this.phase,
      urgency: urgency ?? this.urgency,
      availableVersionCode: identical(availableVersionCode, _unset)
          ? this.availableVersionCode
          : availableVersionCode as int?,
      updatePriority: updatePriority ?? this.updatePriority,
      immediateAllowed: immediateAllowed ?? this.immediateAllowed,
      flexibleAllowed: flexibleAllowed ?? this.flexibleAllowed,
      dismissedForVersion: dismissedForVersion ?? this.dismissedForVersion,
      bypassedForVersion: bypassedForVersion ?? this.bypassedForVersion,
      canBypass: canBypass ?? this.canBypass,
      fromCache: fromCache ?? this.fromCache,
      verifiedAt: identical(verifiedAt, _unset)
          ? this.verifiedAt
          : verifiedAt as DateTime?,
      failure: identical(failure, _unset)
          ? this.failure
          : failure as UpdateFailure?,
      isSupported: isSupported ?? this.isSupported,
    );
  }

  @override
  List<Object?> get props => [
    currentVersion,
    phase,
    urgency,
    availableVersionCode,
    updatePriority,
    immediateAllowed,
    flexibleAllowed,
    dismissedForVersion,
    bypassedForVersion,
    canBypass,
    fromCache,
    verifiedAt,
    failure,
    isSupported,
  ];
}

class UpdateCubit extends Cubit<UpdateState> {
  UpdateCubit({
    required UpdateGateway gateway,
    required UpdatePolicyStore store,
    required StoreLauncher storeLauncher,
    required UpdateConfig config,
    required AppVersion currentVersion,
    DateTime Function()? clock,
  }) : _gateway = gateway,
       // ignore: prefer_initializing_formals
       _store = store,
       // ignore: prefer_initializing_formals
       _storeLauncher = storeLauncher,
       _config = config,
       _clock = clock ?? DateTime.now,
       _policy = UpdatePolicy(config: config, currentVersion: currentVersion),
       super(
         UpdateState(
           currentVersion: currentVersion,
           isSupported: gateway.isSupported,
         ),
       );

  final UpdateGateway _gateway;
  final UpdatePolicyStore _store;
  final StoreLauncher _storeLauncher;
  final UpdateConfig _config;
  final DateTime Function() _clock;
  final UpdatePolicy _policy;

  bool _checking = false;
  bool _flowActive = false;
  bool _recheckOnResume = false;
  int _failedChecks = 0;
  DateTime? _lastCheckAt;
  StreamSubscription<UpdateInstallStatus>? _installSubscription;

  /// Startup and resume checks are throttled so activity recreation and widget
  /// rebuilds cannot hammer Play or stack dialogs.
  Future<void> checkForUpdate({bool force = false}) async {
    if (isClosed || _checking) return;
    if (!_gateway.isSupported) {
      _emit(state.copyWith(phase: UpdatePhase.idle, failure: null));
      return;
    }

    _checking = true;
    try {
      final now = _clock();
      final lastCheck = _lastCheckAt ?? await _store.loadLastCheckAt();
      _lastCheckAt = lastCheck;
      if (!force &&
          lastCheck != null &&
          now.difference(lastCheck) < _config.recheckInterval) {
        return;
      }
      if (isClosed) return;

      _emit(state.copyWith(phase: UpdatePhase.checking, failure: null));

      final info = await _gateway.checkForUpdate().timeout(
        _config.checkTimeout,
      );
      if (isClosed) return;

      await _applyInfo(info, now);
      _failedChecks = 0;
      _lastCheckAt = now;
      await _store.saveLastCheckAt(now);
    } on TimeoutException {
      await _handleCheckFailure(UpdateFailure.timeout);
    } on MissingPluginException {
      await _handleCheckFailure(UpdateFailure.unsupported);
    } on PlatformException {
      await _handleCheckFailure(UpdateFailure.playStoreUnavailable);
    } catch (_) {
      await _handleCheckFailure(UpdateFailure.unknown);
    } finally {
      _checking = false;
    }
  }

  /// Called when the app returns from the Play Store or the Play update flow.
  Future<void> onAppResumed() async {
    if (_recheckOnResume) {
      _recheckOnResume = false;
      await checkForUpdate(force: true);
      return;
    }
    await checkForUpdate();
  }

  Future<void> _applyInfo(UpdateInfo info, DateTime now) async {
    switch (info.availability) {
      case UpdateAvailability.unsupported:
        await _store.clearTrustedPolicy();
        _emit(
          state.copyWith(
            phase: UpdatePhase.idle,
            urgency: UpdateUrgency.none,
            availableVersionCode: null,
            dismissedForVersion: false,
            bypassedForVersion: false,
            canBypass: false,
            fromCache: false,
            verifiedAt: null,
            failure: null,
            isSupported: false,
          ),
        );
      case UpdateAvailability.unavailable:
        await _store.clearTrustedPolicy();
        _emit(
          state.copyWith(
            phase: UpdatePhase.upToDate,
            urgency: UpdateUrgency.none,
            availableVersionCode: null,
            dismissedForVersion: false,
            bypassedForVersion: false,
            canBypass: false,
            fromCache: false,
            verifiedAt: null,
            failure: null,
          ),
        );
      case UpdateAvailability.inProgress:
        final cached = await _store.loadTrustedPolicy();
        if (isClosed) return;
        _listenToInstallStatus();
        _emit(
          state.copyWith(
            phase: _phaseForInstallStatus(info.installStatus),
            urgency: cached?.urgency ?? UpdateUrgency.optional,
            availableVersionCode:
                info.availableVersionCode ?? cached?.availableVersionCode,
            updatePriority: info.updatePriority,
            immediateAllowed: info.immediateAllowed,
            flexibleAllowed: info.flexibleAllowed,
            dismissedForVersion: false,
            bypassedForVersion: false,
            canBypass: false,
            fromCache: cached != null,
            verifiedAt: cached?.verifiedAt,
            failure: null,
          ),
        );
      case UpdateAvailability.available:
        final urgency = _policy.evaluate(info);
        if (urgency == UpdateUrgency.none) {
          await _store.clearTrustedPolicy();
          _emit(
            state.copyWith(
              phase: UpdatePhase.upToDate,
              urgency: UpdateUrgency.none,
              availableVersionCode: null,
              dismissedForVersion: false,
              bypassedForVersion: false,
              canBypass: false,
              fromCache: false,
              verifiedAt: null,
              failure: null,
            ),
          );
          return;
        }

        await _store.saveTrustedPolicy(
          TrustedUpdatePolicy(
            urgency: urgency,
            verifiedAt: now,
            availableVersionCode: info.availableVersionCode,
            updatePriority: info.updatePriority,
          ),
        );
        final dismissedCode = await _store.loadDismissedVersionCode();
        if (isClosed) return;

        _emit(
          state.copyWith(
            phase: UpdatePhase.available,
            urgency: urgency,
            availableVersionCode: info.availableVersionCode,
            updatePriority: info.updatePriority,
            immediateAllowed: info.immediateAllowed,
            flexibleAllowed: info.flexibleAllowed,
            dismissedForVersion:
                info.availableVersionCode != null &&
                dismissedCode == info.availableVersionCode,
            bypassedForVersion: false,
            canBypass: false,
            fromCache: false,
            verifiedAt: now,
            failure: null,
          ),
        );
    }
  }

  /// Network failures never turn into mandatory updates. A previously verified
  /// mandatory policy is honoured only while it is still fresh, and only then
  /// may the user bypass it after repeated failed checks so a Play outage can
  /// never lock the flashlight away permanently.
  Future<void> _handleCheckFailure(UpdateFailure failure) async {
    if (isClosed) return;
    _failedChecks++;

    final now = _clock();
    final cached = await _store.loadTrustedPolicy();
    if (isClosed) return;

    if (cached != null &&
        cached.urgency == UpdateUrgency.mandatory &&
        cached.isFresh(now, _config.cachedPolicyTtl)) {
      _emit(
        state.copyWith(
          phase: UpdatePhase.available,
          urgency: UpdateUrgency.mandatory,
          availableVersionCode: cached.availableVersionCode,
          updatePriority: cached.updatePriority,
          immediateAllowed: false,
          flexibleAllowed: false,
          dismissedForVersion: false,
          bypassedForVersion: false,
          canBypass: _failedChecks >= _config.bypassAfterFailedChecks,
          fromCache: true,
          verifiedAt: cached.verifiedAt,
          failure: failure,
        ),
      );
      return;
    }

    // A failed check must never block the flashlight. The local minimum only
    // applies after Play successfully reports an available update.
    if (state.urgency != UpdateUrgency.none) {
      // Keep the last successfully established prompt; the failed check is not
      // proof that anything changed.
      _emit(
        state.copyWith(
          phase: state.phase == UpdatePhase.checking
              ? UpdatePhase.available
              : state.phase,
          failure: failure,
        ),
      );
      return;
    }

    _emit(
      state.copyWith(
        phase: state.phase == UpdatePhase.checking
            ? UpdatePhase.idle
            : state.phase,
        urgency: UpdateUrgency.none,
        failure: failure,
      ),
    );
  }

  /// Starts the appropriate Google Play flow for the current prompt.
  Future<void> startUpdate() async {
    if (isClosed || _flowActive) return;

    if (state.phase == UpdatePhase.downloaded) {
      await installFlexibleUpdate();
      return;
    }
    if (state.urgency == UpdateUrgency.none) return;

    if (state.urgency == UpdateUrgency.mandatory && state.immediateAllowed) {
      await _startImmediateUpdate();
      return;
    }
    if (state.flexibleAllowed) {
      await _startFlexibleUpdate();
      return;
    }
    await openStore();
  }

  Future<void> _startImmediateUpdate() async {
    _flowActive = true;
    _recheckOnResume = true;
    _emit(state.copyWith(phase: UpdatePhase.installing, failure: null));

    try {
      final result = await _gateway.startImmediateUpdate();
      if (isClosed) return;
      switch (result) {
        case UpdateFlowResult.success:
          _emit(state.copyWith(phase: UpdatePhase.installed, failure: null));
        case UpdateFlowResult.userDenied:
          _emit(
            state.copyWith(
              phase: UpdatePhase.available,
              failure: UpdateFailure.userCanceled,
            ),
          );
        case UpdateFlowResult.failed:
          _emit(
            state.copyWith(
              phase: UpdatePhase.available,
              failure: UpdateFailure.flowFailed,
            ),
          );
      }
    } on MissingPluginException {
      _emit(
        state.copyWith(
          phase: UpdatePhase.available,
          failure: UpdateFailure.playStoreUnavailable,
        ),
      );
    } catch (_) {
      _emit(
        state.copyWith(
          phase: UpdatePhase.available,
          failure: UpdateFailure.flowFailed,
        ),
      );
    } finally {
      _flowActive = false;
    }
  }

  Future<void> _startFlexibleUpdate() async {
    _flowActive = true;
    _recheckOnResume = true;
    _listenToInstallStatus();
    _emit(state.copyWith(phase: UpdatePhase.downloading, failure: null));

    try {
      final result = await _gateway.startFlexibleUpdate();
      if (isClosed) return;
      switch (result) {
        case UpdateFlowResult.success:
          if (state.phase != UpdatePhase.downloaded &&
              state.phase != UpdatePhase.installed) {
            _emit(state.copyWith(phase: UpdatePhase.downloaded, failure: null));
          }
        case UpdateFlowResult.userDenied:
          await _stopInstallListener();
          _emit(
            state.copyWith(
              phase: UpdatePhase.available,
              failure: UpdateFailure.userCanceled,
            ),
          );
        case UpdateFlowResult.failed:
          await _stopInstallListener();
          _emit(
            state.copyWith(
              phase: UpdatePhase.available,
              failure: UpdateFailure.installFailed,
            ),
          );
      }
    } on MissingPluginException {
      await _stopInstallListener();
      _emit(
        state.copyWith(
          phase: UpdatePhase.available,
          failure: UpdateFailure.playStoreUnavailable,
        ),
      );
    } catch (_) {
      await _stopInstallListener();
      _emit(
        state.copyWith(
          phase: UpdatePhase.available,
          failure: UpdateFailure.installFailed,
        ),
      );
    } finally {
      _flowActive = false;
    }
  }

  Future<void> installFlexibleUpdate() async {
    if (isClosed || state.phase != UpdatePhase.downloaded) return;

    _emit(state.copyWith(phase: UpdatePhase.installing, failure: null));
    try {
      await _gateway.completeFlexibleUpdate();
    } catch (_) {
      if (isClosed) return;
      _emit(
        state.copyWith(
          phase: UpdatePhase.downloaded,
          failure: UpdateFailure.installFailed,
        ),
      );
    }
  }

  Future<void> openStore() async {
    if (isClosed) return;

    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final url = isIos ? _config.appStoreUrl : _config.playStoreUrl;
    if (url == null) {
      _emit(state.copyWith(failure: UpdateFailure.openStoreFailed));
      return;
    }

    final opened = await _storeLauncher.open(Uri.parse(url));
    if (isClosed) return;

    if (opened) {
      _recheckOnResume = true;
      return;
    }
    _emit(state.copyWith(failure: UpdateFailure.openStoreFailed));
  }

  Future<void> dismissOptional() async {
    if (state.urgency == UpdateUrgency.mandatory || state.dismissedForVersion) {
      return;
    }
    final code = state.availableVersionCode;
    if (code != null) {
      await _store.saveDismissedVersionCode(code);
    }
    _emit(state.copyWith(dismissedForVersion: true));
  }

  /// Only available while a cached mandatory policy cannot be re-verified.
  void continueWithoutUpdating() {
    if (!state.canBypass) return;
    _emit(state.copyWith(bypassedForVersion: true));
  }

  void _listenToInstallStatus() {
    unawaited(_stopInstallListener());
    _installSubscription = _gateway.installStatusStream.listen(
      (status) {
        if (isClosed) return;
        switch (status) {
          case UpdateInstallStatus.pending:
          case UpdateInstallStatus.downloading:
            if (state.phase != UpdatePhase.downloaded &&
                state.phase != UpdatePhase.installing &&
                state.phase != UpdatePhase.installed) {
              _emit(
                state.copyWith(phase: UpdatePhase.downloading, failure: null),
              );
            }
          case UpdateInstallStatus.downloaded:
            if (state.phase != UpdatePhase.installing &&
                state.phase != UpdatePhase.installed) {
              _emit(
                state.copyWith(phase: UpdatePhase.downloaded, failure: null),
              );
            }
          case UpdateInstallStatus.installing:
            if (state.phase != UpdatePhase.installed) {
              _emit(
                state.copyWith(phase: UpdatePhase.installing, failure: null),
              );
            }
          case UpdateInstallStatus.installed:
            _flowActive = false;
            _emit(state.copyWith(phase: UpdatePhase.installed, failure: null));
          case UpdateInstallStatus.failed:
            _emit(
              state.copyWith(
                phase: UpdatePhase.available,
                failure: UpdateFailure.installFailed,
              ),
            );
          case UpdateInstallStatus.canceled:
            _emit(
              state.copyWith(
                phase: UpdatePhase.available,
                failure: UpdateFailure.userCanceled,
              ),
            );
          case UpdateInstallStatus.unknown:
            break;
        }
      },
      onError: (_) {
        // The stream is advisory; flow futures still report the final result.
      },
    );
  }

  Future<void> _stopInstallListener() async {
    await _installSubscription?.cancel();
    _installSubscription = null;
  }

  UpdatePhase _phaseForInstallStatus(UpdateInstallStatus status) {
    return switch (status) {
      UpdateInstallStatus.downloading ||
      UpdateInstallStatus.pending => UpdatePhase.downloading,
      UpdateInstallStatus.downloaded => UpdatePhase.downloaded,
      UpdateInstallStatus.installing => UpdatePhase.installing,
      UpdateInstallStatus.installed => UpdatePhase.installed,
      _ => UpdatePhase.available,
    };
  }

  void _emit(UpdateState next) {
    if (!isClosed) emit(next);
  }

  @override
  Future<void> close() async {
    await _installSubscription?.cancel();
    return super.close();
  }
}
