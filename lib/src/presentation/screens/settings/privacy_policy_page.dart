import 'package:flash_light_pro/features/monetization/domain/ad_models.dart';
import 'package:flash_light_pro/features/monetization/presentation/monetization_banner.dart';
import 'package:flash_light_pro/src/presentation/screens/settings/policy_section.dart';
import 'package:flash_light_pro/src/presentation/theme/app_theme.dart';
import 'package:flash_light_pro/src/presentation/utils/localization.dart';
import 'package:flutter/material.dart';

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
            const SizedBox(height: 22),
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
              l10n.privacyPolicyFooter,
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
