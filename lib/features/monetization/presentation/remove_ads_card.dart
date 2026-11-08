import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/presentation/theme/app_theme.dart';
import '../../../src/presentation/utils/localization.dart';
import '../application/monetization_controller.dart';
import '../domain/monetization_models.dart';
import 'monetization_scope.dart';

/// Settings entry for the one-time lifetime Remove Ads purchase.
///
/// Price comes from the store, never hardcoded. No subscription language is
/// used, and success is only shown after the store confirms the transaction.
class RemoveAdsCard extends StatelessWidget {
  const RemoveAdsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = MonetizationScope.maybeOf(context);
    if (controller == null || !controller.shouldOfferRemoveAds) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Padding(
        key: const Key('settings-remove-ads'),
        padding: const EdgeInsets.only(top: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F1938), Color(0xFF18244C), Color(0xFF0B1229)],
            ),
            border: Border.all(color: const Color(0x3DFFC94D)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
              BoxShadow(
                color: Color(0x1AFFC94D),
                blurRadius: 18,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                const Positioned(
                  top: -70,
                  right: -50,
                  child: _Glow(color: Color(0x33A78BFA), size: 180),
                ),
                const Positioned(
                  bottom: -80,
                  left: -60,
                  child: _Glow(color: Color(0x26FFC94D), size: 190),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: controller.isAdFree
                      ? _OwnedContent(controller: controller)
                      : _PurchaseContent(controller: controller),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFE7CC8A)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE7CC8A),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.icon, this.owned = false});

  final String text;
  final IconData icon;
  final bool owned;

  @override
  Widget build(BuildContext context) {
    final accent = owned ? const Color(0xFF7DE2B8) : const Color(0xFFFFC94D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.22),
            const Color(0xFFA78BFA).withValues(alpha: 0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              color: accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnedContent extends StatelessWidget {
  const _OwnedContent({required this.controller});

  final MonetizationController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Badge(
          text: l10n.premiumOwnedBadge,
          icon: Icons.workspace_premium_rounded,
          owned: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF7DE2B8), Color(0xFF36B37E)],
                ),
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: Color(0xFF062B1E),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                l10n.premiumOwnedTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.premiumOwnedDescription,
          key: const Key('settings-remove-ads-owned'),
          style: const TextStyle(
            color: Color(0xFFC7D1EC),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const Key('settings-remove-ads-restore'),
            onPressed: controller.removeAdsPhase == RemoveAdsPhase.restoring
                ? null
                : () => unawaited(controller.restoreRemoveAds()),
            child: Text(l10n.removeAdsRestore),
          ),
        ),
      ],
    );
  }
}

class _PurchaseContent extends StatelessWidget {
  const _PurchaseContent({required this.controller});

