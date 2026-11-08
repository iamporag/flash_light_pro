import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

enum RewardOutcome { earned, dismissedWithoutReward, failedToShow, unavailable }

/// Presentation boundary for rewarded ads. A reward is only reported after the
/// SDK fires `onUserEarnedReward`, and duplicate callbacks for the same
/// presentation are ignored.
abstract class RewardedAdPresenter {
  bool get isReady;

  Future<bool> load(String unitId);

  Future<RewardOutcome> show({void Function()? onRewardGranted});

  void dispose();
}

class GoogleRewardedAdPresenter implements RewardedAdPresenter {
  RewardedAd? _rewarded;
  bool _loading = false;
  bool _showing = false;

  static const Duration _loadTimeout = Duration(seconds: 15);
  static const Duration _showTimeout = Duration(minutes: 5);

  @override
  bool get isReady => _rewarded != null;

  @override
  Future<bool> load(String unitId) async {
    if (_rewarded != null) return true;
    if (_loading) return false;

    _loading = true;
    final completer = Completer<RewardedAd?>();
    try {
      await RewardedAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (!completer.isCompleted) completer.complete(ad);
          },
          onAdFailedToLoad: (_) {
            if (!completer.isCompleted) completer.complete(null);
          },
        ),
      );
    } catch (_) {
      if (!completer.isCompleted) completer.complete(null);
    }

    final ad = await completer.future.timeout(
      _loadTimeout,
      onTimeout: () => null,
    );
    _loading = false;
    if (ad != null) {
      _rewarded = ad;
      return true;
    }
    return false;
  }

  @override
  Future<RewardOutcome> show({void Function()? onRewardGranted}) async {
    final ad = _rewarded;
    if (ad == null || _showing) return RewardOutcome.unavailable;

    _rewarded = null;
    _showing = true;
    var rewarded = false;
    var presented = false;
    final completer = Completer<RewardOutcome>();

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (_) => presented = true,
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(
            rewarded
                ? RewardOutcome.earned
                : RewardOutcome.dismissedWithoutReward,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(RewardOutcome.failedToShow);
        }
      },
    );

    try {
      // `show` installs this callback internally, so duplicate rewards are
      // filtered here rather than through the ad's callback field.
      await ad.show(
        onUserEarnedReward: (_, __) {
          if (rewarded) return;
          rewarded = true;
          onRewardGranted?.call();
        },
      );
    } catch (_) {
      ad.dispose();
      _showing = false;
      return RewardOutcome.failedToShow;
    }

    try {
      return await completer.future.timeout(
        _showTimeout,
        onTimeout: () => presented
            ? (rewarded
                  ? RewardOutcome.earned
                  : RewardOutcome.dismissedWithoutReward)
            : RewardOutcome.failedToShow,
      );
    } finally {
      _showing = false;
    }
  }

  @override
  void dispose() {
    _rewarded?.dispose();
    _rewarded = null;
  }
}
