import 'package:flash_light_pro/features/monetization/domain/ad_models.dart';
import 'package:flash_light_pro/features/monetization/presentation/monetization_banner.dart';
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
            _PolicySection(
              icon: Icons.phone_android_rounded,
              title: l10n.privacyLocalTitle,
              body: l10n.privacyLocalBody,
            ),
            _PolicySection(
              icon: Icons.sensors_rounded,
              title: l10n.privacyHardwareTitle,
              body: l10n.privacyHardwareBody,
            ),
            _PolicySection(
              icon: Icons.campaign_outlined,
              title: l10n.privacyAdsTitle,
              body: l10n.privacyAdsBody,
            ),
            _PolicySection(
              icon: Icons.receipt_long_rounded,
              title: l10n.privacyBillingTitle,
              body: l10n.privacyBillingBody,
            ),
            _PolicySection(
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

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