  final MonetizationController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = _statusText(l10n, controller);
    final busy =
        controller.removeAdsPhase == RemoveAdsPhase.purchasing ||
        controller.removeAdsPhase == RemoveAdsPhase.pending ||
        controller.removeAdsPhase == RemoveAdsPhase.restoring;
    final hasProduct = controller.removeAdsPrice != null;
    final canRetry =
        controller.canRetryRemoveAdsStore &&
        controller.removeAdsPhase != RemoveAdsPhase.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Badge(
              text: l10n.premiumBadgeUpgrade,
              icon: Icons.auto_awesome_rounded,
            ),
            const Spacer(),
            const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFC94D),
              size: 22,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.premiumTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.premiumDescription,
          style: const TextStyle(
            color: Color(0xFFC7D1EC),
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.premiumBenefitsTitle,
          style: const TextStyle(
            color: Color(0xFFFFD98A),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        _Benefits(l10n: l10n),
        const SizedBox(height: 18),
        Container(
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x00FFC94D), Color(0x66FFC94D), Color(0x00A78BFA)],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ValueChip(
              icon: Icons.payments_outlined,
              label: l10n.premiumOneTimePayment,
            ),
            _ValueChip(
              icon: Icons.all_inclusive_rounded,
              label: l10n.premiumLifetimeAccess,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _PriceBlock(controller: controller, l10n: l10n),
        if (status != null) ...[
          const SizedBox(height: 10),
          Text(
            status,
            key: const Key('settings-remove-ads-status'),
            style: const TextStyle(
              color: Color(0xFFAEB9D6),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (hasProduct) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              key: const Key('settings-remove-ads-buy'),
              onPressed: controller.canPurchaseRemoveAds && !busy
                  ? () => unawaited(controller.purchaseRemoveAds())
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFC94D),
                foregroundColor: const Color(0xFF201A05),
                disabledBackgroundColor: const Color(0x4DFFC94D),
                disabledForegroundColor: const Color(0x991F1A05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Color(0xFF201A05),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 18),
                        const SizedBox(width: 8),
                        Flexible(child: Text(l10n.premiumCta)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              l10n.premiumOneTimeNote,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF93A0BF), fontSize: 11.5),
            ),
          ),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            if (canRetry)
              TextButton(
                key: const Key('settings-remove-ads-retry'),
                onPressed: () => unawaited(controller.retryRemoveAdsStore()),
                child: Text(l10n.removeAdsRetry),
              ),
            if (!busy)
              TextButton(
                key: const Key('settings-remove-ads-restore'),
                onPressed: () => unawaited(controller.restoreRemoveAds()),
                child: Text(l10n.removeAdsRestore),
              ),
          ],
        ),
      ],
    );
  }

  String? _statusText(
    AppLocalizations l10n,
    MonetizationController controller,
  ) {
    switch (controller.removeAdsPhase) {
      case RemoveAdsPhase.loading:
        return l10n.removeAdsLoading;
      case RemoveAdsPhase.purchasing:
        return l10n.removeAdsPurchasing;
      case RemoveAdsPhase.pending:
        return l10n.removeAdsPending;
      case RemoveAdsPhase.restoring:
        return l10n.removeAdsRestoring;
      case RemoveAdsPhase.unavailable:
        return controller.removeAdsNotice == RemoveAdsNotice.productNotFound
            ? l10n.removeAdsProductNotFound
            : l10n.removeAdsUnavailable;
      case RemoveAdsPhase.failed:
        return switch (controller.removeAdsNotice) {
          RemoveAdsNotice.restoreFailed => l10n.removeAdsRestoreFailed,
          RemoveAdsNotice.noPurchaseFound => l10n.removeAdsNoPurchase,
          RemoveAdsNotice.storeUnavailable => l10n.removeAdsUnavailable,
          RemoveAdsNotice.productNotFound => l10n.removeAdsProductNotFound,
          RemoveAdsNotice.purchaseFailed ||
          RemoveAdsNotice.none => l10n.removeAdsPurchaseFailed,
        };
      case RemoveAdsPhase.ready:
      case RemoveAdsPhase.purchased:
        return switch (controller.removeAdsNotice) {
          RemoveAdsNotice.noPurchaseFound => l10n.removeAdsNoPurchase,
          RemoveAdsNotice.storeUnavailable => l10n.removeAdsUnavailable,
          RemoveAdsNotice.productNotFound => l10n.removeAdsProductNotFound,
          RemoveAdsNotice.purchaseFailed => l10n.removeAdsPurchaseFailed,
          RemoveAdsNotice.restoreFailed => l10n.removeAdsRestoreFailed,
          RemoveAdsNotice.none => null,
        };
    }
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final items = [
      l10n.premiumBenefitNoBanners,
      l10n.premiumBenefitNoNative,
      l10n.premiumBenefitNoInterstitials,
      l10n.premiumBenefitNoAppOpen,
      l10n.premiumBenefitUninterrupted,
      l10n.premiumBenefitLifetime,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 400;
        final width = twoColumns
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 14,
          runSpacing: 10,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: Color(0xFFFFC94D),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Color(0xFFE6EBFB),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.controller, required this.l10n});

  final MonetizationController controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final price = controller.removeAdsPrice;
    final loading = controller.removeAdsPhase == RemoveAdsPhase.loading;
    final available = price != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.premiumStorePriceLabel,
          style: const TextStyle(
            color: Color(0xFF93A0BF),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 3),
        // Never invent a price. Until the store responds, say so.
        Text(
          available
              ? price
              : loading
              ? l10n.removeAdsLoading
              : l10n.removeAdsUnavailable,
          key: const Key('settings-remove-ads-price'),
          style: TextStyle(
            color: available
                ? const Color(0xFFFFD98A)
                : const Color(0xFFAEB9D6),
            fontSize: available ? 24 : 12.5,
            fontWeight: available ? FontWeight.w800 : FontWeight.w400,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

/// Read-only summary of advertising and purchase availability for Settings.
/// It shows user-facing states only and never exposes unit IDs or store codes.
class MonetizationStatusCard extends StatelessWidget {
  const MonetizationStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = MonetizationScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final l10n = context.l10n;
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Material(
            key: const Key('settings-monetization-status'),
            color: AppColors.surface.withValues(alpha: 0.78),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0x14FFFFFF)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.monetizationStatusTitle,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatusRow(
                    label: l10n.adsStatusLabel,
                    value: _adsStatus(l10n, controller),
                    valueKey: const Key('settings-ads-status'),
                  ),
                  _StatusRow(
                    label: l10n.removeAdsStatusLabel,
                    value: _removeAdsStatus(l10n, controller),
                    valueKey: const Key('settings-remove-ads-state'),
                  ),
                  _StatusRow(
                    label: l10n.purchaseStatusLabel,
                    value: _purchaseStatus(l10n, controller),
                    valueKey: const Key('settings-purchase-status'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _adsStatus(AppLocalizations l10n, MonetizationController controller) {
    return switch (controller.adsStatus) {
      AdsStatus.available => l10n.adsStatusAvailable,
      AdsStatus.disabled => l10n.adsStatusDisabled,
      AdsStatus.waitingForConsent => l10n.adsStatusWaitingConsent,
      AdsStatus.configurationMissing => l10n.adsStatusConfigurationMissing,
      AdsStatus.starting => l10n.adsStatusStarting,
    };
  }

  String _removeAdsStatus(
    AppLocalizations l10n,
    MonetizationController controller,
  ) {
    if (controller.isAdFree) return l10n.removeAdsStatusOwned;
    if (!controller.isStoreSupported ||
        controller.removeAdsPhase == RemoveAdsPhase.unavailable) {
      return l10n.removeAdsStatusStoreUnavailable;
    }
    return l10n.removeAdsStatusNotPurchased;
  }

  String _purchaseStatus(
    AppLocalizations l10n,
    MonetizationController controller,
  ) {
    final phase = controller.removeAdsPhase;
    if (phase == RemoveAdsPhase.purchasing ||
        phase == RemoveAdsPhase.pending ||
        phase == RemoveAdsPhase.restoring) {
      return l10n.purchaseStatusPending;
    }
    if (phase == RemoveAdsPhase.failed ||
        controller.removeAdsNotice == RemoveAdsNotice.purchaseFailed ||
        controller.removeAdsNotice == RemoveAdsNotice.restoreFailed) {
      return l10n.purchaseStatusFailed;
    }
    if (controller.canPurchaseRemoveAds) return l10n.purchaseStatusAvailable;
    return l10n.purchaseStatusUnavailable;
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            key: valueKey,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kept out of the purchase card so the About area can offer UMP privacy
/// options without crowding the entitlement UI.
class PrivacyOptionsTile extends StatelessWidget {
  const PrivacyOptionsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = MonetizationScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.privacyOptionsRequired) {
          return const SizedBox.shrink();
        }
        final l10n = context.l10n;
        return ListTile(
          key: const Key('settings-privacy-options'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.privacy_tip_outlined,
            color: AppColors.accent,
          ),
          title: Text(l10n.privacyOptions),
          subtitle: Text(l10n.privacyOptionsBody),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => unawaited(controller.showPrivacyOptions()),
        );
      },
    );
  }
}
