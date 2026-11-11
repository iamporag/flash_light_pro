import 'package:flash_light_pro/features/monetization/application/ad_eligibility_manager.dart';
import 'package:flash_light_pro/features/monetization/application/ad_free_entitlement_service.dart';
import 'package:flash_light_pro/features/monetization/application/consent_manager.dart';
import 'package:flash_light_pro/features/monetization/application/fullscreen_ad_coordinator.dart';
import 'package:flash_light_pro/features/monetization/data/fullscreen_ad_presenter.dart';
import 'package:flash_light_pro/core/config/admob/admob_config.dart';
import 'package:flash_light_pro/features/monetization/domain/ad_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

class _Fixture {
  _Fixture({MutableAdContext? context, FakeFullScreenPresenter? presenter})
    : context = context ?? MutableAdContext(),
      presenter = presenter ?? FakeFullScreenPresenter();

  final MutableAdContext context;
  final FakeFullScreenPresenter presenter;
  final FakeAdFrequencyStore frequencyStore = FakeAdFrequencyStore();
  final AdRuntimeFlags runtimeFlags = AdRuntimeFlags();
  late final AdEligibilityManager eligibility;
  late final FullscreenAdCoordinator coordinator;

  Future<void> setUp() async {
    final consent = ConsentManager(gateway: FakeConsentGateway());
    await consent.initialize();
    final entitlement = AdFreeEntitlementService(
      store: FakeAdFreeStore(),
      gateway: FakeBillingGateway(),
    );
    await entitlement.initialize(reconcileSilently: false);
    eligibility = AdEligibilityManager(
      config: AdConfig.test(),
      contextProvider: context.call,
      entitlement: entitlement,
      consent: consent,
      frequencyStore: frequencyStore,
    );
    await eligibility.loadPersistedState();

    coordinator = FullscreenAdCoordinator(
      config: AdConfig.test(),
      eligibility: eligibility,
      presenter: presenter,
      runtimeFlags: runtimeFlags,
    );
  }

  Future<void> reachTrigger() async {
    await eligibility.clickFrequency.register(AdActionId.openSettings);
    await eligibility.clickFrequency.register(AdActionId.openLicenses);
    await eligibility.clickFrequency.register(AdActionId.closeLicenses);
  }
}

