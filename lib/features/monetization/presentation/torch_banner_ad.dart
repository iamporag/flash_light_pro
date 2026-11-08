import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../src/presentation/theme/app_theme.dart';
import '../../../src/presentation/utils/localization.dart';
import '../application/ad_diagnostics.dart';
import '../application/monetization_controller.dart';
import '../domain/ad_models.dart';
import 'monetization_scope.dart';

/// Adaptive banner for torch screens.
///
/// It lives outside the primary interaction area and disappears while a light,
/// SOS, strobe, or morse operation is running. A loaded banner is kept in
/// memory while suppressed so toggling the torch does not request a new ad.
class TorchBannerAd extends StatefulWidget {
  const TorchBannerAd({super.key});

  @override
  State<TorchBannerAd> createState() => _TorchBannerAdState();
}

class _TorchBannerAdState extends State<TorchBannerAd> {
  MonetizationController? _controller;
  BannerAd? _ad;
  Timer? _retryTimer;
  bool _loading = false;
  bool _failed = false;
  bool _suppressed = false;
  int _failedAttempts = 0;
  double _lastWidth = 0;

  static const Duration _retryDelay = Duration(seconds: 30);
  static const Duration _maxRetryDelay = Duration(minutes: 5);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = MonetizationScope.maybeOf(context);
    if (!identical(controller, _controller)) {
      _controller?.removeListener(_onControllerChanged);
      _controller = controller;
      controller?.addListener(_onControllerChanged);
    }
    _sync();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _retryTimer?.cancel();
    _disposeAd();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    _sync();
  }

  void _sync() {
    final controller = _controller;
    if (controller == null) {
      _suppressed = false;
      _reset();
      return;
    }

    final eligibility = controller.placementEligibility(
      AdPlacement.torchBanner,
    );
    if (eligibility.isAllowed) {
      _suppressed = false;
      if (_failed) {
        _scheduleRetry();
      } else {
        _reloadIfNeeded();
      }
      return;
    }

    if (_isTransient(eligibility.reason)) {
      // Keep the loaded banner so a torch ON/OFF cycle does not re-request.
      _suppressed = true;
      _retryTimer?.cancel();
      _retryTimer = null;
      return;
    }

    _suppressed = false;
    _reset();
  }

  /// Reasons that clear on their own without a configuration change.
  bool _isTransient(AdBlockReason? reason) {
    switch (reason) {
      case AdBlockReason.lightActive:
      case AdBlockReason.essentialInitialization:
      case AdBlockReason.appNotResumed:
      case AdBlockReason.fullscreenAdVisible:
      case AdBlockReason.purchaseFlowActive:
      case AdBlockReason.updateCheckInProgress:
      case AdBlockReason.mandatoryUpdateActive:
      case AdBlockReason.updateFlowActive:
      case AdBlockReason.frequencyCooldown:
      case AdBlockReason.adNotReady:
        return true;
      case AdBlockReason.adsNotConfigured:
      case AdBlockReason.consentNotObtained:
      case AdBlockReason.adFreeEntitlement:
      case AdBlockReason.fullscreenFormatCooldown:
      case AdBlockReason.dailyLimitReached:
      case AdBlockReason.noPendingTrigger:
      case null:
        return false;
    }
  }

  void _reset() {
    final hadAd = _ad != null || _loading;
    _retryTimer?.cancel();
    _retryTimer = null;
    _disposeAd();
    _loading = false;
    _failed = false;
    _failedAttempts = 0;
    _lastWidth = 0;
    if (hadAd && mounted) setState(() {});
  }

  void _reloadIfNeeded() {
    if (_ad != null || _loading || _failed) return;
    if (_lastWidth > 0) _requestLoad(_lastWidth);
  }

  void _requestLoad(double width) {
    if (!mounted || _suppressed || _ad != null || _loading) return;
    if (_failed) {
      _scheduleRetry();
      return;
    }
    _lastWidth = width;
    _loading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _ad != null) return;
      _load(width);
    });
  }

  Future<void> _load(double width) async {
    final controller = _controller;
    final unitId = controller?.bannerUnitId;
    if (controller == null || unitId == null) {
      _loading = false;
      return;
    }

    final eligibility = controller.placementEligibility(
      AdPlacement.torchBanner,
    );
    if (!eligibility.isAllowed && !_isTransient(eligibility.reason)) {
      _loading = false;
      _suppressed = true;
      return;
    }

    AdSize size;
    try {
      size =
          await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width.round()) ??
          AdSize.banner;
    } catch (_) {
      size = AdSize.banner;
    }
    if (!mounted || _ad != null) {
      _loading = false;
      return;
    }

    AdDiagnostics.log('banner request started', 'torch');
    final ad = BannerAd(
      size: size,
      adUnitId: unitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          if (!mounted) {
            loaded.dispose();
            return;
          }
          final current = controller.placementEligibility(
            AdPlacement.torchBanner,
          );
          if (!current.isAllowed && !_isTransient(current.reason)) {
            loaded.dispose();
            _loading = false;
            _failed = false;
            _suppressed = true;
            return;
          }
          _failedAttempts = 0;
          AdDiagnostics.log('banner loaded', 'torch');
          setState(() {
            _ad = loaded as BannerAd;
            _loading = false;
          });
        },
        onAdFailedToLoad: (failedAd, error) {
          failedAd.dispose();
          AdDiagnostics.log(
            'banner load failed',
            'torch: ${error.code} ${error.domain} ${error.message}',
          );
          if (!mounted) return;
          setState(() {
            _loading = false;
            _failed = true;
          });
          _scheduleRetry();
        },
      ),
    );
    ad.load();
  }

  void _scheduleRetry() {
    if (!mounted || _retryTimer != null) return;
    _failedAttempts++;
    final multiplier = _failedAttempts.clamp(1, 10);
    final delay = _retryDelay * multiplier;
    final capped = delay > _maxRetryDelay ? _maxRetryDelay : delay;
    _retryTimer = Timer(capped, () {
      _retryTimer = null;
      if (!mounted) return;
      setState(() => _failed = false);
      _reloadIfNeeded();
    });
  }

  void _disposeAd() {
    _ad?.dispose();
    _ad = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || _suppressed) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final ad = _ad;
        if (ad == null) {
          if (!_failed && constraints.maxWidth > 24) {
            _requestLoad(constraints.maxWidth - 24);
          }
          return const SizedBox.shrink();
        }

        return SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  context.l10n.adLabel,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: ad.size.width.toDouble(),
                    height: ad.size.height.toDouble(),
                    child: AdWidget(ad: ad),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
