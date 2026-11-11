import 'package:flash_light_pro/features/monetization/data/consent_gateway.dart';
import 'package:flash_light_pro/core/config/admob/admob_config.dart';
import 'package:flash_light_pro/features/monetization/domain/ad_models.dart';
import 'package:flash_light_pro/features/monetization/domain/monetization_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('initialization', () {
    test(
      'loads the entitlement, price, and session flag without ads',
      () async {
        final frequency = FakeAdFrequencyStore(firstSession: true);
        final controller = buildTestController(frequencyStore: frequency);

        await controller.initialize();
        // Store reconciliation runs in the background so ads are never blocked
        // by a slow store connection.
        await pumpEventQueue();

        expect(controller.isInitialized, isTrue);
        expect(controller.isFirstSession, isTrue);
        expect(frequency.sessionStarts, 1);
        expect(controller.shouldOfferRemoveAds, isTrue);
        expect(controller.removeAdsPrice, r'US$4.99');
        expect(controller.isSdkReady, isFalse);
        expect(
          controller.isPlacementAllowed(AdPlacement.settingsNative),
          isFalse,
        );

        controller.dispose();
      },
    );

    test(
      'a configuration without ids offers nothing and starts nothing',
      () async {
        final initializer = FakeAdInitializer();
        final controller = buildTestController(
          config: const AdConfig(
            testMode: false,
            androidUnitIds: {},
            iosUnitIds: {},
          ),
          adInitializer: initializer,
        );

        await controller.initialize();
        await controller.startAds();

        expect(controller.shouldOfferRemoveAds, isFalse);
        expect(initializer.calls, 0);
        expect(controller.isSdkReady, isFalse);

        controller.dispose();
      },
    );
  });

  group('startAds', () {
    test('requests consent, initializes the SDK, and preloads', () async {
      final initializer = FakeAdInitializer();
      final presenter = FakeFullScreenPresenter();
      final controller = buildTestController(
        adInitializer: initializer,
        fullscreenPresenter: presenter,
      );

      await controller.startAds();
      await pumpEventQueue();

      expect(initializer.calls, 1);
      expect(controller.isSdkReady, isTrue);
      expect(controller.canRequestAds, isTrue);
      expect(presenter.interstitialLoadCalls, 1);
      expect(presenter.appOpenLoadCalls, 1);
      expect(controller.isPlacementAllowed(AdPlacement.settingsNative), isTrue);

      controller.dispose();
    });

    test('without consent the SDK is never initialized', () async {
      final initializer = FakeAdInitializer();
      final controller = buildTestController(
        consentGateway: FakeConsentGateway(
          info: const ConsentInfo(
            canRequestAds: false,
            formAvailable: false,
            privacyOptionsRequired: false,
          ),
        ),
        adInitializer: initializer,
      );

      await controller.startAds();

      expect(controller.canRequestAds, isFalse);
      expect(initializer.calls, 0);
      expect(controller.isSdkReady, isFalse);
      expect(
        controller.isPlacementAllowed(AdPlacement.settingsNative),
        isFalse,
      );

      controller.dispose();
    });

    test('a consent form is shown before ads can start', () async {
      final gateway =
          FakeConsentGateway(
              info: const ConsentInfo(
                canRequestAds: false,
                formAvailable: true,
                privacyOptionsRequired: true,
              ),
            )
            ..afterFormInfo = const ConsentInfo(
              canRequestAds: true,
              formAvailable: false,
              privacyOptionsRequired: true,
            );
      final controller = buildTestController(consentGateway: gateway);

      await controller.startAds();

      expect(gateway.forms, 1);
      expect(controller.canRequestAds, isTrue);
      expect(controller.privacyOptionsRequired, isTrue);

      controller.dispose();
    });

    test('a failed SDK initialization leaves ads disabled', () async {
      final controller = buildTestController(
        adInitializer: FakeAdInitializer(result: false),
      );

      await controller.startAds();

      expect(controller.isSdkReady, isFalse);
      expect(
        controller.isPlacementAllowed(AdPlacement.settingsNative),
        isFalse,
      );
      expect(
        await controller.maybeShowInterstitial(AdPlacement.interstitialAction),
        isFalse,
      );

      controller.dispose();
    });
  });

  group('fullscreen presentation', () {
    test('interstitial shows only after three eligible actions', () async {
      final frequency = FakeAdFrequencyStore();
      final controller = buildTestController(frequencyStore: frequency);
      await controller.startAds();
      await pumpEventQueue();

      await controller.registerEligibleAction(AdActionId.openSettings);
      await controller.registerEligibleAction(AdActionId.openPrivacyPolicy);
      expect(controller.eligibleActionCount, 2);
      expect(controller.pendingInterstitial, isFalse);

      await controller.registerEligibleAction(AdActionId.closePrivacyPolicy);
      expect(controller.eligibleActionCount, 3);
      expect(controller.pendingInterstitial, isTrue);

      final shown = await controller.maybeShowInterstitial(
        AdPlacement.interstitialAction,
      );

      expect(shown, isTrue);
      expect(frequency.state.lastInterstitialAt, isNotNull);
      expect(controller.eligibleActionCount, 0);
      expect(controller.pendingInterstitial, isFalse);

      controller.dispose();
    });

    test('an ad-free entitlement stops the counter', () async {
      final controller = buildTestController(
        adFreeStore: FakeAdFreeStore(owned: true),
      );
      await controller.startAds();
      await pumpEventQueue();

      expect(
        await controller.registerEligibleAction(AdActionId.openSettings),
        isFalse,
      );
      expect(controller.eligibleActionCount, 0);

      controller.dispose();
    });

    test('app-open is allowed on the first session', () async {
      final presenter = FakeFullScreenPresenter();
      final controller = buildTestController(
        context: MutableAdContext(firstSession: true),
        frequencyStore: FakeAdFrequencyStore(firstSession: true),
        fullscreenPresenter: presenter,
      );
      await controller.startAds();
      await pumpEventQueue();

      expect(await controller.maybeShowAppOpen(), isTrue);
      expect(presenter.appOpenShows, 1);

      controller.dispose();
    });

    test('app-open waits while an interstitial trigger is pending', () async {
      final presenter = FakeFullScreenPresenter();
      final controller = buildTestController(fullscreenPresenter: presenter);
      await controller.startAds();
      await pumpEventQueue();

      for (var i = 0; i < 3; i++) {
        await controller.registerEligibleAction(AdActionId.values[i]);
      }
      expect(controller.pendingInterstitial, isTrue);

      expect(await controller.maybeShowAppOpen(), isFalse);
      expect(presenter.appOpenShows, 0);

      controller.dispose();
    });
  });

  group('remove ads', () {
    test('a confirmed purchase makes every placement ineligible', () async {
      final billing = FakeBillingGateway();
      final controller = buildTestController(billingGateway: billing);
      await controller.initialize();

      await controller.purchaseRemoveAds();
      billing.emit(status: BillingPurchaseStatus.purchased);
      await pumpEventQueue();

      expect(controller.isAdFree, isTrue);
      expect(controller.removeAdsPhase, RemoveAdsPhase.purchased);
      expect(
        controller.isPlacementAllowed(AdPlacement.settingsNative),
        isFalse,
      );

      controller.dispose();
    });

    test('privacy options refresh the consent decision', () async {
      final gateway = FakeConsentGateway(
        info: const ConsentInfo(
          canRequestAds: false,
          formAvailable: false,
          privacyOptionsRequired: true,
        ),
      );
      final controller = buildTestController(consentGateway: gateway);
      await controller.startAds();

      expect(controller.canRequestAds, isFalse);

      gateway.afterFormInfo = const ConsentInfo(
        canRequestAds: true,
        formAvailable: false,
        privacyOptionsRequired: true,
      );
      await controller.showPrivacyOptions();

      expect(gateway.privacyOptionsShown, 1);
      expect(controller.canRequestAds, isTrue);
      expect(controller.isSdkReady, isTrue);

      controller.dispose();
    });
  });

  test('dispose releases services exactly once', () async {
    final presenter = FakeFullScreenPresenter();
    final rewarded = FakeRewardedPresenter();
    final consent = FakeConsentGateway();
    final controller = buildTestController(
      consentGateway: consent,
      fullscreenPresenter: presenter,
      rewardedPresenter: rewarded,
    );

    controller.dispose();

    expect(presenter.disposed, isTrue);
    expect(rewarded.disposed, isTrue);
    expect(consent.disposed, isTrue);
  });
}
