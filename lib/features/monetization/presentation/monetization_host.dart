import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../src/bloc/flash_light/flash_light_bloc.dart';
import '../../updates/application/update_cubit.dart';
import '../application/ad_diagnostics.dart';
import '../application/ad_mob_service.dart';
import '../application/monetization_controller.dart';
import '../application/monetization_start_gate.dart';
import '../data/ad_frequency_store.dart';
import '../data/billing_gateway.dart';
import '../data/consent_gateway.dart';
import '../data/entitlement_store.dart';
import '../data/fullscreen_ad_presenter.dart';
import '../data/rewarded_ad_presenter.dart';

import 'package:flash_light_pro/core/config/admob/admob_config.dart';

import '../domain/ad_models.dart';
import '../domain/monetization_models.dart';
import 'monetization_scope.dart';

/// Composition root and lifecycle owner for monetization.
///
/// It waits for the update check to settle, for no light to be active, and for
/// the app to be resumed before consent or any ad request is started. Once
/// running, it requests one App Open on the first eligible moment of a cold
/// start and one on a real return from the background, never for a brief
/// Quick Settings or system-settings round trip.
class MonetizationHost extends StatefulWidget {
  const MonetizationHost({
    super.key,
    required this.config,
    required this.child,
  });

  /// Null disables monetization entirely (used by widget tests).
  final AdConfig? config;
  final Widget child;

  @override
  State<MonetizationHost> createState() => _MonetizationHostState();
}

