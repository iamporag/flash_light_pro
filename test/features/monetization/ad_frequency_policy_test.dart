import 'package:flash_light_pro/features/monetization/domain/ad_frequency_policy.dart';
import 'package:flash_light_pro/features/monetization/domain/ad_models.dart';
import 'package:flutter_test/flutter_test.dart';

const AdFrequencyPolicy policy = AdFrequencyPolicy(
  interstitialMinInterval: Duration(minutes: 5),
  interstitialDailyCap: 3,
  appOpenCooldown: Duration(hours: 4),
);

void main() {
  final now = DateTime(2026, 1, 1, 12);

  group('interstitial frequency', () {
    test('the first impression is allowed', () {
      expect(
        policy.interstitialBlockReason(const AdFrequencyState(), now),
        isNull,
      );
    });

    test('a second impression inside five minutes is blocked', () {
      final state = policy.recordInterstitial(const AdFrequencyState(), now);

      expect(
        policy.interstitialBlockReason(
          state,
          now.add(const Duration(minutes: 4, seconds: 59)),
        ),
        AdBlockReason.frequencyCooldown,
      );
      expect(
        policy.interstitialBlockReason(
          state,
          now.add(const Duration(minutes: 5)),
        ),
        isNull,
      );
    });

    test('the daily cap blocks a fourth impression on the same day', () {
      var state = const AdFrequencyState();
      var time = now;
      for (var i = 0; i < 3; i++) {
        expect(policy.interstitialBlockReason(state, time), isNull);
        state = policy.recordInterstitial(state, time);
        time = time.add(const Duration(minutes: 6));
      }

      expect(state.interstitialCount, 3);
      expect(
        policy.interstitialBlockReason(state, time),
        AdBlockReason.dailyLimitReached,
      );
    });

    test('the count resets on a new local day', () {
      var state = const AdFrequencyState();
      var time = DateTime(2025, 12, 31, 10);
      for (var i = 0; i < 3; i++) {
        state = policy.recordInterstitial(state, time);
        time = time.add(const Duration(minutes: 6));
      }
      expect(state.interstitialDayKey, '2025-12-31');

      final nextDay = DateTime(2026, 1, 1, 9);
      expect(policy.interstitialBlockReason(state, nextDay), isNull);

      final recorded = policy.recordInterstitial(state, nextDay);
      expect(recorded.interstitialCount, 1);
      expect(recorded.interstitialDayKey, '2026-01-01');
    });

    test('a recorded impression stores the timestamp and day', () {
      final state = policy.recordInterstitial(const AdFrequencyState(), now);

      expect(state.lastInterstitialAt, now);
      expect(state.interstitialCount, 1);
      expect(state.interstitialDayKey, '2026-01-01');
    });
  });

  group('app-open frequency', () {
    test('the first session is always blocked', () {
      expect(
        policy.appOpenBlockReason(
          const AdFrequencyState(),
          now,
          firstSession: true,
        ),
        AdBlockReason.appOpenFirstSession,
      );
    });

    test('the four hour cooldown is enforced', () {
      final state = policy.recordAppOpen(const AdFrequencyState(), now);

      expect(
        policy.appOpenBlockReason(
          state,
          now.add(const Duration(hours: 3, minutes: 59)),
          firstSession: false,
        ),
        AdBlockReason.frequencyCooldown,
      );
      expect(
        policy.appOpenBlockReason(
          state,
          now.add(const Duration(hours: 4)),
          firstSession: false,
        ),
        isNull,
      );
    });
  });
}
