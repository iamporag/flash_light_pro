import 'dart:async';

import 'package:flash_light_pro/features/monetization/application/ad_free_entitlement_service.dart';
import 'package:flash_light_pro/features/monetization/application/ad_mob_service.dart';
import 'package:flash_light_pro/features/monetization/application/monetization_controller.dart';
import 'package:flash_light_pro/features/monetization/data/ad_frequency_store.dart';
import 'package:flash_light_pro/features/monetization/data/billing_gateway.dart';
import 'package:flash_light_pro/features/monetization/data/consent_gateway.dart';
import 'package:flash_light_pro/features/monetization/data/entitlement_store.dart';
import 'package:flash_light_pro/features/monetization/data/fullscreen_ad_presenter.dart';
import 'package:flash_light_pro/features/monetization/data/rewarded_ad_presenter.dart';
import 'package:flash_light_pro/core/config/admob/admob_config.dart';
import 'package:flash_light_pro/features/monetization/domain/ad_frequency_policy.dart';
import 'package:flash_light_pro/features/monetization/domain/ad_models.dart';
import 'package:flash_light_pro/features/monetization/domain/monetization_models.dart';

const RemoveAdsProduct testRemoveAdsProduct = RemoveAdsProduct(
  id: AdFreeEntitlementService.productId,
  title: 'Remove ads',
  description: 'One-time purchase.',
  price: r'US$4.99',
  currencyCode: 'USD',
);

class FakeAdFrequencyStore implements AdFrequencyStore {
  FakeAdFrequencyStore({
    this.state = const AdFrequencyState(),
    this.firstSession = false,
  });

  AdFrequencyState state;
  bool firstSession;
  int sessionStarts = 0;
  int saves = 0;

  @override
  Future<AdFrequencyState> load() async => state;

  @override
  Future<void> save(AdFrequencyState state) async {
    saves++;
    this.state = state;
  }

  @override
  Future<bool> registerSessionStart() async {
    sessionStarts++;
    return firstSession;
  }
}

class FakeAdFreeStore implements AdFreeStore {
  FakeAdFreeStore({this.owned = false});

  bool owned;
  int saves = 0;

  @override
  Future<bool> loadOwned() async => owned;

  @override
  Future<void> saveOwned(bool owned) async {
    saves++;
    this.owned = owned;
  }
}

class FakeBillingGateway implements BillingGateway {
  FakeBillingGateway({
    this.supported = true,
    this.available = true,
    this.product = testRemoveAdsProduct,
  });

  final StreamController<BillingPurchase> _events =
      StreamController<BillingPurchase>.broadcast();

  bool supported;
  bool available;
  RemoveAdsProduct? product;
  String? queryError;
  bool failBuy = false;
  bool failRestore = false;

  final List<String> bought = [];
  final List<BillingPurchase> completed = [];
  int restoreCount = 0;
  int availabilityChecks = 0;
  int productQueries = 0;
  bool disposed = false;

  @override
  bool get isSupported => supported;

  @override
  Stream<BillingPurchase> get purchases => _events.stream;

  @override
  Future<bool> isAvailable() async {
    availabilityChecks++;
    return available;
  }

  @override
  Future<RemoveAdsProduct?> queryProduct(String productId) async {
    productQueries++;
    if (product?.id != productId) return null;
    return product;
  }

  @override
  String? get lastQueryError => queryError;

  @override
  Future<void> buy(String productId) async {
    if (failBuy) throw StateError('buy failed');
    bought.add(productId);
  }

  @override
  Future<void> restore() async {
    restoreCount++;
    if (failRestore) throw StateError('restore failed');
  }

  @override
  Future<void> complete(BillingPurchase purchase) async {
    completed.add(purchase);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _events.close();
  }

  void emit({
    required BillingPurchaseStatus status,
    String productId = AdFreeEntitlementService.productId,
    bool needsCompletion = true,
  }) {
    _events.add(
      BillingPurchase(
        productId: productId,
        status: status,
        needsCompletion: needsCompletion,
      ),
    );
  }
}

class FakeConsentGateway implements ConsentGateway {
  FakeConsentGateway({
    this.info = const ConsentInfo(
      canRequestAds: true,
      formAvailable: false,
      privacyOptionsRequired: false,
    ),
  });

  ConsentInfo info;
  ConsentInfo? afterFormInfo;
  bool throwOnRequest = false;
  bool throwOnForm = false;
  bool throwOnPrivacyOptions = false;

  int requests = 0;
  int forms = 0;
  int privacyOptionsShown = 0;
  bool disposed = false;

  @override
  Future<ConsentInfo> requestConsentInfo() async {
    requests++;
    if (throwOnRequest) throw ConsentGatewayException('request failed');
    return info;
  }

  @override
  Future<ConsentInfo> refresh() async => afterFormInfo ?? info;

  @override
  Future<void> showFormIfRequired() async {
    forms++;
    if (throwOnForm) throw ConsentGatewayException('form failed');
  }

  @override
  Future<void> showPrivacyOptions() async {
    privacyOptionsShown++;
    if (throwOnPrivacyOptions) {
      throw ConsentGatewayException('privacy options failed');
    }
  }

  @override
  void dispose() {
    disposed = true;
  }
}

class FakeAdInitializer implements AdInitializer {
  FakeAdInitializer({this.result = true});

  bool result;
  int calls = 0;

  @override
  bool get isInitialized => calls > 0 && result;

