import 'package:flash_light_pro/features/monetization/application/ad_click_frequency_manager.dart';
import 'package:flash_light_pro/features/monetization/domain/ad_frequency_policy.dart';
import 'package:flash_light_pro/features/monetization/domain/ad_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

const AdFrequencyPolicy policy = AdFrequencyPolicy(
  interstitialMinInterval: Duration(minutes: 2),
  interstitialDailyCap: 5,
  appOpenCooldown: Duration(hours: 4),
);

AdClickFrequencyManager buildManager({
  FakeAdFrequencyStore? store,
  DateTime Function()? clock,
}) {
  return AdClickFrequencyManager(
    store: store ?? FakeAdFrequencyStore(),
    policy: policy,
    clock: clock,
  );
}

void main() {
  final now = DateTime(2026, 1, 1, 12);

  test('counts eligible actions and triggers on the third', () async {
    final manager = buildManager();
    await manager.load();

    final first = await manager.register(AdActionId.openSettings);
    expect(first.count, 1);
    expect(first.triggerReached, isFalse);

    final second = await manager.register(AdActionId.openPrivacyPolicy);
    expect(second.count, 2);
    expect(second.triggerReached, isFalse);

    final third = await manager.register(AdActionId.closePrivacyPolicy);
    expect(third.count, 3);
    expect(third.triggerReached, isTrue);
    expect(manager.hasPendingInterstitial, isTrue);
  });

  test('a trigger freezes the counter until a confirmed impression', () async {
    final manager = buildManager();
    await manager.load();
    await manager.register(AdActionId.openSettings);
    await manager.register(AdActionId.openLicenses);
    await manager.register(AdActionId.closeLicenses);

    final extra = await manager.register(AdActionId.openLicenses);
    expect(extra.counted, isFalse);
    expect(extra.triggerReached, isTrue);
    expect(manager.eligibleActionCount, 3);

    await manager.recordInterstitial(now);

    expect(manager.eligibleActionCount, 0);
    expect(manager.hasPendingInterstitial, isFalse);
  });

  test('repeated callbacks for one action are deduplicated', () async {
    final manager = buildManager(clock: () => now);
    await manager.load();

    await manager.register(AdActionId.openSettings);
    final duplicate = await manager.register(AdActionId.openSettings);

    expect(duplicate.duplicate, isTrue);
    expect(duplicate.counted, isFalse);
    expect(manager.eligibleActionCount, 1);
  });

  test('a different action is counted even in the same window', () async {
    final manager = buildManager(clock: () => now);
    await manager.load();

    await manager.register(AdActionId.openSettings);
    await manager.register(AdActionId.closeSettings);

    expect(manager.eligibleActionCount, 2);
  });

  test('the counter and trigger survive a restart', () async {
    final store = FakeAdFrequencyStore();
    final first = buildManager(store: store);
    await first.load();
    await first.register(AdActionId.openSettings);
    await first.register(AdActionId.openLicenses);
    await first.register(AdActionId.closeLicenses);

    final restarted = buildManager(store: store);
    await restarted.load();

    expect(restarted.eligibleActionCount, 3);
    expect(restarted.hasPendingInterstitial, isTrue);
  });

  test('the daily count resets on a new local day', () async {
    var clock = DateTime(2026, 1, 1, 12);
    final manager = buildManager(clock: () => clock);
    await manager.load();

    for (var i = 0; i < 5; i++) {
      await manager.recordInterstitial(clock);
      clock = clock.add(const Duration(minutes: 3));
    }
    expect(
      manager.interstitialBlockReason(clock, requirePending: false),
      AdBlockReason.dailyLimitReached,
    );

    clock = DateTime(2026, 1, 2, 9);
    expect(
      manager.interstitialBlockReason(clock, requirePending: false),
      isNull,
    );
  });
}
