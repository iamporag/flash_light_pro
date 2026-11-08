import 'dart:async';

import '../data/rewarded_ad_presenter.dart';
import '../domain/ad_config.dart';
import '../domain/ad_models.dart';
import 'ad_eligibility_manager.dart';

/// Reusable rewarded-ad service.
///
/// The current app has no feature that is appropriate to gate behind a reward,
/// so this service is intentionally not wired to any UI. It exists so a future
/// opt-in feature can grant a reward only after the SDK confirms completion,
/// never on skip, early close, or failure, and never twice for one view.
class RewardedAdService {
  RewardedAdService({
    required this.config,
    required this.eligibility,
    required this.presenter,
    required this.runtimeFlags,
  });

  final AdConfig config;
  final AdEligibilityManager eligibility;
  final RewardedAdPresenter presenter;
  final AdRuntimeFlags runtimeFlags;

  bool _showInProgress = false;
  bool _rewardGranted = false;

  bool get isReady => presenter.isReady;

  Future<bool> preload() async {
    final unitId = config.unitIdFor(AdFormat.rewarded);
    if (unitId == null) return false;
    return presenter.load(unitId);
  }

  /// Shows a rewarded ad because the user explicitly asked for it.
  ///
  /// [onReward] is invoked at most once per presentation, and only when the
  /// SDK reports that the reward was earned.
  Future<RewardOutcome> show({void Function()? onReward}) async {
    if (_showInProgress) return RewardOutcome.unavailable;

    final result = eligibility.check(
      AdPlacement.rewarded,
      ready: presenter.isReady,
    );
    if (!result.isAllowed) return RewardOutcome.unavailable;

    final unitId = config.unitIdFor(AdFormat.rewarded);
    if (unitId == null) return RewardOutcome.unavailable;

    _showInProgress = true;
    _rewardGranted = false;
    runtimeFlags.fullscreenVisible = true;
    try {
      final outcome = await presenter.show(
        onRewardGranted: () {
          if (_rewardGranted) return;
          _rewardGranted = true;
          onReward?.call();
        },
      );
      if (outcome != RewardOutcome.earned || !_rewardGranted) {
        return outcome == RewardOutcome.earned
            ? RewardOutcome.dismissedWithoutReward
            : outcome;
      }
      return RewardOutcome.earned;
    } finally {
      runtimeFlags.fullscreenVisible = false;
      _showInProgress = false;
      unawaited(presenter.load(unitId));
    }
  }

  void dispose() {
    presenter.dispose();
  }
}
