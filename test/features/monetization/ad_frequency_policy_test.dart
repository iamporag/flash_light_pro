import 'package:flash_light_pro/features/monetization/domain/ad_frequency_policy.dart';
import 'package:flash_light_pro/features/monetization/domain/ad_models.dart';
import 'package:flutter_test/flutter_test.dart';

const AdFrequencyPolicy policy = AdFrequencyPolicy(
  interstitialMinInterval: Duration(minutes: 2),
  interstitialDailyCap: 5,
  appOpenCooldown: Duration(hours: 4),
);

AdFrequencyState pendingState() {
  var state = const AdFrequencyState();
  for (var i = 0; i < 3; i++) {
    state = policy.registerEligibleAction(state);
  }
  return state;
}

void main() {
  final now = DateTime(2026, 1, 1, 12);

  group('eligible action cycle', () {
    test('the third action reaches the trigger once', () {
      var state = const AdFrequencyState();
      state = policy.registerEligibleAction(state);
      expect(state.eligibleActionCount, 1);
      expect(state.pendingInterstitial, isFalse);

      state = policy.registerEligibleAction(state);
      expect(state.eligibleActionCount, 2);
      expect(state.pendingInterstitial, isFalse);

      state = policy.registerEligibleAction(state);
      expect(state.eligibleActionCount, 3);
      expect(state.pendingInterstitial, isTrue);
    });

    test('the counter freezes while a trigger is pending', () {
      var state = pendingState();
      final next = policy.registerEligibleAction(state);

      expect(next.eligibleActionCount, 3);
      expect(next.pendingInterstitial, isTrue);
      expect(identical(state, next), isTrue);
    });

    test('only a confirmed impression resets the cycle', () {
      final state = pendingState();
      final blocked = policy.interstitialBlockReason(
        state,
        now,
        requirePending: false,
      );
      expect(blocked, isNull);
      expect(state.eligibleActionCount, 3);
      expect(state.pendingInterstitial, isTrue);

      final recorded = policy.recordInterstitial(state, now);
      expect(recorded.eligibleActionCount, 0);
      expect(recorded.pendingInterstitial, isFalse);
    });
  });

  group('interstitial frequency', () {
    test('a trigger is required before an impression may be shown', () {
      expect(
        policy.interstitialBlockReason(const AdFrequencyState(), now),
        AdBlockReason.noPendingTrigger,
      );
      expect(policy.interstitialBlockReason(pendingState(), now), isNull);
    });

    test('a second impression inside two minutes is blocked', () {
      final state = policy.recordInterstitial(pendingState(), now);

      expect(
        policy.interstitialBlockReason(
          state,
          now.add(const Duration(minutes: 1, seconds: 59)),
          requirePending: false,
        ),
        AdBlockReason.frequencyCooldown,
      );
      expect(
        policy.interstitialBlockReason(
          state,
          now.add(const Duration(minutes: 2)),
          requirePending: false,
        ),
        isNull,
      );
    });

    test('the daily cap blocks a sixth impression on the same day', () {
      var state = const AdFrequencyState();
      var time = now;
      for (var i = 0; i < 5; i++) {
        state = policy.recordInterstitial(state, time);
        time = time.add(const Duration(minutes: 3));
      }

      expect(state.interstitialCount, 5);
      expect(
        policy.interstitialBlockReason(state, time, requirePending: false),
        AdBlockReason.dailyLimitReached,
      );
    });

    test('the count resets on a new local day', () {
      var state = const AdFrequencyState();
      var time = DateTime(2025, 12, 31, 10);
      for (var i = 0; i < 5; i++) {
        state = policy.recordInterstitial(state, time);
        time = time.add(const Duration(minutes: 3));
      }
      expect(state.interstitialDayKey, '2025-12-31');

      final nextDay = DateTime(2026, 1, 1, 9);
      expect(
        policy.interstitialBlockReason(state, nextDay, requirePending: false),
        isNull,
      );

      final recorded = policy.recordInterstitial(state, nextDay);
      expect(recorded.interstitialCount, 1);
      expect(recorded.interstitialDayKey, '2026-01-01');
    });

    test('a recorded impression stores the timestamp, day, and format', () {
      final state = policy.recordInterstitial(pendingState(), now);

      expect(state.lastInterstitialAt, now);
      expect(state.interstitialCount, 1);
      expect(state.interstitialDayKey, '2026-01-01');
      expect(state.lastFullscreenFormat, AdFormat.interstitial);
    });
  });

  group('app-open frequency', () {
    test('the first eligible session is allowed', () {
      expect(policy.appOpenBlockReason(const AdFrequencyState(), now), isNull);
    });

    test('the four hour cooldown is enforced', () {
      final state = policy.recordAppOpen(const AdFrequencyState(), now);

      expect(
        policy.appOpenBlockReason(
          state,
          now.add(const Duration(hours: 3, minutes: 59)),
        ),
        AdBlockReason.frequencyCooldown,
      );
      expect(
        policy.appOpenBlockReason(state, now.add(const Duration(hours: 4))),
        isNull,
      );
    });
  });

  group('fullscreen format coordination', () {
    test('an interstitial is blocked right after an app open', () {
      final state = policy.recordAppOpen(const AdFrequencyState(), now);

      expect(
        policy.interstitialBlockReason(
          state.copyWith(pendingInterstitial: true),
          now.add(const Duration(minutes: 1)),
        ),
        AdBlockReason.fullscreenFormatCooldown,
      );
      expect(
        policy.interstitialBlockReason(
          state.copyWith(pendingInterstitial: true),
          now.add(const Duration(minutes: 2)),
        ),
        isNull,
      );
    });

    test('an app open is blocked right after an interstitial', () {
      final state = policy.recordInterstitial(pendingState(), now);

      expect(
        policy.appOpenBlockReason(state, now.add(const Duration(minutes: 1))),
        AdBlockReason.fullscreenFormatCooldown,
      );
      expect(
        policy.appOpenBlockReason(state, now.add(const Duration(minutes: 2))),
        isNull,
      );
    });
  });
}
