import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../application/ad_diagnostics.dart';
import '../domain/ad_config.dart';

class ConsentInfo {
  const ConsentInfo({
    required this.canRequestAds,
    required this.formAvailable,
    required this.privacyOptionsRequired,
  });

  const ConsentInfo.denied()
    : canRequestAds = false,
      formAvailable = false,
      privacyOptionsRequired = false;

  final bool canRequestAds;
  final bool formAvailable;
  final bool privacyOptionsRequired;
}

class ConsentGatewayException implements Exception {
  ConsentGatewayException(this.message);

  final String message;

  @override
  String toString() => 'ConsentGatewayException: $message';
}

/// Thin abstraction over the Google User Messaging Platform so consent can be
/// exercised in tests without the platform channel.
abstract class ConsentGateway {
  Future<ConsentInfo> requestConsentInfo();

  Future<ConsentInfo> refresh();

  Future<void> showFormIfRequired();

  Future<void> showPrivacyOptions();

  void dispose();
}

class GoogleConsentGateway implements ConsentGateway {
  GoogleConsentGateway({required this.config});

  final AdConfig config;

  static const Duration _timeout = Duration(seconds: 15);

  @override
  Future<ConsentInfo> requestConsentInfo() async {
    final completer = Completer<void>();
    final params = ConsentRequestParameters(
      consentDebugSettings: config.testDeviceIds.isEmpty
          ? null
          : ConsentDebugSettings(
              debugGeography: DebugGeography.debugGeographyEea,
              testIdentifiers: config.testDeviceIds,
            ),
    );

    AdDiagnostics.log(
      'UMP requestConsentInfoUpdate',
      'debugGeography=${config.testDeviceIds.isEmpty ? 'none' : 'EEA'}',
    );
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        AdDiagnostics.log('UMP requestConsentInfoUpdate succeeded');
        if (!completer.isCompleted) completer.complete();
      },
      (error) {
        AdDiagnostics.log(
          'UMP requestConsentInfoUpdate failed',
          'code=${error.errorCode}, message=${error.message}',
        );
        if (!completer.isCompleted) {
          completer.completeError(ConsentGatewayException(error.message));
        }
      },
    );

    await completer.future.timeout(
      _timeout,
      onTimeout: () => throw ConsentGatewayException(
        'Consent information request timed out.',
      ),
    );
    return refresh();
  }

  @override
  Future<ConsentInfo> refresh() async {
    final canRequestAds = await ConsentInformation.instance.canRequestAds();
    final formAvailable = await ConsentInformation.instance
        .isConsentFormAvailable();
    final privacyStatus = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();

    AdDiagnostics.log(
      'UMP status',
      'canRequestAds=$canRequestAds, formAvailable=$formAvailable, '
          'privacyOptions=$privacyStatus',
    );
    return ConsentInfo(
      canRequestAds: canRequestAds,
      formAvailable: formAvailable,
      privacyOptionsRequired:
          privacyStatus == PrivacyOptionsRequirementStatus.required,
    );
  }

  @override
  Future<void> showFormIfRequired() async {
    AdDiagnostics.log('UMP consent form opening');
    await ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (error != null) {
        AdDiagnostics.log(
          'UMP consent form error',
          'code=${error.errorCode}, message=${error.message}',
        );
      }
    });
    AdDiagnostics.log('UMP consent form closed');
    await refresh();
  }

  @override
  Future<void> showPrivacyOptions() async {
    AdDiagnostics.log('UMP privacy options form opening');
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) {
        AdDiagnostics.log(
          'UMP privacy options error',
          'code=${error.errorCode}, message=${error.message}',
        );
      }
    });
    AdDiagnostics.log('UMP privacy options form closed');
  }

  @override
  void dispose() {}
}
