/// Ad formats supported by the monetization layer.
enum AdFormat { banner, native, interstitial, rewarded, appOpen }

/// Every place in the app that is allowed to request an advertisement.
///
/// Keeping placements explicit is what prevents ad logic from leaking into
/// screens that were never designed for it. Torch screens only use the
/// explicitly approved [torchBanner] placement, and it is suppressed whenever
/// a light operation is active.
enum AdPlacement {
  torchBanner(AdFormat.banner),
  settingsNative(AdFormat.native),
  privacyPolicyBanner(AdFormat.banner),
  interstitialAction(AdFormat.interstitial),
  rewarded(AdFormat.rewarded),
  appOpen(AdFormat.appOpen);

  const AdPlacement(this.format);

  final AdFormat format;

  bool get isFullScreen =>
      format == AdFormat.interstitial ||
      format == AdFormat.rewarded ||
      format == AdFormat.appOpen;
}

/// Why an advertisement request was refused. The list is intentionally
/// fail-closed: any condition that cannot be evaluated blocks the ad.
enum AdBlockReason {
  adsNotConfigured,
  consentNotObtained,
  adFreeEntitlement,
  lightActive,
  essentialInitialization,
  appNotResumed,
  updateCheckInProgress,
  mandatoryUpdateActive,
  updateFlowActive,
  purchaseFlowActive,
  fullscreenAdVisible,
  frequencyCooldown,
  fullscreenFormatCooldown,
  dailyLimitReached,
  noPendingTrigger,
  adNotReady,
}

/// Meaningful, explicitly approved user actions that advance the interstitial
/// counter. Torch control, SOS, strobe, Morse, shake, Quick Settings, consent,
/// permissions, and purchases are deliberately absent.
enum AdActionId {
  openSettings,
  closeSettings,
  openPrivacyPolicy,
  closePrivacyPolicy,
  openLicenses,
  closeLicenses,
  settingsLanguage,
  settingsHaptics,
  settingsReduceAnimations,
  settingsDefaultMode,
  settingsKeepScreenAwake,
}

class AdEligibility {
  const AdEligibility.allowed() : isAllowed = true, reason = null;

  const AdEligibility.blocked(AdBlockReason this.reason) : isAllowed = false;

  final bool isAllowed;
  final AdBlockReason? reason;

  @override
  String toString() =>
      isAllowed ? 'AdEligibility.allowed' : 'AdEligibility.blocked($reason)';
}

/// A snapshot of the app conditions that influence ad eligibility. It is
/// produced synchronously from the existing Bloc/Cubit state so eligibility can
/// be answered without waiting on any asynchronous work.
class AdRequestContext {
  const AdRequestContext({
    required this.lightActive,
    required this.essentialInitialization,
    required this.appResumed,
    required this.updateCheckInProgress,
    required this.mandatoryUpdateActive,
    required this.updateFlowActive,
    required this.purchaseFlowActive,
    required this.fullscreenAdVisible,
    required this.firstSession,
  });

  const AdRequestContext.blockedAll()
    : lightActive = true,
      essentialInitialization = true,
      appResumed = false,
      updateCheckInProgress = true,
      mandatoryUpdateActive = true,
      updateFlowActive = true,
      purchaseFlowActive = true,
      fullscreenAdVisible = true,
      firstSession = true;

  final bool lightActive;
  final bool essentialInitialization;
  final bool appResumed;
  final bool updateCheckInProgress;
  final bool mandatoryUpdateActive;
  final bool updateFlowActive;
  final bool purchaseFlowActive;
  final bool fullscreenAdVisible;
  final bool firstSession;
}

/// Mutable flags shared between the controller and the composition root.
///
/// It exists so the eligibility context can report "a fullscreen ad is showing"
/// without the context provider depending on the controller it feeds.
class AdRuntimeFlags {
  bool fullscreenVisible = false;

  /// Set while the app hands control to a system surface (for example battery
  /// optimization settings). Returning from that flow must not show an App Open
  /// ad, even though the app really was backgrounded.
  bool externalSystemFlow = false;
}
