import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ad_frequency_policy.dart';

/// Persists interstitial/app-open frequency data and the very first session
/// flag. The first session flag is what makes "never on first launch" a hard
/// rule rather than an in-memory accident.
abstract class AdFrequencyStore {
  Future<AdFrequencyState> load();

  Future<void> save(AdFrequencyState state);

  /// Returns true exactly once in the lifetime of the install.
  Future<bool> registerSessionStart();
}

class SharedPreferencesAdFrequencyStore implements AdFrequencyStore {
  const SharedPreferencesAdFrequencyStore();

  static const String _lastInterstitialKey =
      'monetization.interstitial.last_at';
  static const String _interstitialCountKey =
      'monetization.interstitial.day_count';
  static const String _interstitialDayKey = 'monetization.interstitial.day';
  static const String _lastAppOpenKey = 'monetization.app_open.last_at';
  static const String _sessionStartedKey = 'monetization.session.started';

  @override
  Future<AdFrequencyState> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return AdFrequencyState(
        lastInterstitialAt: _readDate(prefs.getString(_lastInterstitialKey)),
        interstitialCount: prefs.getInt(_interstitialCountKey) ?? 0,
        interstitialDayKey: prefs.getString(_interstitialDayKey),
        lastAppOpenAt: _readDate(prefs.getString(_lastAppOpenKey)),
      );
    } catch (_) {
      return const AdFrequencyState();
    }
  }

  @override
  Future<void> save(AdFrequencyState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _lastInterstitialKey,
        state.lastInterstitialAt?.toIso8601String() ?? '',
      );
      await prefs.setInt(_interstitialCountKey, state.interstitialCount);
      await prefs.setString(
        _interstitialDayKey,
        state.interstitialDayKey ?? '',
      );
      await prefs.setString(
        _lastAppOpenKey,
        state.lastAppOpenAt?.toIso8601String() ?? '',
      );
    } catch (_) {
      // Frequency persistence is best-effort; the in-memory state still
      // enforces the limits for the current session.
    }
  }

  @override
  Future<bool> registerSessionStart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyStarted = prefs.getBool(_sessionStartedKey) ?? false;
      if (!alreadyStarted) {
        await prefs.setBool(_sessionStartedKey, true);
      }
      return !alreadyStarted;
    } catch (_) {
      // If the flag cannot be read, fail closed and treat this as a first
      // session so an app-open ad is never shown.
      return true;
    }
  }

  static DateTime? _readDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
