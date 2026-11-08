import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flash_light_pro/features/updates/application/update_cubit.dart';
import 'package:flash_light_pro/features/updates/domain/update_models.dart';
import 'package:flash_light_pro/l10n/app_localizations.dart';
import 'package:flash_light_pro/src/presentation/theme/app_theme.dart';
import 'package:flash_light_pro/src/presentation/utils/localization.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key, required this.mandatory, this.onClose});

  final bool mandatory;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<UpdateCubit, UpdateState>(
      builder: (context, state) {
        final title = switch (state.urgency) {
          UpdateUrgency.mandatory => l10n.updateRequiredTitle,
          UpdateUrgency.recommended => l10n.updateRecommendedTitle,
          UpdateUrgency.optional => l10n.updateAvailableTitle,
          UpdateUrgency.none => l10n.settingsUpdates,
        };
        final body = _bodyFor(state, l10n);

        return Dialog(
          key: const Key('update-dialog'),
          backgroundColor: AppColors.surface,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: const BorderSide(color: Color(0x26FFFFFF)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: state.urgency == UpdateUrgency.mandatory
                              ? const [AppColors.accent, Color(0xFFFFE9A8)]
                              : const [AppColors.accentAlt, Color(0xFF3E92C9)],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33FFC94D),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        state.isReadyToInstall
                            ? Icons.install_mobile_rounded
                            : state.phase == UpdatePhase.installed
                            ? Icons.check_rounded
                            : Icons.system_update_rounded,
                        size: 30,
                        color: const Color(0xFF201A05),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                  if (state.phase != UpdatePhase.installed) ...[
                    const SizedBox(height: 18),
                    _VersionCard(state: state),
                  ],
                  if (state.failure != null &&
                      state.phase != UpdatePhase.installing) ...[
                    const SizedBox(height: 12),
                    _ErrorNotice(text: _failureText(state.failure!, l10n)),
                  ],
                  if (state.fromCache &&
                      state.urgency == UpdateUrgency.mandatory) ...[
                    const SizedBox(height: 12),
                    _InfoNotice(text: l10n.updateCachedNotice),
                  ],
                  if (state.phase == UpdatePhase.downloading ||
                      state.phase == UpdatePhase.installing) ...[
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const LinearProgressIndicator(
                        minHeight: 7,
                        backgroundColor: Color(0x22FFFFFF),
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  ..._actions(context, state, l10n),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _bodyFor(UpdateState state, AppLocalizations l10n) {
    return switch (state.phase) {
      UpdatePhase.downloading => l10n.updateDownloadingBody,
      UpdatePhase.downloaded => l10n.updateReadyBody,
      UpdatePhase.installing => l10n.updateInstallingBody,
      UpdatePhase.installed => l10n.updateInstalledBody,
      _ => switch (state.urgency) {
        UpdateUrgency.mandatory => l10n.updateRequiredBody,
        UpdateUrgency.recommended => l10n.updateRecommendedBody,
        UpdateUrgency.optional => l10n.updateAvailableBody,
        UpdateUrgency.none => l10n.updateAvailableBody,
      },
    };
  }

  String _failureText(UpdateFailure failure, AppLocalizations l10n) {
    return switch (failure) {
      UpdateFailure.userCanceled => l10n.updateCanceled,
      UpdateFailure.openStoreFailed => l10n.updateStoreError,
      _ => l10n.updateErrorBody,
    };
  }

  List<Widget> _actions(
    BuildContext context,
    UpdateState state,
    AppLocalizations l10n,
  ) {
    final cubit = context.read<UpdateCubit>();

    if (state.phase == UpdatePhase.installed) {
      return [
        _PrimaryButton(
          key: const Key('update-close'),
          label: l10n.close,
          onPressed: () {
            onClose?.call();
            Navigator.of(context).pop();
          },
        ),
      ];
    }

    if (state.phase == UpdatePhase.installing) {
      return const [];
    }

    if (state.phase == UpdatePhase.downloading) {
      if (mandatory) return const [];
      return [
        _SecondaryButton(
          key: const Key('update-hide'),
          label: l10n.updateHide,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ];
    }

    if (state.phase == UpdatePhase.downloaded) {
      return [
        _PrimaryButton(
          key: const Key('update-install'),
          label: l10n.updateInstallNow,
          onPressed: () => unawaited(cubit.installFlexibleUpdate()),
        ),
        if (!mandatory) ...[
          const SizedBox(height: 6),
          _SecondaryButton(
            key: const Key('update-later'),
            label: l10n.updateLater,
            onPressed: () => _later(context, cubit),
          ),
        ],
      ];
    }

    final retryCheck =
        state.failure != null &&
        !state.immediateAllowed &&
        !state.flexibleAllowed;

    return [
      _PrimaryButton(
        key: state.failure != null
            ? const Key('update-retry')
            : const Key('update-now'),
        label: state.failure != null ? l10n.updateTryAgain : l10n.updateNow,
        onPressed: () => unawaited(
          retryCheck ? cubit.checkForUpdate(force: true) : cubit.startUpdate(),
        ),
      ),
      const SizedBox(height: 8),
      _SecondaryButton(
        key: const Key('update-store'),
        label: l10n.updateOpenStore,
        onPressed: () => unawaited(cubit.openStore()),
      ),
      if (!mandatory) ...[
        const SizedBox(height: 4),
        _SecondaryButton(
          key: const Key('update-later'),
          label: l10n.updateLater,
          onPressed: () => _later(context, cubit),
        ),
      ],
      if (mandatory && state.canBypass) ...[
        const SizedBox(height: 4),
        _SecondaryButton(
          key: const Key('update-bypass'),
          label: l10n.updateContinueAnyway,
          onPressed: () {
            cubit.continueWithoutUpdating();
            Navigator.of(context).pop();
          },
        ),
      ],
    ];
  }

  Future<void> _later(BuildContext context, UpdateCubit cubit) async {
    await cubit.dismissOptional();
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({required this.state});

  final UpdateState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final available = state.availableVersionCode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.updateInstalledVersion(state.currentVersion.toString()),
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 3),
          Text(
            available == null
                ? l10n.updateVersionUnknown
                : l10n.updateAvailableBuild(available),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFFFB4B4),
          fontSize: 12.5,
          height: 1.4,
        ),
      ),
    );
  }
}

class _InfoNotice extends StatelessWidget {
  const _InfoNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11.5,
        height: 1.4,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: const Color(0xFF201A05),
        minimumSize: const Size.fromHeight(50),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text(label),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        foregroundColor: AppColors.textPrimary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
