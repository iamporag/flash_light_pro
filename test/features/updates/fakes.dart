import 'dart:async';

import 'package:flash_light_pro/features/updates/data/store_launcher.dart';
import 'package:flash_light_pro/features/updates/data/update_gateway.dart';
import 'package:flash_light_pro/features/updates/data/update_policy_store.dart';
import 'package:flash_light_pro/features/updates/domain/update_models.dart';

class FakeUpdateGateway implements UpdateGateway {
  FakeUpdateGateway({this.isSupported = true, UpdateInfo? info})
    : info =
          info ??
          const UpdateInfo(availability: UpdateAvailability.unavailable);

  @override
  bool isSupported;

  UpdateInfo info;
  Object? checkError;
  Duration checkDelay = Duration.zero;
  int checkCalls = 0;

  UpdateFlowResult immediateResult = UpdateFlowResult.success;
  UpdateFlowResult flexibleResult = UpdateFlowResult.success;
  Completer<UpdateFlowResult>? immediateCompleter;
  Completer<UpdateFlowResult>? flexibleCompleter;

  int immediateCalls = 0;
  int flexibleCalls = 0;
  int completeCalls = 0;

  final StreamController<UpdateInstallStatus> _installStatus =
      StreamController<UpdateInstallStatus>.broadcast(sync: true);

  @override
  Future<UpdateInfo> checkForUpdate() async {
    checkCalls++;
    if (checkDelay > Duration.zero) {
      await Future<void>.delayed(checkDelay);
    }
    final error = checkError;
    if (error != null) throw error;
    return info;
  }

  @override
  Future<UpdateFlowResult> startImmediateUpdate() {
    immediateCalls++;
    return immediateCompleter?.future ?? Future.value(immediateResult);
  }

  @override
  Future<UpdateFlowResult> startFlexibleUpdate() {
    flexibleCalls++;
    return flexibleCompleter?.future ?? Future.value(flexibleResult);
  }

  @override
  Future<void> completeFlexibleUpdate() async {
    completeCalls++;
  }

  @override
  Stream<UpdateInstallStatus> get installStatusStream => _installStatus.stream;

  void emitInstallStatus(UpdateInstallStatus status) {
    _installStatus.add(status);
  }

  Future<void> close() => _installStatus.close();
}

class FakeUpdatePolicyStore implements UpdatePolicyStore {
  FakeUpdatePolicyStore({
    this.policy,
    this.dismissedVersionCode,
    this.lastCheckAt,
  });

  TrustedUpdatePolicy? policy;
  int? dismissedVersionCode;
  DateTime? lastCheckAt;

  int savePolicyCalls = 0;
  int clearPolicyCalls = 0;
  int saveDismissedCalls = 0;
  int saveLastCheckCalls = 0;

  @override
  Future<TrustedUpdatePolicy?> loadTrustedPolicy() async => policy;

  @override
  Future<void> saveTrustedPolicy(TrustedUpdatePolicy policy) async {
    savePolicyCalls++;
    this.policy = policy;
  }

  @override
  Future<void> clearTrustedPolicy() async {
    clearPolicyCalls++;
    policy = null;
  }

  @override
  Future<int?> loadDismissedVersionCode() async => dismissedVersionCode;

  @override
  Future<void> saveDismissedVersionCode(int versionCode) async {
    saveDismissedCalls++;
    dismissedVersionCode = versionCode;
  }

  @override
  Future<DateTime?> loadLastCheckAt() async => lastCheckAt;

  @override
  Future<void> saveLastCheckAt(DateTime at) async {
    saveLastCheckCalls++;
    lastCheckAt = at;
  }
}

class FakeStoreLauncher implements StoreLauncher {
  FakeStoreLauncher({this.openResult = true});

  bool openResult;
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return openResult;
  }
}