class _MonetizationHostState extends State<MonetizationHost>
    with WidgetsBindingObserver {
  MonetizationController? _controller;
  FlashLightBloc? _flashlight;
  UpdateCubit? _updates;
  AdRuntimeFlags? _flags;
  StreamSubscription<Object?>? _lightSubscription;
  StreamSubscription<Object?>? _updateSubscription;
  Timer? _startupSafetyTimer;
  Timer? _appOpenTimer;
  Timer? _appOpenRetryTimer;
  Timer? _startRetryTimer;

  bool _appResumed = true;
  bool _hasBackgrounded = false;
  bool _sawBackground = false;
  bool _sawUpdateCheck = false;
  bool _allowBeforeFirstCheck = false;
  bool _startCallInFlight = false;
  bool _pendingAppOpen = false;
  bool _appOpenAttempted = false;
  bool _coldStartAppOpenRequested = false;
  int _appOpenRetriesLeft = 0;
  DateTime? _backgroundedAt;
  DateTime? _lastGateLogAt;

  static const Duration _briefBackgroundThreshold = Duration(seconds: 2);
  static const Duration _appOpenRetryDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.config == null) return;

    final config = widget.config!;
    _flashlight = context.read<FlashLightBloc>();
    _updates = context.read<UpdateCubit>();
    _flags = AdRuntimeFlags();
    _controller = MonetizationController(
      config: config,
      contextProvider: _requestContext,
      adFreeStore: const SharedPreferencesAdFreeStore(),
      billingGateway: InAppPurchaseBillingGateway(),
      consentGateway: GoogleConsentGateway(config: config),
      adInitializer: AdMobService(config: config),
      fullscreenPresenter: GoogleFullScreenAdPresenter(),
      rewardedPresenter: GoogleRewardedAdPresenter(),
      frequencyStore: const SharedPreferencesAdFrequencyStore(),
      runtimeFlags: _flags!,
    );

    unawaited(_controller!.initialize());
    _controller!.addListener(_onControllerChanged);

    _lightSubscription = _flashlight!.stream
        .map(
          (state) => (state.activeLight, state.isLoading, state.availability),
        )
        .distinct()
        .listen((_) => _onAppStateChanged());

    _updateSubscription = _updates!.stream
        .map(
          (state) => (
            state.phase,
            state.urgency,
            state.shouldPrompt,
            state.availableVersionCode,
            state.dismissedForVersion,
            state.bypassedForVersion,
            state.isSupported,
          ),
        )
        .distinct()
        .listen((_) => _onUpdateChanged());

    if (!_updates!.state.isSupported) {
      _sawUpdateCheck = true;
    }

    // Ads still start when the Play update check is throttled (it returns
    // without ever entering the checking phase) or unavailable. Eligibility is
    // re-evaluated separately, so no ad can appear during a real update flow.
    _startupSafetyTimer = Timer(const Duration(seconds: 4), () {
      _allowBeforeFirstCheck = true;
      _tryStartAds();
    });

    _scheduleStartCheck();
  }

  @override
  void dispose() {
    _startupSafetyTimer?.cancel();
    _appOpenTimer?.cancel();
    _appOpenRetryTimer?.cancel();
    _startRetryTimer?.cancel();
    unawaited(_lightSubscription?.cancel());
    unawaited(_updateSubscription?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        final returningFromBackground = _hasBackgrounded;
        final backgroundedAt = _backgroundedAt;
        final wasBrief =
            backgroundedAt != null &&
            DateTime.now().difference(backgroundedAt) <
                _briefBackgroundThreshold;
        final externalFlow = _controller!.externalSystemFlow;
        _controller!.clearExternalSystemFlow();
        _hasBackgrounded = false;
        _backgroundedAt = null;
        _appResumed = true;
        _appOpenAttempted = false;
        _controller!.notifyAppStateChanged();
        _tryStartAds();
        if (returningFromBackground) {
          // Returning from Quick Settings, a permission surface, Android
          // Settings, or another brief system hand-off must not show a
          // fullscreen ad.
          if (wasBrief || externalFlow) {
            AdDiagnostics.log(
              'app-open skipped',
              wasBrief ? 'brief background return' : 'external system flow',
            );
          } else {
            _requestAppOpen();
          }
        }
      case AppLifecycleState.inactive:
        // A system dialog, permission prompt, or the app switcher.
        _appResumed = false;
        _controller!.notifyAppStateChanged();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _appResumed = false;
        _hasBackgrounded = true;
        _sawBackground = true;
        _backgroundedAt ??= DateTime.now();
        _controller!.notifyAppStateChanged();
      case AppLifecycleState.detached:
        _appResumed = false;
        _controller!.notifyAppStateChanged();
    }
  }

  AdRequestContext _requestContext() {
    final light = _flashlight!.state;
    final update = _updates!.state;
    final removeAdsPhase = _controller?.removeAdsPhase;
    return AdRequestContext(
      lightActive: light.activeLight != null,
      essentialInitialization: light.isLoading,
      appResumed: _appResumed,
      updateCheckInProgress: update.phase == UpdatePhase.checking,
      mandatoryUpdateActive: update.isMandatory && update.shouldPrompt,
      updateFlowActive:
          update.phase == UpdatePhase.downloading ||
          update.phase == UpdatePhase.downloaded ||
          update.phase == UpdatePhase.installing ||
          update.phase == UpdatePhase.installed,
      purchaseFlowActive:
          removeAdsPhase == RemoveAdsPhase.purchasing ||
          removeAdsPhase == RemoveAdsPhase.pending ||
          removeAdsPhase == RemoveAdsPhase.restoring,
      fullscreenAdVisible: _flags!.fullscreenVisible,
      firstSession: _controller?.isFirstSession ?? true,
    );
  }

  void _onAppStateChanged() {
    _controller?.notifyAppStateChanged();
    _tryStartAds();
  }

  void _onUpdateChanged() {
    if (_updates!.state.phase == UpdatePhase.checking) {
      _sawUpdateCheck = true;
    }
    _controller?.notifyAppStateChanged();
    _tryStartAds();
    _flushPendingAppOpen();
  }

  void _scheduleStartCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tryStartAds();
    });
  }

  void _tryStartAds() {
    final controller = _controller;
    if (controller == null || _startCallInFlight || controller.isSdkReady) {
      if (controller != null && controller.isSdkReady) {
        _requestColdStartAppOpen();
      }
      return;
    }

    final update = _updates!.state;
    final light = _flashlight!.state;
    final allowed = canStartMonetization(
      updateSupported: update.isSupported,
      sawUpdateCheck: _sawUpdateCheck,
      updateCheckInProgress: update.phase == UpdatePhase.checking,
      mandatoryUpdateActive: update.isMandatory && update.shouldPrompt,
      lightActive: light.activeLight != null,
      essentialInitialization: light.isLoading,
      appResumed: _appResumed,
      allowBeforeFirstCheck: _allowBeforeFirstCheck,
    );
    if (!allowed) {
      _logGateBlock(update, light);
      return;
    }

    _startRetryTimer?.cancel();
    _startCallInFlight = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (mounted) await controller.startAds();
      } finally {
        _startCallInFlight = false;
      }
      if (!mounted) return;
      if (controller.isSdkReady) {
        _requestColdStartAppOpen();
        return;
      }
      // Consent or SDK initialization can fail transiently (for example while
      // offline). Retry later instead of latching ads off for the session.
      _startRetryTimer?.cancel();
      _startRetryTimer = Timer(const Duration(seconds: 20), _tryStartAds);
    });
  }

  /// The first App Open of a process is requested once the SDK is ready.
  /// A process that has already been backgrounded is not a cold start, so the
  /// lifecycle path owns the request instead.
  void _requestColdStartAppOpen() {
    final controller = _controller;
    if (controller == null || !controller.isSdkReady) return;
    if (!_appResumed || _coldStartAppOpenRequested || _sawBackground) return;
    _coldStartAppOpenRequested = true;
    AdDiagnostics.log(
      'app-open cold start',
      'firstSession=${controller.isFirstSession}',
    );
    _requestAppOpen();
  }

  void _logGateBlock(UpdateState update, FlashLightState light) {
    final now = DateTime.now();
    final last = _lastGateLogAt;
    if (last != null && now.difference(last) < const Duration(seconds: 5)) {
      return;
    }
    _lastGateLogAt = now;
    AdDiagnostics.log(
      'start gate blocked',
      'updateSupported=${update.isSupported}, '
          'sawUpdateCheck=$_sawUpdateCheck, '
          'checking=${update.phase == UpdatePhase.checking}, '
          'mandatory=${update.isMandatory && update.shouldPrompt}, '
          'light=${light.activeLight != null}, '
          'initializing=${light.isLoading}, resumed=$_appResumed',
    );
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (_pendingAppOpen) _flushPendingAppOpen();
  }

  void _requestAppOpen() {
    final controller = _controller;
    if (controller == null ||
        !controller.isSdkReady ||
        !controller.canRequestAds) {
      AdDiagnostics.log(
        'app-open skipped',
        'sdkReady=${controller?.isSdkReady}, '
            'canRequestAds=${controller?.canRequestAds}',
      );
      return;
    }

    AdDiagnostics.log('app-open pending');
    _pendingAppOpen = true;
    _appOpenAttempted = false;
    _appOpenRetriesLeft = 3;
    _appOpenTimer?.cancel();
    _appOpenRetryTimer?.cancel();
    // Give the update check triggered by this resume a moment to report that
    // it is running, so an app-open ad can never appear over a mandatory
    // update prompt.
    _appOpenTimer = Timer(
      const Duration(milliseconds: 600),
      _flushPendingAppOpen,
    );
  }

  /// Defers the pending App Open a few times while a transient condition (an
  /// update check or a not-yet-loaded ad) clears, then abandons it.
  void _retryPendingAppOpen(String reason) {
    if (_appOpenRetriesLeft <= 0) {
      _pendingAppOpen = false;
      AdDiagnostics.log('app-open abandoned', reason);
      return;
    }
    _appOpenRetriesLeft--;
    _appOpenRetryTimer?.cancel();
    _appOpenRetryTimer = Timer(_appOpenRetryDelay, _flushPendingAppOpen);
  }

  void _flushPendingAppOpen() {
    if (!mounted || !_pendingAppOpen) return;
    final controller = _controller;
    if (controller == null) {
      _pendingAppOpen = false;
      return;
    }
    if (!_appResumed || !controller.isSdkReady || !controller.canRequestAds) {
      AdDiagnostics.log(
        'app-open dropped',
        'resumed=$_appResumed, sdkReady=${controller.isSdkReady}, '
            'canRequestAds=${controller.canRequestAds}',
      );
      _pendingAppOpen = false;
      return;
    }
    if (controller.externalSystemFlow) {
      controller.clearExternalSystemFlow();
      _pendingAppOpen = false;
      AdDiagnostics.log('app-open skipped', 'external system flow');
      return;
    }
    // An interstitial is owed after the third eligible action. It takes
    // priority so a fullscreen ad is never shown immediately before another.
    if (controller.pendingInterstitial) {
      _pendingAppOpen = false;
      AdDiagnostics.log('app-open skipped', 'interstitial trigger pending');
      return;
    }

    final update = _updates!.state;
    if (update.phase == UpdatePhase.checking) {
      _retryPendingAppOpen('update check in progress');
      return;
    }
    if (update.isMandatory && update.shouldPrompt) {
      _pendingAppOpen = false;
      return;
    }
    if (update.phase == UpdatePhase.downloading ||
        update.phase == UpdatePhase.downloaded ||
        update.phase == UpdatePhase.installing ||
        update.phase == UpdatePhase.installed) {
      _pendingAppOpen = false;
      return;
    }

    final light = _flashlight!.state;
    if (light.activeLight != null || light.isLoading) {
      _pendingAppOpen = false;
      return;
    }
    if (_appOpenAttempted) {
      _pendingAppOpen = false;
      return;
    }

    _appOpenAttempted = true;
    _pendingAppOpen = false;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final shown = await controller.maybeShowAppOpen();
      if (shown || !mounted) return;
      if (_appOpenRetriesLeft <= 0) {
        AdDiagnostics.log('app-open not shown', 'retries exhausted');
        return;
      }
      // A cold start can race the first preload; retry briefly.
      _appOpenAttempted = false;
      _pendingAppOpen = true;
      _retryPendingAppOpen('not shown');
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;
    return MonetizationScope(controller: controller, child: widget.child);
  }
}
