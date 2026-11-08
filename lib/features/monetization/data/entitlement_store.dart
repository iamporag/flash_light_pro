import 'package:shared_preferences/shared_preferences.dart';

/// Local cache of the lifetime Remove Ads entitlement.
///
/// This is deliberately a cache, not the source of truth: the billing gateway
/// reconciles with the store on startup (Android) or when the user restores
/// (iOS and Android).
abstract class AdFreeStore {
  Future<bool> loadOwned();

  Future<void> saveOwned(bool owned);
}

class SharedPreferencesAdFreeStore implements AdFreeStore {
  const SharedPreferencesAdFreeStore();

  static const String _ownedKey = 'monetization.remove_ads.owned';

  @override
  Future<bool> loadOwned() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_ownedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> saveOwned(bool owned) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_ownedKey, owned);
    } catch (_) {
      // The in-memory entitlement still applies for this session.
    }
  }
}
