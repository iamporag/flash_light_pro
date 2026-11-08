import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/ad_frequency_store.dart';
import '../data/billing_gateway.dart';
import '../data/consent_gateway.dart';
import '../data/entitlement_store.dart';
import '../data/fullscreen_ad_presenter.dart';
import '../data/rewarded_ad_presenter.dart';
import '../domain/ad_config.dart';
import '../domain/ad_models.dart';
import '../domain/monetization_models.dart';
import 'ad_diagnostics.dart';
import 'ad_eligibility_manager.dart';
import 'ad_free_entitlement_service.dart';
import 'ad_mob_service.dart';
import 'consent_manager.dart';
import 'fullscreen_ad_coordinator.dart';
import 'rewarded_ad_service.dart';

/// Composition root for monetization. It owns the consent, entitlement,
/// eligibility, frequency, and presentation services and exposes a single
/// [Listenable] for the UI.
class MonetizationController extends ChangeNotifier {
  MonetizationController({
    required this.config,
    required AdRequestContextProvider contextProvider,
    required AdFreeStore adFreeStore,
    required BillingGateway billingGateway,
    required ConsentGateway consentGateway,
    required this.adInitializer,
    required FullScreenAdPresenter fullscreenPresenter,
    required RewardedAdPresenter rewardedPresenter,
    required this.frequencyStore,
    required this.runtimeFlags,
    DateTime Function()? clock,
    this.interstitialActionDelay = const Duration(milliseconds: 350),
  }) {
    consent = ConsentManager(gateway: consentGateway);
    entitlement = AdFreeEntitlementService(
      store: adFreeStore,
      gateway: billingGateway,
    );
    eligibility = AdEligibilityManager(
      config: config,
      contextProvider: contextProvider,
      entitlement: entitlement,
      consent: consent,
      frequencyStore: frequencyStore,
      clock: clock,
    );
    fullscreen = FullscreenAdCoordinator(
      config: config,
      eligibility: eligibility,
      presenter: fullscreenPresenter,
      runtimeFlags: runtimeFlags,
    );
    rewarded = RewardedAdService(
      config: config,
      eligibility: eligibility,
      presenter: rewardedPresenter,
      runtimeFlags: runtimeFlags,
    );

    consent.addListener(_onDependencyChanged);
    entitlement.addListener(_onDependencyChanged);
  }

  final AdConfig config;
  final AdInitializer adInitializer;
  final AdFrequencyStore frequencyStore;
  final AdRuntimeFlags runtimeFlags;
  final Duration interstitialActionDelay;

  late final ConsentManager consent;
  late final AdFreeEntitlementService entitlement;
  late final AdEligibilityManager eligibility;
  late final FullscreenAdCoordinator fullscreen;
  late final RewardedAdService rewarded;

  Future<void>? _initializeFuture;
  bool _initialized = false;
  bool _sdkReady = false;
  bool _starting = false;
  bool _firstSession = true;
  bool _disposed = false;
  DateTime? _lastStartAttemptAt;
  DateTime? _lastPreloadAttemptAt;
  Timer? _interstitialAttemptTimer;

  static const Duration _startRetryInterval = Duration(seconds: 20);
  static const Duration _preloadRetryInterval = Duration(seconds: 15);

  bool get isInitialized => _initialized;
  bool get isSdkReady => _sdkReady;
  bool get isFirstSession => _firstSession;
  bool get isAdFree => entitlement.isAdFree;
  bool get canRequestAds => consent.canRequestAds;
  bool get privacyOptionsRequired => consent.privacyOptionsRequired;
  bool get shouldOfferRemoveAds => config.hasAnyUnitId;
  bool get isStoreSupported => entitlement.isStoreSupported;

  ConsentPhase get consentPhase => consent.phase;
  RemoveAdsPhase get removeAdsPhase => entitlement.phase;
  RemoveAdsNotice get removeAdsNotice => entitlement.notice;
  String? get removeAdsPrice => entitlement.localizedPrice;
  bool get canPurchaseRemoveAds => entitlement.canPurchase;
  bool get canRetryRemoveAdsStore => entitlement.canRetryStore;

