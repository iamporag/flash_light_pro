import 'ad_models.dart';

class AdFrequencyState {
  const AdFrequencyState({
    this.lastInterstitialAt,
    this.interstitialCount = 0,
    this.interstitialDayKey,
    this.lastAppOpenAt,
  });

  final DateTime? lastInterstitialAt;
  final int interstitialCount;
  final String? interstitialDayKey;
  final DateTime? lastAppOpenAt;

  AdFrequencyState copyWith({
    DateTime? lastInterstitialAt,
    int? interstitialCount,
    String? interstitialDayKey,
    DateTime? lastAppOpenAt,
  }) {
    return AdFrequencyState(
      lastInterstitialAt: lastInterstitialAt ?? this.lastInterstitialAt,
      interstitialCount: interstitialCount ?? this.interstitialCount,
      interstitialDayKey: interstitialDayKey ?? this.interstitialDayKey,
      lastAppOpenAt: lastAppOpenAt ?? this.lastAppOpenAt,
    );
  }
}

/// Pure frequency rules for fullscreen ads. Impressions are only recorded
/// after the SDK confirms that an ad was presented, so a failed load or a
/// skipped ad never consumes a user's allowance.
class AdFrequencyPolicy {
  const AdFrequencyPolicy({
    required this.interstitialMinInterval,
    required this.interstitialDailyCap,
    required this.appOpenCooldown,
  });

  final Duration interstitialMinInterval;
  final int interstitialDailyCap;
  final Duration appOpenCooldown;

  AdBlockReason? interstitialBlockReason(AdFrequencyState state, DateTime now) {
    final last = state.lastInterstitialAt;
    if (last != null && now.difference(last) < interstitialMinInterval) {
      return AdBlockReason.frequencyCooldown;
    }

    final today = _dayKey(now);
    final count = state.interstitialDayKey == today
        ? state.interstitialCount
        : 0;
    if (count >= interstitialDailyCap) {
      return AdBlockReason.dailyLimitReached;
    }
    return null;
  }

  AdBlockReason? appOpenBlockReason(
    AdFrequencyState state,
    DateTime now, {
    required bool firstSession,
  }) {
    if (firstSession) return AdBlockReason.appOpenFirstSession;

    final last = state.lastAppOpenAt;
    if (last != null && now.difference(last) < appOpenCooldown) {
      return AdBlockReason.frequencyCooldown;
    }
    return null;
  }

  AdFrequencyState recordInterstitial(AdFrequencyState state, DateTime now) {
    final today = _dayKey(now);
    final count = state.interstitialDayKey == today
        ? state.interstitialCount + 1
        : 1;
    return state.copyWith(
      lastInterstitialAt: now,
      interstitialCount: count,
      interstitialDayKey: today,
    );
  }

  AdFrequencyState recordAppOpen(AdFrequencyState state, DateTime now) {
    return state.copyWith(lastAppOpenAt: now);
  }

  static String _dayKey(DateTime time) {
    final local = time.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
