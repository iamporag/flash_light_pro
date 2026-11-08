import '../data/ad_frequency_store.dart';
import '../domain/ad_frequency_policy.dart';
import '../domain/ad_models.dart';
import 'ad_diagnostics.dart';

/// Result of one explicitly approved user action.
class AdClickRegistration {
  const AdClickRegistration({
    required this.counted,
    required this.triggerReached,
    required this.count,
    this.duplicate = false,
  });

  final bool counted;
  final bool triggerReached;
  final int count;
  final bool duplicate;
}

/// Single owner of the eligible-action counter, the pending Interstitial
/// trigger, and the persisted frequency state.
///
/// The counter advances only for [AdActionId] values passed by the UI. It is
/// reset only after [recordInterstitial] is called from the SDK's confirmed
/// presentation callback, never because a load failed or a cooldown blocked it.
class AdClickFrequencyManager {
  AdClickFrequencyManager({
    required this.store,
    required this.policy,
    DateTime Function()? clock,
    this.dedupeWindow = const Duration(milliseconds: 750),
  }) : _clock = clock ?? DateTime.now;

  final AdFrequencyStore store;
  final AdFrequencyPolicy policy;
  final Duration dedupeWindow;
  final DateTime Function() _clock;

  AdFrequencyState _state = const AdFrequencyState();
  final Map<AdActionId, DateTime> _lastActionAt = {};

  AdFrequencyState get state => _state;
  int get eligibleActionCount => _state.eligibleActionCount;
  bool get hasPendingInterstitial => _state.pendingInterstitial;
  int get actionThreshold => policy.eligibleActionThreshold;

  Future<void> load() async {
    _state = await store.load();
    AdDiagnostics.log(
      'frequency loaded',
      'actions=${_state.eligibleActionCount}/$actionThreshold, '
          'pending=${_state.pendingInterstitial}, '
          'lastFullscreen=${_state.lastFullscreenFormat?.name ?? 'none'}',
    );
  }

  /// Records one approved action. Repeated calls for the same action inside
  /// [dedupeWindow] are ignored so a route callback and a button callback
  /// cannot count the same navigation twice.
  Future<AdClickRegistration> register(AdActionId action) async {
    final now = _clock();
    final last = _lastActionAt[action];
    if (last != null && now.difference(last) < dedupeWindow) {
      AdDiagnostics.log(
        'eligible action ignored',
        '${action.name} (duplicate)',
      );
      return AdClickRegistration(
        counted: false,
        triggerReached: _state.pendingInterstitial,
        count: _state.eligibleActionCount,
        duplicate: true,
      );
    }
    _lastActionAt[action] = now;

    final wasPending = _state.pendingInterstitial;
    if (!wasPending) {
      _state = policy.registerEligibleAction(_state);
      AdDiagnostics.log(
        'eligible action counted',
        '${action.name} ${_state.eligibleActionCount}/$actionThreshold',
      );
    }

    if (_state.pendingInterstitial && !wasPending) {
      AdDiagnostics.log(
        'interstitial trigger reached',
        '$actionThreshold actions',
      );
    } else if (wasPending) {
      AdDiagnostics.log('pending interstitial preserved', action.name);
    }

    await _persist();
    return AdClickRegistration(
      counted: !wasPending,
      triggerReached: _state.pendingInterstitial,
      count: _state.eligibleActionCount,
    );
  }

  AdBlockReason? interstitialBlockReason(
    DateTime now, {
    bool requirePending = true,
  }) {
    return policy.interstitialBlockReason(
      _state,
      now,
      requirePending: requirePending,
    );
  }

  AdBlockReason? appOpenBlockReason(DateTime now) {
    return policy.appOpenBlockReason(_state, now);
  }

  /// Called only after the SDK confirmed that the Interstitial was presented.
  Future<void> recordInterstitial(DateTime now) async {
    _state = policy.recordInterstitial(_state, now);
    AdDiagnostics.log(
      'interstitial recorded',
      'dayCount=${_state.interstitialCount}',
    );
    await _persist();
  }

  /// Called only after the SDK confirmed that the App Open ad was presented.
  Future<void> recordAppOpen(DateTime now) async {
    _state = policy.recordAppOpen(_state, now);
    AdDiagnostics.log('app open recorded');
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await store.save(_state);
    } catch (error) {
      AdDiagnostics.log('frequency save failed', error);
    }
  }
}
