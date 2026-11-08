import 'ad_models.dart';

class AdFrequencyState {
  const AdFrequencyState({
    this.lastInterstitialAt,
    this.interstitialCount = 0,
    this.interstitialDayKey,
    this.lastAppOpenAt,
    this.eligibleActionCount = 0,
    this.pendingInterstitial = false,
    this.lastFullscreenFormat,
  });

  final DateTime? lastInterstitialAt;
  final int interstitialCount;
  final String? interstitialDayKey;
  final DateTime? lastAppOpenAt;

  /// Approved user actions counted since the last confirmed Interstitial
  /// impression. It is only reset by [AdFrequencyPolicy.recordInterstitial].
  final int eligibleActionCount;

  /// True once the action threshold is reached. The trigger survives failed
  /// loads, cooldowns, and restarts until an Interstitial is actually shown.
  final bool pendingInterstitial;

  /// Format of the last confirmed fullscreen impression, so two fullscreen
  /// formats are never shown back to back.
  final AdFormat? lastFullscreenFormat;

  static const Object _unset = Object();

  AdFrequencyState copyWith({
    DateTime? lastInterstitialAt,
    int? interstitialCount,
    String? interstitialDayKey,
    DateTime? lastAppOpenAt,
    int? eligibleActionCount,
    bool? pendingInterstitial,
    Object? lastFullscreenFormat = _unset,
  }) {
    return AdFrequencyState(
      lastInterstitialAt: lastInterstitialAt ?? this.lastInterstitialAt,
      interstitialCount: interstitialCount ?? this.interstitialCount,
      interstitialDayKey: interstitialDayKey ?? this.interstitialDayKey,
      lastAppOpenAt: lastAppOpenAt ?? this.lastAppOpenAt,
      eligibleActionCount: eligibleActionCount ?? this.eligibleActionCount,
      pendingInterstitial: pendingInterstitial ?? this.pendingInterstitial,
      lastFullscreenFormat: identical(lastFullscreenFormat, _unset)
          ? this.lastFullscreenFormat
          : lastFullscreenFormat as AdFormat?,
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
    this.eligibleActionThreshold = 3,
    this.crossFormatCooldown = const Duration(minutes: 2),
  });

  final Duration interstitialMinInterval;
  final int interstitialDailyCap;
  final Duration appOpenCooldown;
  final int eligibleActionThreshold;
  final Duration crossFormatCooldown;

  /// Counts one approved action. While a trigger is pending the counter is
  /// frozen, so several queued actions can never produce several ads.
  AdFrequencyState registerEligibleAction(AdFrequencyState state) {
    if (state.pendingInterstitial) return state;

    final next = state.eligibleActionCount + 1;
    return state.copyWith(
      eligibleActionCount: next,
      pendingInterstitial: next >= eligibleActionThreshold,
    );
  }

  /// [requirePending] is false for preloading, which must be able to warm an
  /// ad before the user has performed the triggering action.
  AdBlockReason? interstitialBlockReason(
    AdFrequencyState state,
    DateTime now, {
    bool requirePending = true,
  }) {
    if (requirePending && !state.pendingInterstitial) {
      return AdBlockReason.noPendingTrigger;
    }

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

    return _crossFormatBlockReason(state, now, AdFormat.interstitial);
  }

  AdBlockReason? appOpenBlockReason(AdFrequencyState state, DateTime now) {
    final last = state.lastAppOpenAt;
    if (last != null && now.difference(last) < appOpenCooldown) {
      return AdBlockReason.frequencyCooldown;
    }
    return _crossFormatBlockReason(state, now, AdFormat.appOpen);
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
      eligibleActionCount: 0,
      pendingInterstitial: false,
      lastFullscreenFormat: AdFormat.interstitial,
    );
  }

  AdFrequencyState recordAppOpen(AdFrequencyState state, DateTime now) {
    return state.copyWith(
      lastAppOpenAt: now,
      lastFullscreenFormat: AdFormat.appOpen,
    );
  }

  AdBlockReason? _crossFormatBlockReason(
    AdFrequencyState state,
    DateTime now,
    AdFormat requested,
  ) {
    final lastFormat = state.lastFullscreenFormat;
    if (lastFormat == null || lastFormat == requested) return null;

    final lastAt = lastFormat == AdFormat.interstitial
        ? state.lastInterstitialAt
        : state.lastAppOpenAt;
    if (lastAt != null && now.difference(lastAt) < crossFormatCooldown) {
      return AdBlockReason.fullscreenFormatCooldown;
    }
    return null;
  }

  static String dayKey(DateTime time) {
    final local = time.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  static String _dayKey(DateTime time) => dayKey(time);
}
