import 'package:flutter/foundation.dart';

import '../domain/ad_models.dart';

/// Debug-only diagnostics for advertising.
///
/// Logs are compiled out of release behavior (`debugPrint` is a no-op there)
/// and never include full ad unit IDs, prices, or purchase tokens.
abstract final class AdDiagnostics {
  static const String _prefix = '[Monetization]';

  static bool get enabled => kDebugMode;

  static void log(String event, [Object? detail]) {
    if (!enabled) return;
    final suffix = detail == null ? '' : ': $detail';
    debugPrint('$_prefix $event$suffix');
  }

  /// Widget rebuilds can call eligibility many times per second, so repeated
  /// rejection reasons are throttled instead of flooding the console.
  static final Map<String, DateTime> _recentRejections = {};

  static void eligibility(AdPlacement placement, AdEligibility eligibility) {
    if (!enabled || eligibility.isAllowed) return;
    final key = '${placement.name}/${eligibility.reason?.name}';
    final now = DateTime.now();
    final last = _recentRejections[key];
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      return;
    }
    _recentRejections[key] = now;
    log(
      'eligibility rejected',
      '${placement.name} -> ${eligibility.reason?.name ?? 'unknown'}',
    );
  }

  /// Reports whether a unit is configured without revealing the ID value.
  static String unitStatus(String format, String? unitId) =>
      '$format=${unitId == null ? 'missing' : 'configured'}';

  static String errorSummary(Object error) => error.toString();
}
