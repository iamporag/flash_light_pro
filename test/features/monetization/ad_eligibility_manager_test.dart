import 'package:flash_light_pro/features/monetization/application/ad_eligibility_manager.dart';
import 'package:flash_light_pro/features/monetization/application/ad_free_entitlement_service.dart';
import 'package:flash_light_pro/features/monetization/application/consent_manager.dart';
import 'package:flash_light_pro/features/monetization/data/consent_gateway.dart';
import 'package:flash_light_pro/features/monetization/domain/ad_config.dart';
import 'package:flash_light_pro/features/monetization/domain/ad_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

class _Harness {
  _Harness({
    AdConfig? config,
    MutableAdContext? context,
    FakeConsentGateway? consentGateway,
    FakeAdFreeStore? adFreeStore,
    FakeBillingGateway? billing,
    FakeAdFrequencyStore? frequencyStore,
    DateTime Function()? clock,
  }) : context = context ?? MutableAdContext(),
       consentGateway = consentGateway ?? FakeConsentGateway(),
       adFreeStore = adFreeStore ?? FakeAdFreeStore(),
       billing = billing ?? FakeBillingGateway(),
       frequencyStore = frequencyStore ?? FakeAdFrequencyStore(),
       clock = clock ?? (() => DateTime(2026, 1, 1, 12)),
       config = config ?? AdConfig.test();

  final AdConfig config;
  final MutableAdContext context;
  final FakeConsentGateway consentGateway;
  final FakeAdFreeStore adFreeStore;
  final FakeBillingGateway billing;
  final FakeAdFrequencyStore frequencyStore;
  final DateTime Function() clock;

  late final ConsentManager consent;
  late final AdFreeEntitlementService entitlement;
  late final AdEligibilityManager eligibility;

  Future<void> setUp() async {
    consent = ConsentManager(gateway: consentGateway);
    await consent.initialize();

    entitlement = AdFreeEntitlementService(
      store: adFreeStore,
      gateway: billing,
    );
    await entitlement.initialize(reconcileSilently: false);

    eligibility = AdEligibilityManager(
      config: config,
      contextProvider: context.call,
      entitlement: entitlement,
      consent: consent,
      frequencyStore: frequencyStore,
      clock: clock,
    );
    await eligibility.loadPersistedState();
  }
}

AdEligibility check(
  AdEligibilityManager manager,
  AdPlacement placement, {
  bool ready = false,
}) {
  return manager.check(placement, ready: ready);
}

