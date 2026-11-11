import 'package:flash_light_pro/features/monetization/application/ad_eligibility_manager.dart';
import 'package:flash_light_pro/features/monetization/application/ad_free_entitlement_service.dart';
import 'package:flash_light_pro/features/monetization/application/consent_manager.dart';
import 'package:flash_light_pro/features/monetization/application/rewarded_ad_service.dart';
import 'package:flash_light_pro/features/monetization/data/rewarded_ad_presenter.dart';
import 'package:flash_light_pro/core/config/admob/admob_config.dart';
import 'package:flash_light_pro/features/monetization/domain/ad_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

Future<RewardedAdService> buildService({
  required FakeRewardedPresenter presenter,
  MutableAdContext? context,
  AdConfig? config,
}) async {
  final ctx = context ?? MutableAdContext();
  final consent = ConsentManager(gateway: FakeConsentGateway());
  await consent.initialize();
  final entitlement = AdFreeEntitlementService(
    store: FakeAdFreeStore(),
    gateway: FakeBillingGateway(),
  );
  await entitlement.initialize(reconcileSilently: false);
  final eligibility = AdEligibilityManager(
    config: config ?? AdConfig.test(),
    contextProvider: ctx.call,
    entitlement: entitlement,
    consent: consent,
    frequencyStore: FakeAdFrequencyStore(),
  );
  await eligibility.loadPersistedState();

  return RewardedAdService(
    config: config ?? AdConfig.test(),
    eligibility: eligibility,
    presenter: presenter,
    runtimeFlags: AdRuntimeFlags(),
  );
}

void main() {
  test('a reward is granted only when the SDK confirms completion', () async {
    final presenter = FakeRewardedPresenter();
    final service = await buildService(presenter: presenter);
    var grants = 0;

    final outcome = await service.show(onReward: () => grants++);

    expect(outcome, RewardOutcome.earned);
    expect(grants, 1);
    expect(presenter.shows, 1);
  });

  test('duplicate reward callbacks grant the reward once', () async {
    final presenter = FakeRewardedPresenter(rewardCallbacks: 3);
    final service = await buildService(presenter: presenter);
    var grants = 0;

    final outcome = await service.show(onReward: () => grants++);

    expect(outcome, RewardOutcome.earned);
    expect(grants, 1);
  });

  test('closing without completing grants nothing', () async {
    final presenter = FakeRewardedPresenter(
      outcome: RewardOutcome.dismissedWithoutReward,
      rewardCallbacks: 0,
    );
    final service = await buildService(presenter: presenter);
    var grants = 0;

    final outcome = await service.show(onReward: () => grants++);

    expect(outcome, RewardOutcome.dismissedWithoutReward);
    expect(grants, 0);
  });

  test('a failed presentation grants nothing', () async {
    final presenter = FakeRewardedPresenter(
      outcome: RewardOutcome.failedToShow,
      rewardCallbacks: 0,
    );
    final service = await buildService(presenter: presenter);
    var grants = 0;

    final outcome = await service.show(onReward: () => grants++);

    expect(outcome, RewardOutcome.failedToShow);
    expect(grants, 0);
  });

  test('an earned outcome without a reward callback grants nothing', () async {
    final presenter = FakeRewardedPresenter(rewardCallbacks: 0);
    final service = await buildService(presenter: presenter);
    var grants = 0;

    final outcome = await service.show(onReward: () => grants++);

    expect(outcome, RewardOutcome.dismissedWithoutReward);
    expect(grants, 0);
  });

  test('an active light prevents the rewarded ad from showing', () async {
    final presenter = FakeRewardedPresenter();
    final service = await buildService(
      presenter: presenter,
      context: MutableAdContext(lightActive: true),
    );
    var grants = 0;

    final outcome = await service.show(onReward: () => grants++);

    expect(outcome, RewardOutcome.unavailable);
    expect(presenter.shows, 0);
    expect(grants, 0);
  });

  test('missing configuration prevents the rewarded ad from showing', () async {
    final presenter = FakeRewardedPresenter();
    final service = await buildService(
      presenter: presenter,
      config: const AdConfig(
        testMode: false,
        androidUnitIds: {},
        iosUnitIds: {},
      ),
    );

    expect(await service.show(), RewardOutcome.unavailable);
    expect(presenter.shows, 0);
  });

  test('a second concurrent presentation is refused', () async {
    final presenter = FakeRewardedPresenter();
    final service = await buildService(presenter: presenter);
    var grants = 0;

    final first = service.show(onReward: () => grants++);
    final second = await service.show(onReward: () => grants++);
    final firstOutcome = await first;

    expect(firstOutcome, RewardOutcome.earned);
    expect(second, RewardOutcome.unavailable);
    expect(presenter.shows, 1);
    expect(grants, 1);
  });
}
