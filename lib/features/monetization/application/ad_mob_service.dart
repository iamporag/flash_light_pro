import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../domain/ad_config.dart';
import '../domain/ad_models.dart';
import 'ad_diagnostics.dart';

/// Minimal boundary around SDK initialization so the controller can be tested
/// without the Google Mobile Ads platform channel.
abstract class AdInitializer {
  bool get isInitialized;

  Future<bool> initialize();
}

class AdMobService implements AdInitializer {
  AdMobService({required this.config});

  final AdConfig config;

  bool _initialized = false;
  Future<bool>? _pending;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<bool> initialize() {
    if (_initialized) return Future<bool>.value(true);
    return _pending ??= _initialize();
  }

  Future<bool> _initialize() async {
    AdDiagnostics.log(
      'ad SDK initializing',
      'testMode=${config.testMode}, '
          'testDevices=${config.testDeviceIds.length}',
    );
    try {
      if (config.testDeviceIds.isNotEmpty) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: config.testDeviceIds),
        );
      }
      await MobileAds.instance.initialize();
      _initialized = true;
      AdDiagnostics.log(
        'ad SDK initialized',
        'android=${_summary(config.androidUnitIds)}, '
            'ios=${_summary(config.iosUnitIds)}',
      );
      return true;
    } catch (error) {
      // Advertising is optional. A failed SDK initialization must never affect
      // flashlight behavior or the update flow.
      AdDiagnostics.log('ad SDK initialization failed', error);
      _initialized = false;
      return false;
    } finally {
      _pending = null;
    }
  }

  static String _summary(Map<AdFormat, String> ids) {
    return ids.entries
        .map((entry) => '${entry.key.name}:${entry.value.isEmpty ? '-' : 'ok'}')
        .join(',');
  }
}
