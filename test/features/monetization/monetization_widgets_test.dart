import 'package:flash_light_pro/features/monetization/domain/ad_config.dart';
import 'package:flash_light_pro/features/monetization/domain/ad_models.dart';
import 'package:flash_light_pro/features/monetization/domain/monetization_models.dart';
import 'package:flash_light_pro/features/monetization/presentation/monetization_banner.dart';
import 'package:flash_light_pro/features/monetization/presentation/monetization_native_ad.dart';
import 'package:flash_light_pro/features/monetization/presentation/monetization_scope.dart';
import 'package:flash_light_pro/features/monetization/presentation/remove_ads_card.dart';
import 'package:flash_light_pro/features/monetization/data/consent_gateway.dart';
import 'package:flash_light_pro/features/monetization/application/monetization_controller.dart';
import 'package:flash_light_pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'fakes.dart';

Widget app(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

Widget scoped(MonetizationController controller, Widget child) {
  return app(MonetizationScope(controller: controller, child: child));
}

void main() {
  group('ad widgets', () {
    testWidgets('a banner renders nothing without a monetization scope', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const MonetizationBanner(placement: AdPlacement.privacyPolicyBanner),
        ),
      );

      expect(find.byType(AdWidget), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a banner renders nothing before the SDK is ready', (
      tester,
    ) async {
      final controller = buildTestController();
      await tester.pumpWidget(
        scoped(
          controller,
          const MonetizationBanner(placement: AdPlacement.privacyPolicyBanner),
        ),
      );

      expect(find.byType(AdWidget), findsNothing);
      expect(tester.takeException(), isNull);
      controller.dispose();
    });

    testWidgets('a banner is suppressed while a light is active', (
      tester,
    ) async {
      final context = MutableAdContext(lightActive: true);
      final controller = buildTestController(context: context);
      await controller.startAds();

      await tester.pumpWidget(
        scoped(
          controller,
          const MonetizationBanner(placement: AdPlacement.privacyPolicyBanner),
        ),
      );
      await tester.pump();

      expect(find.byType(AdWidget), findsNothing);
      controller.dispose();
    });

    testWidgets('a native ad renders nothing without a scope', (tester) async {
      await tester.pumpWidget(
        app(const MonetizationNativeAd(placement: AdPlacement.settingsNative)),
      );

      expect(find.byType(AdWidget), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the native ad is suppressed while an update is mandatory', (
      tester,
    ) async {
      final controller = buildTestController(
        context: MutableAdContext(mandatoryUpdateActive: true),
      );
      await controller.startAds();

      await tester.pumpWidget(
        scoped(
          controller,
          const MonetizationNativeAd(placement: AdPlacement.settingsNative),
        ),
      );
      await tester.pump();

      expect(find.byType(AdWidget), findsNothing);
      controller.dispose();
    });
  });

  group('remove ads card', () {
    testWidgets('shows the localized store price and a buy action', (
      tester,
    ) async {
      final billing = FakeBillingGateway();
      final controller = buildTestController(billingGateway: billing);
      await controller.initialize();
      addTearDown(controller.dispose);

      await tester.pumpWidget(scoped(controller, const RemoveAdsCard()));

      expect(find.byKey(const Key('settings-remove-ads')), findsOneWidget);
      expect(
        find.byKey(const Key('settings-remove-ads-price')),
        findsOneWidget,
      );
      expect(find.text(r'US$4.99'), findsOneWidget);
      expect(find.byKey(const Key('settings-remove-ads-buy')), findsOneWidget);
      expect(
        find.byKey(const Key('settings-remove-ads-restore')),
        findsOneWidget,
      );
      expect(find.text('SPECIAL UPGRADE'), findsOneWidget);
      expect(find.text('Go Ad-Free'), findsOneWidget);
      expect(find.text('Remove Ads Forever'), findsOneWidget);
      expect(find.text('ONE-TIME PAYMENT'), findsOneWidget);
      expect(find.text('LIFETIME ACCESS'), findsOneWidget);
      expect(
        find.text('One-time purchase. No recurring charges.'),
        findsOneWidget,
      );
    });

    testWidgets('shows an honest loading state before the store responds', (
      tester,
    ) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(scoped(controller, const RemoveAdsCard()));

      expect(
        tester
            .widget<Text>(find.byKey(const Key('settings-remove-ads-price')))
            .data,
        'Loading store price...',
      );
      expect(find.byKey(const Key('settings-remove-ads-buy')), findsNothing);
      expect(find.byKey(const Key('settings-remove-ads-retry')), findsNothing);
    });

    testWidgets('a tap buys the non-consumable product', (tester) async {
      final billing = FakeBillingGateway();
      final controller = buildTestController(billingGateway: billing);
      await controller.initialize();
      addTearDown(controller.dispose);

      await tester.pumpWidget(scoped(controller, const RemoveAdsCard()));
      await tester.tap(find.byKey(const Key('settings-remove-ads-buy')));
      await tester.pump();

      expect(billing.bought, ['flash_light_pro_remove_ads']);
      expect(find.text('Waiting for the store to confirm...'), findsOneWidget);
    });

    testWidgets('a confirmed purchase shows the owned state', (tester) async {
      final billing = FakeBillingGateway();
      final controller = buildTestController(billingGateway: billing);
      await controller.initialize();
      addTearDown(controller.dispose);

      await tester.pumpWidget(scoped(controller, const RemoveAdsCard()));
      billing.emit(status: BillingPurchaseStatus.purchased);
      await tester.pump();

      expect(
        find.byKey(const Key('settings-remove-ads-owned')),
        findsOneWidget,
      );
      expect(find.text("You're Ad-Free!"), findsOneWidget);
      expect(find.text('LIFETIME UNLOCKED'), findsOneWidget);
      expect(find.byKey(const Key('settings-remove-ads-buy')), findsNothing);
      expect(
        find.byKey(const Key('settings-remove-ads-restore')),
        findsOneWidget,
      );
    });

    testWidgets('a cached entitlement starts in the owned state', (
      tester,
    ) async {
      final controller = buildTestController(
        adFreeStore: FakeAdFreeStore(owned: true),
      );
      await controller.initialize();
      addTearDown(controller.dispose);

      await tester.pumpWidget(scoped(controller, const RemoveAdsCard()));

      expect(
        find.byKey(const Key('settings-remove-ads-owned')),
        findsOneWidget,
      );
    });

    testWidgets('an unavailable store offers retry and honest copy', (
      tester,
    ) async {
      final controller = buildTestController(
        billingGateway: FakeBillingGateway(product: null),
      );
      await controller.initialize();
      addTearDown(controller.dispose);

      await tester.pumpWidget(scoped(controller, const RemoveAdsCard()));

      expect(
        find.byKey(const Key('settings-remove-ads-retry')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('settings-remove-ads-buy')), findsNothing);
      expect(
        find.text('The store does not list the Remove Ads product yet.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('settings-remove-ads-price')))
            .data,
        'The store is unavailable right now. Every flashlight feature still works.',
      );
    });

    testWidgets('nothing is shown when monetization has no ad unit ids', (
      tester,
    ) async {
      final controller = buildTestController(
        config: const AdConfig(
          testMode: false,
          androidUnitIds: {},
          iosUnitIds: {},
        ),
      );
      await controller.initialize();
      addTearDown(controller.dispose);

      await tester.pumpWidget(scoped(controller, const RemoveAdsCard()));

      expect(find.byKey(const Key('settings-remove-ads')), findsNothing);
    });

    testWidgets('the card never claims a subscription', (tester) async {
      final controller = buildTestController();
      await controller.initialize();
      addTearDown(controller.dispose);

      await tester.pumpWidget(scoped(controller, const RemoveAdsCard()));

      expect(find.textContaining('subscri', findRichText: true), findsNothing);
    });

    testWidgets('fits a narrow screen in light and dark themes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        final controller = buildTestController();
        await controller.initialize();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: mode,
            home: Scaffold(
              body: SingleChildScrollView(
                child: MonetizationScope(
                  controller: controller,
                  child: const RemoveAdsCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Go Ad-Free'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('privacy options', () {
    testWidgets('is hidden when consent does not require it', (tester) async {
      final controller = buildTestController();
      await controller.initialize();
      addTearDown(controller.dispose);

      await tester.pumpWidget(scoped(controller, const PrivacyOptionsTile()));

      expect(find.byKey(const Key('settings-privacy-options')), findsNothing);
    });

    testWidgets('opens the UMP privacy options form when required', (
      tester,
    ) async {
      final gateway = FakeConsentGateway(
        info: const ConsentInfo(
          canRequestAds: true,
          formAvailable: false,
          privacyOptionsRequired: true,
        ),
      );
      final controller = buildTestController(consentGateway: gateway);
      await controller.startAds();
      addTearDown(controller.dispose);

      await tester.pumpWidget(scoped(controller, const PrivacyOptionsTile()));
      await tester.tap(find.byKey(const Key('settings-privacy-options')));
      await tester.pump();

      expect(gateway.privacyOptionsShown, 1);
    });

    testWidgets('is hidden without a monetization scope', (tester) async {
      await tester.pumpWidget(app(const PrivacyOptionsTile()));

      expect(find.byKey(const Key('settings-privacy-options')), findsNothing);
    });
  });
}
