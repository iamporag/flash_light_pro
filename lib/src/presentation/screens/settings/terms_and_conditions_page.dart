import 'package:flash_light_pro/features/monetization/domain/ad_models.dart';
import 'package:flash_light_pro/features/monetization/presentation/monetization_banner.dart';
import 'package:flash_light_pro/src/presentation/screens/settings/policy_section.dart';
import 'package:flash_light_pro/src/presentation/theme/app_theme.dart';
import 'package:flash_light_pro/src/presentation/utils/localization.dart';
import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.termsAndConditions),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('terms-scroll'),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const SizedBox(height: 8),
            Text(
              l10n.termsEffectiveDate,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.termsIntro,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 22),
            PolicySection(
              icon: Icons.verified_user_outlined,
              title: l10n.termsLicenceTitle,
              body: l10n.termsLicenceBody,
            ),
            PolicySection(
              icon: Icons.campaign_outlined,
              title: l10n.termsAdsTitle,
              body: l10n.termsAdsBody,
            ),
            PolicySection(
              icon: Icons.warning_amber_rounded,
              title: l10n.termsSafetyTitle,
              body: l10n.termsSafetyBody,
            ),
            PolicySection(
              icon: Icons.block_outlined,
              title: l10n.termsUseTitle,
              body: l10n.termsUseBody,
            ),
            PolicySection(
              icon: Icons.security_rounded,
              title: l10n.termsPermissionsTitle,
              body: l10n.termsPermissionsBody,
            ),
            PolicySection(
              icon: Icons.system_update_rounded,
              title: l10n.termsUpdatesTitle,
              body: l10n.termsUpdatesBody,
            ),
            PolicySection(
              icon: Icons.copyright_rounded,
              title: l10n.termsIpTitle,
              body: l10n.termsIpBody,
            ),
            PolicySection(
              icon: Icons.hub_outlined,
              title: l10n.termsThirdPartyTitle,
              body: l10n.termsThirdPartyBody,
            ),
            PolicySection(
              icon: Icons.gavel_rounded,
              title: l10n.termsLiabilityTitle,
              body: l10n.termsLiabilityBody,
            ),
            PolicySection(
              icon: Icons.handshake_outlined,
              title: l10n.termsIndemnityTitle,
              body: l10n.termsIndemnityBody,
            ),
            PolicySection(
              icon: Icons.balance_rounded,
              title: l10n.termsLawTitle,
              body: l10n.termsLawBody,
            ),
            PolicySection(
              icon: Icons.mail_outline_rounded,
              title: l10n.termsChangesTitle,
              body: l10n.termsChangesBody,
            ),
            const MonetizationBanner(
              placement: AdPlacement.privacyPolicyBanner,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.termsFooter,
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
