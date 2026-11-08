import 'package:flutter/foundation.dart';

import '../data/consent_gateway.dart';
import 'ad_diagnostics.dart';

enum ConsentPhase { idle, preparing, formShowing, ready, denied, failed }

/// Owns the UMP consent decision. Ads may only be requested when
/// [canRequestAds] is true; every failure path leaves it false.
class ConsentManager extends ChangeNotifier {
  ConsentManager({required this.gateway});

  final ConsentGateway gateway;

  static const Duration _failedRetryCooldown = Duration(seconds: 15);

  ConsentPhase _phase = ConsentPhase.idle;
  ConsentInfo _info = const ConsentInfo.denied();
  bool _initializing = false;
  bool _disposed = false;
  DateTime? _lastAttemptAt;

  ConsentPhase get phase => _phase;
  bool get canRequestAds => _info.canRequestAds;
  bool get privacyOptionsRequired => _info.privacyOptionsRequired;

  /// Called on every ad-start attempt. It requests UMP info only when no
  /// decision exists yet, never re-prompts after an explicit denial, and
  /// retries a transient failure after a short cooldown.
  Future<void> ensureConsent() async {
    switch (_phase) {
      case ConsentPhase.ready:
        return;
      case ConsentPhase.preparing:
      case ConsentPhase.formShowing:
        return;
      case ConsentPhase.denied:
        await _refreshOnly();
      case ConsentPhase.idle:
      case ConsentPhase.failed:
        await initialize();
    }
  }

  Future<void> initialize() async {
    if (_initializing || _phase == ConsentPhase.ready) return;

    final now = DateTime.now();
    final lastAttempt = _lastAttemptAt;
    if (_phase == ConsentPhase.failed &&
        lastAttempt != null &&
        now.difference(lastAttempt) < _failedRetryCooldown) {
      return;
    }
    _lastAttemptAt = now;
    _initializing = true;
    _setPhase(ConsentPhase.preparing);
    AdDiagnostics.log('consent request started');

    try {
      var info = await gateway.requestConsentInfo();
      _logInfo('consent info', info);

      if (info.formAvailable) {
        _setPhase(ConsentPhase.formShowing);
        AdDiagnostics.log('consent form showing');
        await gateway.showFormIfRequired();
        info = await gateway.refresh();
        _logInfo('consent after form', info);
      }

      _info = info;
      _setPhase(info.canRequestAds ? ConsentPhase.ready : ConsentPhase.denied);
    } catch (error) {
      AdDiagnostics.log('consent request failed', error);
      _info = const ConsentInfo.denied();
      _setPhase(ConsentPhase.failed);
    } finally {
      _initializing = false;
    }
  }

  Future<void> showPrivacyOptions() async {
    AdDiagnostics.log('privacy options opening');
    try {
      await gateway.showPrivacyOptions();
      _info = await gateway.refresh();
      _phase = _info.canRequestAds ? ConsentPhase.ready : ConsentPhase.denied;
      _logInfo('privacy options closed', _info);
    } catch (error) {
      AdDiagnostics.log('privacy options failed', error);
      // Keep the previous consent result; the privacy options entry point is
      // always safe to tap again.
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> _refreshOnly() async {
    try {
      _info = await gateway.refresh();
      _phase = _info.canRequestAds ? ConsentPhase.ready : ConsentPhase.denied;
      _logInfo('consent refreshed', _info);
    } catch (error) {
      AdDiagnostics.log('consent refresh failed', error);
    }
    if (!_disposed) notifyListeners();
  }

  void _logInfo(String event, ConsentInfo info) {
    AdDiagnostics.log(
      event,
      'canRequestAds=${info.canRequestAds}, '
      'formAvailable=${info.formAvailable}, '
      'privacyOptionsRequired=${info.privacyOptionsRequired}',
    );
  }

  void _setPhase(ConsentPhase phase) {
    _phase = phase;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    gateway.dispose();
    super.dispose();
  }
}
