import 'dart:async';

import 'package:flash_light_pro/core/config/app_theme_config.dart';
import 'package:flash_light_pro/src/presentation/utils/localization.dart';
import 'package:flutter/material.dart';

import 'monetization_scope.dart';

/// UMP privacy-options entry for the About area.
///
/// Kept separate from ad and purchase UI so consent controls remain available
/// even when those surfaces are hidden.
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