void main() {
  group('configuration and consent', () {
    test('missing ad unit ids block every placement', () async {
      final harness = _Harness(
        config: const AdConfig(
          testMode: false,
          androidUnitIds: {},
          iosUnitIds: {},
        ),
      );
      await harness.setUp();

      expect(
        check(harness.eligibility, AdPlacement.settingsNative).reason,
        AdBlockReason.adsNotConfigured,
      );
    });

    test('no ad is allowed before consent', () async {
      final harness = _Harness(
        consentGateway: FakeConsentGateway(
          info: const ConsentInfo(
            canRequestAds: false,
            formAvailable: false,
            privacyOptionsRequired: false,
          ),
        ),
      );
      await harness.setUp();

      expect(
        check(harness.eligibility, AdPlacement.settingsNative).reason,
        AdBlockReason.consentNotObtained,
      );
    });

    test('consent errors leave ads blocked', () async {
      final gateway = FakeConsentGateway()..throwOnRequest = true;
      final consent = ConsentManager(gateway: gateway);
      await consent.initialize();

      final harness = _Harness(consentGateway: gateway);
      await harness.setUp();

      expect(consent.canRequestAds, isFalse);
      expect(consent.phase, ConsentPhase.failed);
      expect(
        check(harness.eligibility, AdPlacement.settingsNative).reason,
        AdBlockReason.consentNotObtained,
      );
    });

    test(
      'the remove ads entitlement blocks ads even when configured',
      () async {
        final harness = _Harness(adFreeStore: FakeAdFreeStore(owned: true));
        await harness.setUp();

        expect(harness.entitlement.isAdFree, isTrue);
        expect(
          check(harness.eligibility, AdPlacement.settingsNative).reason,
          AdBlockReason.adFreeEntitlement,
        );
      },
    );
  });

  group('app state', () {
    late _Harness harness;

    setUp(() async {
      harness = _Harness();
      await harness.setUp();
    });

    test('the default state allows a settings native ad', () {
      expect(
        check(harness.eligibility, AdPlacement.settingsNative).isAllowed,
        isTrue,
      );
    });

    test('an active light blocks every format', () async {
      harness.context.lightActive = true;

      for (final placement in AdPlacement.values) {
        expect(
          check(harness.eligibility, placement).reason,
          AdBlockReason.lightActive,
          reason: '$placement',
        );
      }
    });

    test('mandatory updates outrank every other ad request', () async {
      harness.context.mandatoryUpdateActive = true;

      expect(
        check(harness.eligibility, AdPlacement.appOpen, ready: true).reason,
        AdBlockReason.mandatoryUpdateActive,
      );
      expect(
        check(
          harness.eligibility,
          AdPlacement.privacyPolicyExit,
          ready: true,
        ).reason,
        AdBlockReason.mandatoryUpdateActive,
      );
    });

    test('an update check, update flow, or init blocks ads', () async {
      harness.context.updateCheckInProgress = true;
      expect(
        check(harness.eligibility, AdPlacement.settingsNative).reason,
        AdBlockReason.updateCheckInProgress,
      );

      harness.context.updateCheckInProgress = false;
      harness.context.updateFlowActive = true;
      expect(
        check(harness.eligibility, AdPlacement.settingsNative).reason,
        AdBlockReason.updateFlowActive,
      );

      harness.context.updateFlowActive = false;
      harness.context.essentialInitialization = true;
      expect(
        check(harness.eligibility, AdPlacement.settingsNative).reason,
        AdBlockReason.essentialInitialization,
      );
    });

    test('a backgrounded or covered app blocks ads', () async {
      harness.context.appResumed = false;
      expect(
        check(harness.eligibility, AdPlacement.settingsNative).reason,
        AdBlockReason.appNotResumed,
      );

      harness.context.appResumed = true;
      harness.context.fullscreenAdVisible = true;
      expect(
        check(harness.eligibility, AdPlacement.settingsNative).reason,
        AdBlockReason.fullscreenAdVisible,
      );
    });

    test('a fullscreen placement must be confirmed ready', () {
      expect(
        check(harness.eligibility, AdPlacement.privacyPolicyExit).reason,
        AdBlockReason.adNotReady,
      );
      expect(
        check(
          harness.eligibility,
          AdPlacement.privacyPolicyExit,
          ready: true,
        ).isAllowed,
        isTrue,
      );
    });
  });

  group('frequency', () {
    test(
      'an interstitial impression starts the five minute cooldown',
      () async {
        var now = DateTime(2026, 1, 1, 12);
        final harness = _Harness(clock: () => now);
        await harness.setUp();

        await harness.eligibility.recordImpression(
          AdPlacement.privacyPolicyExit,
        );

        now = now.add(const Duration(minutes: 4));
        expect(
          check(
            harness.eligibility,
            AdPlacement.privacyPolicyExit,
            ready: true,
          ).reason,
          AdBlockReason.frequencyCooldown,
        );

        now = now.add(const Duration(minutes: 1));
        expect(
          check(
            harness.eligibility,
            AdPlacement.privacyPolicyExit,
            ready: true,
          ).isAllowed,
          isTrue,
        );
      },
    );

    test('three interstitials in one day block the fourth', () async {
      var now = DateTime(2026, 1, 1, 12);
      final store = FakeAdFrequencyStore();
      final harness = _Harness(clock: () => now, frequencyStore: store);
      await harness.setUp();

      for (var i = 0; i < 3; i++) {
        await harness.eligibility.recordImpression(
          AdPlacement.privacyPolicyExit,
        );
        now = now.add(const Duration(minutes: 6));
      }

      expect(
        check(
          harness.eligibility,
          AdPlacement.privacyPolicyExit,
          ready: true,
        ).reason,
        AdBlockReason.dailyLimitReached,
      );
      expect(store.saves, 3);
    });

    test('app-open is never allowed during the first session', () async {
      final harness = _Harness(context: MutableAdContext(firstSession: true));
      await harness.setUp();

      expect(
        check(harness.eligibility, AdPlacement.appOpen, ready: true).reason,
        AdBlockReason.appOpenFirstSession,
      );
    });

    test('app-open respects the four hour cooldown', () async {
      var now = DateTime(2026, 1, 1, 12);
      final harness = _Harness(clock: () => now);
      await harness.setUp();

      await harness.eligibility.recordImpression(AdPlacement.appOpen);

      now = now.add(const Duration(hours: 3));
      expect(
        check(harness.eligibility, AdPlacement.appOpen, ready: true).reason,
        AdBlockReason.frequencyCooldown,
      );

      now = now.add(const Duration(hours: 1));
      expect(
        check(harness.eligibility, AdPlacement.appOpen, ready: true).isAllowed,
        isTrue,
      );
    });

    test(
      'a second fullscreen format waits for the separation window',
      () async {
        var now = DateTime(2026, 1, 1, 12);
        final harness = _Harness(clock: () => now);
        await harness.setUp();

        await harness.eligibility.recordImpression(
          AdPlacement.privacyPolicyExit,
        );

        now = now.add(const Duration(seconds: 29));
        expect(
          check(harness.eligibility, AdPlacement.appOpen, ready: true).reason,
          AdBlockReason.frequencyCooldown,
        );
      },
    );

    test('persisted frequency data is enforced after a restart', () async {
      final now = DateTime(2026, 1, 1, 12);
      final store = FakeAdFrequencyStore();
      final first = _Harness(clock: () => now, frequencyStore: store);
      await first.setUp();
      await first.eligibility.recordImpression(AdPlacement.appOpen);

      final restarted = _Harness(clock: () => now, frequencyStore: store);
      await restarted.setUp();

      expect(
        check(restarted.eligibility, AdPlacement.appOpen, ready: true).reason,
        AdBlockReason.frequencyCooldown,
      );
    });
  });
}
