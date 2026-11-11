import 'dart:async';

import 'package:flash_light_pro/core/config/app_info.dart';
import 'package:flash_light_pro/features/monetization/domain/ad_models.dart';
import 'package:flash_light_pro/features/monetization/presentation/monetization_banner.dart';
import 'package:flash_light_pro/src/presentation/screens/settings/policy_section.dart';
import 'package:flash_light_pro/core/config/app_theme_config.dart';
import 'package:flash_light_pro/src/presentation/utils/localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _openOnlinePolicy() async {
  try {
    await launchUrl(
      Uri.parse(AppInfo.privacyPolicyUrl),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    // The same policy is already shown on this screen.
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicyTitle),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const SizedBox(height: 8),
            Text(
              l10n.privacyIntro,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('privacy-policy-online'),
                onPressed: () => unawaited(_openOnlinePolicy()),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  textStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(l10n.privacyViewOnline),
              ),
            ),
            const SizedBox(height: 14),
            PolicySection(
              icon: Icons.phone_android_rounded,
              title: l10n.privacyLocalTitle,
              body: l10n.privacyLocalBody,
            ),
            PolicySection(
              icon: Icons.sensors_rounded,
              title: l10n.privacyHardwareTitle,
              body: l10n.privacyHardwareBody,
            ),
            PolicySection(
              icon: Icons.campaign_outlined,
              title: l10n.privacyAdsTitle,
              body: l10n.privacyAdsBody,
            ),
            PolicySection(
              icon: Icons.receipt_long_rounded,
              title: l10n.privacyBillingTitle,
              body: l10n.privacyBillingBody,
            ),
            PolicySection(
              icon: Icons.shield_outlined,
              title: l10n.privacyNoAnalyticsTitle,
              body: l10n.privacyNoAnalyticsBody,
            ),
            const MonetizationBanner(
              placement: AdPlacement.privacyPolicyBanner,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.privacyPolicyFooter(AppInfo.version),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
