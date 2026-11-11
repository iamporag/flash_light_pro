import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:flash_light_pro/core/config/app_theme_config.dart';

import '../../../src/presentation/utils/localization.dart';
import '../application/ad_diagnostics.dart';
import '../application/monetization_controller.dart';
import '../domain/ad_models.dart';
import 'monetization_scope.dart';

/// Banner slot for informational screens only. It renders nothing when
/// monetization is disabled, consent is missing, an ad-free entitlement is
/// active, a light is running, or the update flow is in progress.
class MonetizationBanner extends StatefulWidget {
  const MonetizationBanner({super.key, required this.placement});

  final AdPlacement placement;

  @override
  State<MonetizationBanner> createState() => _MonetizationBannerState();
}

class _MonetizationBannerState extends State<MonetizationBanner> {
  MonetizationController? _controller;
  BannerAd? _ad;
  bool _loading = false;
  bool _failed = false;
  int _failedAttempts = 0;
  Timer? _retryTimer;

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
    _sync(notify: false);
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
    _sync(notify: true);
  }

  void _sync({required bool notify}) {
    final controller = _controller;
    final allowed =
        controller != null &&
        widget.placement.format == AdFormat.banner &&
        controller.isPlacementAllowed(widget.placement);

    if (!allowed) {
      final hadAd = _ad != null || _loading;
      _retryTimer?.cancel();
      _disposeAd();
      _loading = false;
      _failed = false;
      _failedAttempts = 0;
      if (notify && hadAd && mounted) setState(() {});
      return;
    }

    if (_ad != null || _loading) return;

    if (_failed) {
      _scheduleRetry(controller);
      return;
    }

    final unitId = controller.bannerUnitId;
    if (unitId == null) return;

    _loading = true;
    AdDiagnostics.log('banner request started', widget.placement.name);
    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: unitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          if (!mounted) {
            loaded.dispose();
            return;
          }
          _failedAttempts = 0;
          AdDiagnostics.log('banner loaded', widget.placement.name);
          setState(() {
            _ad = loaded as BannerAd;
            _loading = false;
          });
        },
        onAdFailedToLoad: (failed, error) {
          failed.dispose();
          AdDiagnostics.log(
            'banner load failed',
            '${widget.placement.name}: ${error.code} ${error.domain} ${error.message}',
          );
          if (!mounted) return;
          setState(() {
            _loading = false;
            _failed = true;
          });
          _scheduleRetry(_controller);
        },
      ),
    );
    ad.load();
  }

  void _scheduleRetry(MonetizationController? controller) {
    if (!mounted || controller == null || _retryTimer != null) return;
    _failedAttempts++;
    final multiplier = _failedAttempts.clamp(1, 10);
    final delay = _retryDelay * multiplier;
    final capped = delay > _maxRetryDelay ? _maxRetryDelay : delay;
    _retryTimer = Timer(capped, () {
      _retryTimer = null;
      if (!mounted) return;
      setState(() => _failed = false);
      _sync(notify: false);
    });
  }

  void _disposeAd() {
    _ad?.dispose();
    _ad = null;
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
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
          SizedBox(
            width: ad.size.width.toDouble(),
            height: ad.size.height.toDouble(),
            child: AdWidget(ad: ad),
          ),
        ],
      ),
    );
  }
}