void main() {
  group('preload', () {
    test('loads both fullscreen formats when the app is eligible', () async {
      final fixture = _Fixture();
      await fixture.setUp();

      await fixture.coordinator.preload();

      expect(fixture.presenter.interstitialLoadCalls, 1);
      expect(fixture.presenter.appOpenLoadCalls, 1);
      expect(fixture.presenter.interstitialShows, 0);
      expect(fixture.presenter.appOpenShows, 0);
    });

    test('loads nothing while a light is active', () async {
      final fixture = _Fixture(context: MutableAdContext(lightActive: true));
      await fixture.setUp();

      await fixture.coordinator.preload();

      expect(fixture.presenter.interstitialLoadCalls, 0);
      expect(fixture.presenter.appOpenLoadCalls, 0);
    });

    test('loads nothing while an update is mandatory', () async {
      final fixture = _Fixture(
        context: MutableAdContext(mandatoryUpdateActive: true),
      );
      await fixture.setUp();

      await fixture.coordinator.preload();

      expect(fixture.presenter.interstitialLoadCalls, 0);
      expect(fixture.presenter.appOpenLoadCalls, 0);
    });
  });

  group('interstitial', () {
    test('skips immediately when the ad is not ready', () async {
      final fixture = _Fixture();
      await fixture.setUp();
      await fixture.reachTrigger();

      final shown = await fixture.coordinator.maybeShowInterstitial(
        AdPlacement.interstitialAction,
      );

      expect(shown, isFalse);
      expect(fixture.presenter.interstitialShows, 0);
      expect(fixture.presenter.interstitialLoadCalls, greaterThanOrEqualTo(1));
    });

    test('does nothing without a pending trigger', () async {
      final fixture = _Fixture();
      await fixture.setUp();
      await fixture.coordinator.preload();

      final shown = await fixture.coordinator.maybeShowInterstitial(
        AdPlacement.interstitialAction,
      );

      expect(shown, isFalse);
      expect(fixture.presenter.interstitialShows, 0);
    });

    test('presents once and records the impression', () async {
      final fixture = _Fixture();
      await fixture.setUp();
      await fixture.reachTrigger();
      await fixture.coordinator.preload();

      final shown = await fixture.coordinator.maybeShowInterstitial(
        AdPlacement.interstitialAction,
      );

      expect(shown, isTrue);
      expect(fixture.presenter.interstitialShows, 1);
      expect(fixture.frequencyStore.state.lastInterstitialAt, isNotNull);
      expect(fixture.frequencyStore.state.eligibleActionCount, 0);
      expect(fixture.runtimeFlags.fullscreenVisible, isFalse);
    });

    test('does not record an impression when presentation fails', () async {
      final fixture = _Fixture(
        presenter: FakeFullScreenPresenter(
          outcome: FullScreenAdOutcome.failedToShow,
        ),
      );
      await fixture.setUp();
      await fixture.reachTrigger();
      await fixture.coordinator.preload();

      final shown = await fixture.coordinator.maybeShowInterstitial(
        AdPlacement.interstitialAction,
      );

      expect(shown, isFalse);
      expect(fixture.frequencyStore.state.lastInterstitialAt, isNull);
      expect(fixture.frequencyStore.state.pendingInterstitial, isTrue);
    });

    test('refuses a placement that is not an action interstitial', () async {
      final fixture = _Fixture();
      await fixture.setUp();
      await fixture.reachTrigger();
      await fixture.coordinator.preload();

      expect(
        await fixture.coordinator.maybeShowInterstitial(
          AdPlacement.settingsNative,
        ),
        isFalse,
      );
      expect(fixture.presenter.interstitialShows, 0);
    });

    test('an active light prevents presentation', () async {
      final fixture = _Fixture();
      await fixture.setUp();
      await fixture.reachTrigger();
      await fixture.coordinator.preload();

      fixture.context.lightActive = true;

      expect(
        await fixture.coordinator.maybeShowInterstitial(
          AdPlacement.interstitialAction,
        ),
        isFalse,
      );
      expect(fixture.presenter.interstitialShows, 0);
    });
  });

  group('app open', () {
    test('is shown on the first eligible session', () async {
      final fixture = _Fixture(context: MutableAdContext(firstSession: true));
      await fixture.setUp();
      await fixture.coordinator.preload();

      expect(await fixture.coordinator.maybeShowAppOpen(), isTrue);
      expect(fixture.presenter.appOpenShows, 1);
      expect(fixture.frequencyStore.state.lastAppOpenAt, isNotNull);
    });

    test('presents and records the cooldown timestamp', () async {
      final fixture = _Fixture();
      await fixture.setUp();
      await fixture.coordinator.preload();

      expect(await fixture.coordinator.maybeShowAppOpen(), isTrue);
      expect(fixture.presenter.appOpenShows, 1);
      expect(fixture.frequencyStore.state.lastAppOpenAt, isNotNull);
    });

    test('skips while another fullscreen ad is visible', () async {
      final fixture = _Fixture();
      await fixture.setUp();
      await fixture.coordinator.preload();

      fixture.runtimeFlags.fullscreenVisible = true;

      expect(await fixture.coordinator.maybeShowAppOpen(), isFalse);
      expect(fixture.presenter.appOpenShows, 0);
    });
  });

  test('dispose releases the presenter', () async {
    final fixture = _Fixture();
    await fixture.setUp();
    fixture.coordinator.dispose();

    expect(fixture.presenter.disposed, isTrue);
  });
}
