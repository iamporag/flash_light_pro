import '../data/ad_frequency_store.dart';
import '../domain/ad_config.dart';
import '../domain/ad_frequency_policy.dart';
import '../domain/ad_models.dart';
import 'ad_diagnostics.dart';
import 'ad_free_entitlement_service.dart';
import 'consent_manager.dart';

typedef AdRequestContextProvider = AdRequestContext Function();

/// Single place that decides whether an ad may be requested or presented.
///
/// It is intentionally strict: if a condition is unknown the request is
/// refused. Placement, consent, entitlement, app state, or frequency limits
/// can each veto an ad.
class AdEligibilityManager {
  AdEligibilityManager({
    required this.config,
    required this.contextProvider,
    required this.entitlement,
    required this.consent,
    required this.frequencyStore,
    DateTime Function()? clock,
    this.minFullscreenSeparation = const Duration(seconds: 30),
  }) : _clock = clock ?? DateTime.now,
       _frequencyPolicy = AdFrequencyPolicy(
         interstitialMinInterval: config.interstitialMinInterval,
         interstitialDailyCap: config.interstitialDailyCap,
         appOpenCooldown: config.appOpenCooldown,
       );

  final AdConfig config;
  final AdRequestContextProvider contextProvider;
  final AdFreeEntitlementService entitlement;
  final ConsentManager consent;
  final AdFrequencyStore frequencyStore;
  final DateTime Function() _clock;
  final Duration minFullscreenSeparation;
  final AdFrequencyPolicy _frequencyPolicy;

  AdFrequencyState _frequency = const AdFrequencyState();
  DateTime? _lastFullscreenPresentedAt;

  AdFrequencyState get frequencyState => _frequency;

  Future<void> loadPersistedState() async {
    _frequency = await frequencyStore.load();
  }

  AdEligibility check(AdPlacement placement, {bool ready = true}) {
    final base = checkBase(placement);
    if (!base.isAllowed) return base;
    if (placement.isFullScreen && !ready) {
      const blocked = AdEligibility.blocked(AdBlockReason.adNotReady);
      AdDiagnostics.eligibility(placement, blocked);
      return blocked;
    }
    return const AdEligibility.allowed();
  }

  /// State/consent/frequency checks only. Preloading uses this because a
  /// not-yet-loaded ad is exactly what preloading is trying to fix.
  AdEligibility checkBase(AdPlacement placement) {
    final result = _checkBase(placement);
    AdDiagnostics.eligibility(placement, result);
    return result;
  }

  AdEligibility _checkBase(AdPlacement placement) {
    if (config.unitIdFor(placement.format) == null) {
      return const AdEligibility.blocked(AdBlockReason.adsNotConfigured);
    }
    if (!consent.canRequestAds) {
      return const AdEligibility.blocked(AdBlockReason.consentNotObtained);
    }
    if (entitlement.isAdFree) {
      return const AdEligibility.blocked(AdBlockReason.adFreeEntitlement);
    }

    final context = contextProvider();
    if (context.updateCheckInProgress) {
      return const AdEligibility.blocked(AdBlockReason.updateCheckInProgress);
    }
    if (context.mandatoryUpdateActive) {
      return const AdEligibility.blocked(AdBlockReason.mandatoryUpdateActive);
    }
    if (context.updateFlowActive) {
      return const AdEligibility.blocked(AdBlockReason.updateFlowActive);
    }
    if (context.lightActive) {
      return const AdEligibility.blocked(AdBlockReason.lightActive);
    }
    if (context.essentialInitialization) {
      return const AdEligibility.blocked(AdBlockReason.essentialInitialization);
    }
    if (!context.appResumed) {
      return const AdEligibility.blocked(AdBlockReason.appNotResumed);
    }
    if (context.fullscreenAdVisible) {
      return const AdEligibility.blocked(AdBlockReason.fullscreenAdVisible);
    }

    final now = _clock();
    switch (placement) {
      case AdPlacement.privacyPolicyExit:
        final reason = _frequencyPolicy.interstitialBlockReason(
          _frequency,
          now,
        );
        if (reason != null) return AdEligibility.blocked(reason);
        if (!_hasFullscreenSeparation(now)) {
          return const AdEligibility.blocked(AdBlockReason.frequencyCooldown);
        }
      case AdPlacement.appOpen:
        final reason = _frequencyPolicy.appOpenBlockReason(
          _frequency,
          now,
          firstSession: context.firstSession,
        );
        if (reason != null) return AdEligibility.blocked(reason);
        if (!_hasFullscreenSeparation(now)) {
          return const AdEligibility.blocked(AdBlockReason.frequencyCooldown);
        }
      case AdPlacement.settingsNative:
      case AdPlacement.privacyPolicyBanner:
      case AdPlacement.rewarded:
        break;
    }

    return const AdEligibility.allowed();
  }

  /// Records an impression only after the SDK confirmed presentation.
  Future<void> recordImpression(AdPlacement placement) async {
    final now = _clock();
    switch (placement) {
      case AdPlacement.privacyPolicyExit:
        _frequency = _frequencyPolicy.recordInterstitial(_frequency, now);
      case AdPlacement.appOpen:
        _frequency = _frequencyPolicy.recordAppOpen(_frequency, now);
      case AdPlacement.settingsNative:
      case AdPlacement.privacyPolicyBanner:
      case AdPlacement.rewarded:
        return;
    }

    _lastFullscreenPresentedAt = now;
    try {
      await frequencyStore.save(_frequency);
    } catch (_) {
      // The in-memory state still enforces limits for this session.
    }
  }

  bool _hasFullscreenSeparation(DateTime now) {
    final last = _lastFullscreenPresentedAt;
    return last == null || now.difference(last) >= minFullscreenSeparation;
  }
}
