import 'package:shared_preferences/shared_preferences.dart';

import '../domain/update_models.dart';

abstract interface class UpdatePolicyStore {
  Future<TrustedUpdatePolicy?> loadTrustedPolicy();

  Future<void> saveTrustedPolicy(TrustedUpdatePolicy policy);

  Future<void> clearTrustedPolicy();

  Future<int?> loadDismissedVersionCode();

  Future<void> saveDismissedVersionCode(int versionCode);

  Future<DateTime?> loadLastCheckAt();

  Future<void> saveLastCheckAt(DateTime at);
}

class SharedPreferencesUpdatePolicyStore implements UpdatePolicyStore {
  const SharedPreferencesUpdatePolicyStore();

  static const String _urgencyKey = 'updates.policy.urgency';
  static const String _versionCodeKey = 'updates.policy.version_code';
  static const String _priorityKey = 'updates.policy.priority';
  static const String _verifiedAtKey = 'updates.policy.verified_at';
  static const String _dismissedVersionKey = 'updates.dismissed_version_code';
  static const String _lastCheckKey = 'updates.last_check_at';

  @override
  Future<TrustedUpdatePolicy?> loadTrustedPolicy() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final urgencyName = preferences.getString(_urgencyKey);
      final verifiedAtMs = preferences.getInt(_verifiedAtKey);
      if (urgencyName == null || verifiedAtMs == null) return null;

      UpdateUrgency? urgency;
      for (final value in UpdateUrgency.values) {
        if (value.name == urgencyName) {
          urgency = value;
          break;
        }
      }
      if (urgency == null || urgency == UpdateUrgency.none) return null;

      return TrustedUpdatePolicy(
        urgency: urgency,
        verifiedAt: DateTime.fromMillisecondsSinceEpoch(verifiedAtMs),
        availableVersionCode: preferences.getInt(_versionCodeKey),
        updatePriority: preferences.getInt(_priorityKey) ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveTrustedPolicy(TrustedUpdatePolicy policy) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_urgencyKey, policy.urgency.name);
      await preferences.setInt(
        _verifiedAtKey,
        policy.verifiedAt.millisecondsSinceEpoch,
      );
      await preferences.setInt(_priorityKey, policy.updatePriority);

      final code = policy.availableVersionCode;
      if (code == null) {
        await preferences.remove(_versionCodeKey);
      } else {
        await preferences.setInt(_versionCodeKey, code);
      }
    } catch (_) {
      // Cache failures must never affect update checks.
    }
  }

  @override
  Future<void> clearTrustedPolicy() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_urgencyKey);
      await preferences.remove(_versionCodeKey);
      await preferences.remove(_priorityKey);
      await preferences.remove(_verifiedAtKey);
    } catch (_) {
      // Cache failures must never affect update checks.
    }
  }

  @override
  Future<int?> loadDismissedVersionCode() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getInt(_dismissedVersionKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDismissedVersionCode(int versionCode) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt(_dismissedVersionKey, versionCode);
    } catch (_) {
      // Dismissal is best effort; a repeat prompt is preferable to a crash.
    }
  }

  @override
  Future<DateTime?> loadLastCheckAt() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final value = preferences.getInt(_lastCheckKey);
      return value == null ? null : DateTime.fromMillisecondsSinceEpoch(value);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveLastCheckAt(DateTime at) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt(_lastCheckKey, at.millisecondsSinceEpoch);
    } catch (_) {
      // A missing throttle timestamp only means one extra check.
    }
  }
}