  String? get bannerUnitId => config.unitIdFor(AdFormat.banner);
  String? get nativeUnitId => config.unitIdFor(AdFormat.native);

  int get eligibleActionCount => eligibility.clickFrequency.eligibleActionCount;
  int get interstitialActionThreshold =>
      eligibility.clickFrequency.actionThreshold;
  bool get pendingInterstitial =>
      eligibility.clickFrequency.hasPendingInterstitial;
  bool get isAppOpenReady => fullscreen.isAppOpenReady;
  bool get externalSystemFlow => runtimeFlags.externalSystemFlow;

  /// Coarse, user-facing advertising status. It never exposes configuration
  /// values or technical identifiers.
  AdsStatus get adsStatus {
    if (!config.hasAnyUnitId) return AdsStatus.configurationMissing;
    if (isAdFree) return AdsStatus.disabled;
    if (_sdkReady && consent.canRequestAds) return AdsStatus.available;
    if (!_sdkReady ||
        consent.phase == ConsentPhase.idle ||
        consent.phase == ConsentPhase.preparing ||
        consent.phase == ConsentPhase.formShowing) {
      return AdsStatus.starting;
    }
    return AdsStatus.waitingForConsent;
  }

  /// Loads the local entitlement, frequency data, and first-session flag. It
  /// performs no consent UI and requests no ads.
  ///
  /// The returned future is shared so concurrent callers cannot continue
  /// before the ad-free cache and persisted frequency state are loaded.
  Future<void> initialize() {
    return _initializeFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      _firstSession = await frequencyStore.registerSessionStart();
      await eligibility.loadPersistedState();
      // Only the local cache is awaited here so a slow or unreachable store
      // never delays ad startup. Store reconciliation continues in the
      // background and notifies the UI when it completes.
      await entitlement.loadLocal();
      unawaited(entitlement.initialize());
    } catch (error) {
      // Local preferences are best-effort. A failure must not block the app,
      // and the entitlement service fails closed when ownership is unknown.
      AdDiagnostics.log('local state load failed', error);
    }
    if (_disposed) return;
    _initialized = true;
    AdDiagnostics.log(
      'local state ready',
      'firstSession=$_firstSession, adFree=${entitlement.isAdFree}',
    );
    _notify();
  }

  /// Starts consent and the ad SDK. The host calls this only after the update
  /// check has settled, no light is active, and the app is resumed.
  ///
  /// It is safe to call repeatedly: attempts are throttled while consent or the
  /// SDK is still unavailable, and a later call retries.
  Future<void> startAds() async {
    if (_disposed || _sdkReady || !config.hasAnyUnitId) return;
    if (_starting) return;

    final now = DateTime.now();
    final lastAttempt = _lastStartAttemptAt;
    if (lastAttempt != null &&
        now.difference(lastAttempt) < _startRetryInterval) {
      return;
    }
    _lastStartAttemptAt = now;

    _starting = true;
    AdDiagnostics.log(
      'starting ads',
      '${AdDiagnostics.unitStatus('banner', bannerUnitId)}, '
          '${AdDiagnostics.unitStatus('native', nativeUnitId)}',
    );
    try {
      await initialize();
      if (_disposed) return;

      await consent.ensureConsent();
      if (_disposed) return;

      if (!consent.canRequestAds) {
        AdDiagnostics.log(
          'ads not started',
          'consent=${consent.phase.name}, canRequestAds=false',
        );
        return;
      }
      await _ensureSdkReady();
    } finally {
      _starting = false;
      _notify();
    }
  }

  Future<void> showPrivacyOptions() async {
    await consent.showPrivacyOptions();
    if (consent.canRequestAds) {
      await _ensureSdkReady();
    }
    _notify();
  }

  Future<void> retryRemoveAdsStore() => entitlement.refreshProduct();

  Future<void> purchaseRemoveAds() => entitlement.purchase();

  Future<void> restoreRemoveAds() => entitlement.restore();

  bool isPlacementAllowed(AdPlacement placement) {
    if (!_sdkReady) return false;
    return eligibility.check(placement).isAllowed;
  }

  AdEligibility placementEligibility(AdPlacement placement) {
    if (!_sdkReady) {
      return const AdEligibility.blocked(AdBlockReason.adNotReady);
    }
    return eligibility.checkBase(placement);
  }

  /// Records one approved user action and schedules an Interstitial attempt
  /// when the threshold is reached. A pending trigger is preserved and retried
  /// on the next eligible action; the counter never advances past the trigger.
  Future<bool> registerEligibleAction(AdActionId action) async {
    if (!config.hasAnyUnitId) return false;
    if (isAdFree) {
      AdDiagnostics.log('eligible action ignored', '${action.name} (ad-free)');
      return false;
    }

    final registration = await eligibility.clickFrequency.register(action);
    if (registration.triggerReached && !registration.duplicate) {
      _scheduleInterstitialAttempt();
    }
    return registration.triggerReached;
  }

  void _scheduleInterstitialAttempt() {
    _interstitialAttemptTimer?.cancel();
    _interstitialAttemptTimer = Timer(interstitialActionDelay, () {
      if (_disposed) return;
      unawaited(maybeShowInterstitial(AdPlacement.interstitialAction));
    });
  }

  /// Marks a deliberate hand-off to a system surface (for example battery
  /// settings) so returning from it never triggers an App Open ad.
  void markExternalSystemFlow() {
    runtimeFlags.externalSystemFlow = true;
    AdDiagnostics.log('external system flow marked');
  }

  void clearExternalSystemFlow() {
    runtimeFlags.externalSystemFlow = false;
  }

  /// Immediately skips when the ad is not ready; navigation never waits.
  Future<bool> maybeShowInterstitial(AdPlacement placement) async {
    if (!_sdkReady) return false;
    final shown = await fullscreen.maybeShowInterstitial(placement);
    _notify();
    return shown;
  }

  Future<bool> maybeShowAppOpen() async {
    if (!_sdkReady) return false;
    if (pendingInterstitial) {
      AdDiagnostics.log('app open skipped', 'interstitial trigger pending');
      return false;
    }
    final shown = await fullscreen.maybeShowAppOpen();
    _notify();
    return shown;
  }

  /// Called by the host whenever the app state that eligibility depends on
  /// changes, so ad widgets can re-evaluate without polling and missing
  /// preloads can be retried once the app is safe again.
  void notifyAppStateChanged() {
    _notify();
    _retryPreloadIfNeeded();
  }

  Future<void> _ensureSdkReady() async {
    if (_sdkReady) return;
    final ready = await adInitializer.initialize();
    if (_disposed) return;
    _sdkReady = ready;
    if (ready) {
      AdDiagnostics.log('ad SDK ready');
      unawaited(_preload());
      _notify();
    } else {
      AdDiagnostics.log('ad SDK initialization failed');
    }
  }

  Future<void> _preload() async {
    _lastPreloadAttemptAt = DateTime.now();
    await fullscreen.preload();
  }

  /// A preload can be skipped because a light is active, an update check is
  /// running, or a consent form is open. This retries once those conditions
  /// clear so fullscreen ads are ready for the next natural transition.
  void _retryPreloadIfNeeded() {
    if (!_sdkReady || _disposed) return;
    if (fullscreen.isInterstitialReady && fullscreen.isAppOpenReady) return;
    final now = DateTime.now();
    final last = _lastPreloadAttemptAt;
    if (last != null && now.difference(last) < _preloadRetryInterval) return;
    _lastPreloadAttemptAt = now;
    unawaited(fullscreen.preload());
  }

  void _onDependencyChanged() {
    if (_disposed) return;
    _notify();
    if (entitlement.isAdFree) {
      // Loaded fullscreen ads must not resurface after ownership is confirmed.
      _interstitialAttemptTimer?.cancel();
      fullscreen.disposeLoaded();
    }
    _retryPreloadIfNeeded();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _interstitialAttemptTimer?.cancel();
    consent.removeListener(_onDependencyChanged);
    entitlement.removeListener(_onDependencyChanged);
    consent.dispose();
    entitlement.dispose();
    fullscreen.dispose();
    rewarded.dispose();
    super.dispose();
  }
}

/// Coarse states for the Settings status section.
enum AdsStatus {
  available,
  disabled,
  waitingForConsent,
  configurationMissing,
  starting,
}
