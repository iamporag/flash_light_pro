import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../application/ad_diagnostics.dart';

enum FullScreenAdOutcome { dismissed, failedToShow, unavailable }

/// Presentation boundary for interstitial and app-open ads. Tests use a fake
/// implementation so frequency, lifecycle, and suppression rules can be
/// verified without the platform channel.
abstract class FullScreenAdPresenter {
  bool get interstitialReady;

  bool get appOpenReady;

  Future<bool> loadInterstitial(String unitId);

  Future<bool> loadAppOpen(String unitId);

  Future<FullScreenAdOutcome> showInterstitial({void Function()? onPresented});

  Future<FullScreenAdOutcome> showAppOpen({void Function()? onPresented});

  /// Drops any loaded fullscreen ads without making the presenter unusable.
  void clearAds();

  void dispose();
}

class GoogleFullScreenAdPresenter implements FullScreenAdPresenter {
  InterstitialAd? _interstitial;
  AppOpenAd? _appOpen;
  bool _loadingInterstitial = false;
  bool _loadingAppOpen = false;
  bool _disposed = false;

  static const Duration _loadTimeout = Duration(seconds: 15);
  static const Duration _showTimeout = Duration(minutes: 3);

  @override
  bool get interstitialReady => _interstitial != null;

  @override
  bool get appOpenReady => _appOpen != null;

  @override
  Future<bool> loadInterstitial(String unitId) async {
    if (_disposed) return false;
    if (_interstitial != null) return true;
    if (_loadingInterstitial) {
      AdDiagnostics.log('interstitial load already in flight');
      return false;
    }

    _loadingInterstitial = true;
    AdDiagnostics.log('interstitial load started');
    final completer = Completer<InterstitialAd?>();
    void complete(InterstitialAd? ad) {
      if (!completer.isCompleted) completer.complete(ad);
    }

    try {
      await InterstitialAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: complete,
          onAdFailedToLoad: (error) {
            AdDiagnostics.log(
              'interstitial load failed',
              '${error.code} ${error.domain} ${error.message}',
            );
            complete(null);
          },
        ),
      );
    } catch (error) {
      AdDiagnostics.log('interstitial load threw', error);
      complete(null);
    }

    final ad = await completer.future.timeout(
      _loadTimeout,
      onTimeout: () {
        AdDiagnostics.log('interstitial load timed out');
        return null;
      },
    );
    _loadingInterstitial = false;
    if (_disposed) {
      ad?.dispose();
      return false;
    }
    if (ad != null) {
      _interstitial = ad;
      AdDiagnostics.log('interstitial loaded');
      return true;
    }
    return false;
  }

  @override
  Future<bool> loadAppOpen(String unitId) async {
    if (_disposed) return false;
    if (_appOpen != null) return true;
    if (_loadingAppOpen) {
      AdDiagnostics.log('app open load already in flight');
      return false;
    }

    _loadingAppOpen = true;
    AdDiagnostics.log('app open load started');
    final completer = Completer<AppOpenAd?>();
    void complete(AppOpenAd? ad) {
      if (!completer.isCompleted) completer.complete(ad);
    }

    try {
      await AppOpenAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: complete,
          onAdFailedToLoad: (error) {
            AdDiagnostics.log(
              'app open load failed',
              '${error.code} ${error.domain} ${error.message}',
            );
            complete(null);
          },
        ),
      );
    } catch (error) {
      AdDiagnostics.log('app open load threw', error);
      complete(null);
    }

    final ad = await completer.future.timeout(
      _loadTimeout,
      onTimeout: () {
        AdDiagnostics.log('app open load timed out');
        return null;
      },
    );
    _loadingAppOpen = false;
    if (_disposed) {
      ad?.dispose();
      return false;
    }
    if (ad != null) {
      _appOpen = ad;
      AdDiagnostics.log('app open loaded');
      return true;
    }
    return false;
  }

  @override
  Future<FullScreenAdOutcome> showInterstitial({
    void Function()? onPresented,
  }) async {
    final ad = _interstitial;
    if (ad == null) {
      AdDiagnostics.log('interstitial show skipped', 'no loaded ad');
      return FullScreenAdOutcome.unavailable;
    }
    _interstitial = null;

    var presented = false;
    final completer = Completer<FullScreenAdOutcome>();
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (_) {
        presented = true;
        AdDiagnostics.log('interstitial shown');
        onPresented?.call();
      },
      onAdImpression: (_) => AdDiagnostics.log('interstitial impression'),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        AdDiagnostics.log('interstitial dismissed');
        if (!completer.isCompleted) {
          completer.complete(FullScreenAdOutcome.dismissed);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        AdDiagnostics.log(
          'interstitial show failed',
          '${error.code} ${error.message}',
        );
        if (!completer.isCompleted) {
          completer.complete(FullScreenAdOutcome.failedToShow);
        }
      },
    );

    try {
      await ad.show();
    } catch (error) {
      ad.dispose();
      AdDiagnostics.log('interstitial show threw', error);
      return FullScreenAdOutcome.failedToShow;
    }

    return completer.future.timeout(
      _showTimeout,
      onTimeout: () {
        AdDiagnostics.log('interstitial show timed out');
        return presented
            ? FullScreenAdOutcome.dismissed
            : FullScreenAdOutcome.failedToShow;
      },
    );
  }

  @override
  Future<FullScreenAdOutcome> showAppOpen({
    void Function()? onPresented,
  }) async {
    final ad = _appOpen;
    if (ad == null) {
      AdDiagnostics.log('app open show skipped', 'no loaded ad');
      return FullScreenAdOutcome.unavailable;
    }
    _appOpen = null;

    var presented = false;
    final completer = Completer<FullScreenAdOutcome>();
    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdShowedFullScreenContent: (_) {
        presented = true;
        AdDiagnostics.log('app open shown');
        onPresented?.call();
      },
      onAdImpression: (_) => AdDiagnostics.log('app open impression'),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        AdDiagnostics.log('app open dismissed');
        if (!completer.isCompleted) {
          completer.complete(FullScreenAdOutcome.dismissed);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        AdDiagnostics.log(
          'app open show failed',
          '${error.code} ${error.message}',
        );
        if (!completer.isCompleted) {
          completer.complete(FullScreenAdOutcome.failedToShow);
        }
      },
    );

    try {
      await ad.show();
    } catch (error) {
      ad.dispose();
      AdDiagnostics.log('app open show threw', error);
      return FullScreenAdOutcome.failedToShow;
    }

    return completer.future.timeout(
      _showTimeout,
      onTimeout: () {
        AdDiagnostics.log('app open show timed out');
        return presented
            ? FullScreenAdOutcome.dismissed
            : FullScreenAdOutcome.failedToShow;
      },
    );
  }

  @override
  void clearAds() {
    _interstitial?.dispose();
    _interstitial = null;
    _appOpen?.dispose();
    _appOpen = null;
    AdDiagnostics.log('fullscreen ads cleared');
  }

  @override
  void dispose() {
    _disposed = true;
    clearAds();
  }
}