  @override
  Future<bool> initialize() async {
    calls++;
    return result;
  }
}

class FakeFullScreenPresenter implements FullScreenAdPresenter {
  FakeFullScreenPresenter({
    this.interstitialLoads = true,
    this.appOpenLoads = true,
    this.outcome = FullScreenAdOutcome.dismissed,
  });

  bool interstitialLoads;
  bool appOpenLoads;
  FullScreenAdOutcome outcome;

  @override
  bool interstitialReady = false;

  @override
  bool appOpenReady = false;

  int interstitialLoadCalls = 0;
  int appOpenLoadCalls = 0;
  int interstitialShows = 0;
  int appOpenShows = 0;
  int clearCalls = 0;
  bool disposed = false;

  @override
  Future<bool> loadInterstitial(String unitId) async {
    interstitialLoadCalls++;
    interstitialReady = interstitialLoads;
    return interstitialReady;
  }

  @override
  Future<bool> loadAppOpen(String unitId) async {
    appOpenLoadCalls++;
    appOpenReady = appOpenLoads;
    return appOpenReady;
  }

  @override
  Future<FullScreenAdOutcome> showInterstitial({
    void Function()? onPresented,
  }) async {
    if (!interstitialReady) return FullScreenAdOutcome.unavailable;
    interstitialShows++;
    interstitialReady = false;
    if (outcome != FullScreenAdOutcome.failedToShow) onPresented?.call();
    return outcome;
  }

  @override
  Future<FullScreenAdOutcome> showAppOpen({
    void Function()? onPresented,
  }) async {
    if (!appOpenReady) return FullScreenAdOutcome.unavailable;
    appOpenShows++;
    appOpenReady = false;
    if (outcome != FullScreenAdOutcome.failedToShow) onPresented?.call();
    return outcome;
  }

  @override
  void clearAds() {
    interstitialReady = false;
    appOpenReady = false;
    clearCalls++;
  }

  @override
  void dispose() {
    disposed = true;
  }
}

class FakeRewardedPresenter implements RewardedAdPresenter {
  FakeRewardedPresenter({
    this.ready = true,
    this.outcome = RewardOutcome.earned,
    this.rewardCallbacks = 1,
  });

  bool ready;
  RewardOutcome outcome;
  int rewardCallbacks;

  int loadCalls = 0;
  int shows = 0;
  bool disposed = false;

  @override
  bool get isReady => ready;

  @override
  Future<bool> load(String unitId) async {
    loadCalls++;
    return ready;
  }

  @override
  Future<RewardOutcome> show({void Function()? onRewardGranted}) async {
    shows++;
    ready = false;
    for (var i = 0; i < rewardCallbacks; i++) {
      onRewardGranted?.call();
    }
    return outcome;
  }

  @override
  void dispose() {
    disposed = true;
  }
}

/// Mutable context consumed by [AdEligibilityManager], so each test can flip
/// one condition without rebuilding the manager.
class MutableAdContext {
  MutableAdContext({
    this.lightActive = false,
    this.essentialInitialization = false,
    this.appResumed = true,
    this.updateCheckInProgress = false,
    this.mandatoryUpdateActive = false,
    this.updateFlowActive = false,
    this.purchaseFlowActive = false,
    this.fullscreenAdVisible = false,
    this.firstSession = false,
  });

  bool lightActive;
  bool essentialInitialization;
  bool appResumed;
  bool updateCheckInProgress;
  bool mandatoryUpdateActive;
  bool updateFlowActive;
  bool purchaseFlowActive;
  bool fullscreenAdVisible;
  bool firstSession;

  AdRequestContext call() => AdRequestContext(
    lightActive: lightActive,
    essentialInitialization: essentialInitialization,
    appResumed: appResumed,
    updateCheckInProgress: updateCheckInProgress,
    mandatoryUpdateActive: mandatoryUpdateActive,
    updateFlowActive: updateFlowActive,
    purchaseFlowActive: purchaseFlowActive,
    fullscreenAdVisible: fullscreenAdVisible,
    firstSession: firstSession,
  );
}

MonetizationController buildTestController({
  AdConfig? config,
  MutableAdContext? context,
  FakeAdFreeStore? adFreeStore,
  FakeBillingGateway? billingGateway,
  FakeConsentGateway? consentGateway,
  FakeAdInitializer? adInitializer,
  FakeFullScreenPresenter? fullscreenPresenter,
  FakeRewardedPresenter? rewardedPresenter,
  FakeAdFrequencyStore? frequencyStore,
  AdRuntimeFlags? runtimeFlags,
  DateTime Function()? clock,
}) {
  return MonetizationController(
    config: config ?? AdConfig.test(),
    contextProvider: (context ?? MutableAdContext()).call,
    adFreeStore: adFreeStore ?? FakeAdFreeStore(),
    billingGateway: billingGateway ?? FakeBillingGateway(),
    consentGateway: consentGateway ?? FakeConsentGateway(),
    adInitializer: adInitializer ?? FakeAdInitializer(),
    fullscreenPresenter: fullscreenPresenter ?? FakeFullScreenPresenter(),
    rewardedPresenter: rewardedPresenter ?? FakeRewardedPresenter(),
    frequencyStore: frequencyStore ?? FakeAdFrequencyStore(),
    runtimeFlags: runtimeFlags ?? AdRuntimeFlags(),
    clock: clock,
  );
}
