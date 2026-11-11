import 'dart:async';

import '../data/fullscreen_ad_presenter.dart';

import 'package:flash_light_pro/core/config/admob/admob_config.dart';

import '../domain/ad_models.dart';
import 'ad_diagnostics.dart';
import 'ad_eligibility_manager.dart';

/// Serializes fullscreen ad presentation and enforces that navigation never
/// waits for an ad.
class FullscreenAdCoordinator {
  FullscreenAdCoordinator({
    required this.config,
    required this.eligibility,
    required this.presenter,
    required this.runtimeFlags,
  });

  final AdConfig config;
  final AdEligibilityManager eligibility;
  final FullScreenAdPresenter presenter;
  final AdRuntimeFlags runtimeFlags;

  bool _presenting = false;

  bool get isShowing => runtimeFlags.fullscreenVisible;

  bool get isInterstitialReady => presenter.interstitialReady;

  bool get isAppOpenReady => presenter.appOpenReady;

  /// Loads both fullscreen formats only when the current app state already
  /// allows them. Loading never presents anything.
  Future<void> preload() async {
    final interstitial = config.unitIdFor(AdFormat.interstitial);
    if (interstitial != null &&
        eligibility.checkBase(AdPlacement.interstitialAction).isAllowed) {
      await presenter.loadInterstitial(interstitial);
    }

    final appOpen = config.unitIdFor(AdFormat.appOpen);
    if (appOpen != null &&
        eligibility.checkBase(AdPlacement.appOpen).isAllowed) {
      await presenter.loadAppOpen(appOpen);
    }
  }

  /// Returns true only when an interstitial was actually presented and
  /// dismissed. A missing or unloaded ad skips immediately.
  Future<bool> maybeShowInterstitial(AdPlacement placement) async {
    if (placement != AdPlacement.interstitialAction) return false;
    if (runtimeFlags.fullscreenVisible || _presenting) return false;

    final unitId = config.unitIdFor(AdFormat.interstitial);
    if (unitId == null) return false;

    final result = eligibility.check(
      placement,
      ready: presenter.interstitialReady,
    );
    if (!result.isAllowed) {
      if (result.reason == AdBlockReason.adNotReady) {
        AdDiagnostics.log('interstitial load on demand');
        unawaited(presenter.loadInterstitial(unitId));
      }
      return false;
    }

    _presenting = true;
    runtimeFlags.fullscreenVisible = true;
    try {
      final outcome = await presenter.showInterstitial(
        onPresented: () => unawaited(eligibility.recordImpression(placement)),
      );
      return outcome == FullScreenAdOutcome.dismissed;
    } finally {
      runtimeFlags.fullscreenVisible = false;
      _presenting = false;
      if (!presenter.interstitialReady) {
        unawaited(presenter.loadInterstitial(unitId));
      }
    }
  }

  void disposeLoaded() => presenter.clearAds();

  void dispose() {
    presenter.dispose();
  }

  /// Returns true only when an app-open ad was actually presented.
  Future<bool> maybeShowAppOpen() async {
    if (runtimeFlags.fullscreenVisible || _presenting) return false;

    final unitId = config.unitIdFor(AdFormat.appOpen);
    if (unitId == null) return false;

    final result = eligibility.check(
      AdPlacement.appOpen,
      ready: presenter.appOpenReady,
    );
    if (!result.isAllowed) {
      if (result.reason == AdBlockReason.adNotReady) {
        AdDiagnostics.log('app open load on demand');
        unawaited(presenter.loadAppOpen(unitId));
      }
      return false;
    }

    _presenting = true;
    runtimeFlags.fullscreenVisible = true;
    try {
      final outcome = await presenter.showAppOpen(
        onPresented: () =>
            unawaited(eligibility.recordImpression(AdPlacement.appOpen)),
      );
      return outcome == FullScreenAdOutcome.dismissed;
    } finally {
      runtimeFlags.fullscreenVisible = false;
      _presenting = false;
      if (!presenter.appOpenReady) {
        unawaited(presenter.loadAppOpen(unitId));
      }
    }
  }
}
