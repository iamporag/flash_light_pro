import 'dart:async';

import 'package:flash_light_pro/features/lighting/domain/light_mode.dart';
import 'package:flash_light_pro/features/monetization/domain/ad_models.dart';
import 'package:flash_light_pro/features/monetization/presentation/monetization_native_ad.dart';
import 'package:flash_light_pro/features/monetization/presentation/monetization_scope.dart';
import 'package:flash_light_pro/features/monetization/presentation/remove_ads_card.dart';
import 'package:flash_light_pro/features/settings/domain/app_info.dart';
import 'package:flash_light_pro/features/settings/domain/app_language.dart';
import 'package:flash_light_pro/features/shake/domain/shake_sensitivity.dart';
import 'package:flash_light_pro/features/updates/application/update_cubit.dart';
import 'package:flash_light_pro/l10n/app_localizations.dart';
import 'package:flash_light_pro/src/bloc/flash_light/flash_light_bloc.dart';
import 'package:flash_light_pro/src/presentation/screens/settings/battery_optimization_section.dart';
import 'package:flash_light_pro/src/presentation/screens/settings/privacy_policy_page.dart';
import 'package:flash_light_pro/src/presentation/theme/app_theme.dart';
import 'package:flash_light_pro/src/presentation/utils/light_mode_labels.dart';
import 'package:flash_light_pro/src/presentation/utils/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: BlocBuilder<FlashLightBloc, FlashLightState>(
          buildWhen: (previous, current) =>
              previous.appLanguage != current.appLanguage ||
              previous.hapticsEnabled != current.hapticsEnabled ||
              previous.shakeEnabled != current.shakeEnabled ||
              previous.shakeSensitivity != current.shakeSensitivity ||
              previous.shakeMonitoringSupported !=
                  current.shakeMonitoringSupported ||
              previous.shakeMonitoringActive != current.shakeMonitoringActive ||
              previous.shakeNotificationsEnabled !=
                  current.shakeNotificationsEnabled ||
              previous.keepScreenAwake != current.keepScreenAwake ||
              previous.reduceAnimations != current.reduceAnimations ||
              previous.backgroundTorchEnabled !=
                  current.backgroundTorchEnabled ||
              previous.backgroundTorchSupported !=
                  current.backgroundTorchSupported ||
              previous.backgroundNotificationsEnabled !=
                  current.backgroundNotificationsEnabled ||
              previous.selectedMode != current.selectedMode,
          builder: (context, state) {
            final bloc = context.read<FlashLightBloc>();

            return ListView(
              key: const Key('settings-scroll'),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                const MonetizationStatusCard(),
                const RemoveAdsCard(),
                _SettingsSection(
                  title: l10n.language,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final language in AppLanguage.values)
                          ChoiceChip(
                            key: Key(
                              'settings-language-${language.languageCode}',
                            ),
                            label: Text(_languageName(l10n, language)),
                            selected: state.appLanguage == language,
                            onSelected: (_) =>
                                bloc.add(SetAppLanguage(language)),
                          ),
                      ],
                    ),
                  ],
                ),
                _SettingsSection(
                  title: l10n.appearanceSection,
                  children: [
                    SwitchListTile.adaptive(
                      key: const Key('settings-haptics'),
                      contentPadding: EdgeInsets.zero,
                      value: state.hapticsEnabled,
                      onChanged: (value) => bloc.add(SetHapticsEnabled(value)),
                      title: Text(l10n.haptics),
                      subtitle: Text(l10n.hapticsSubtitle),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      key: const Key('settings-reduce-animations'),
                      contentPadding: EdgeInsets.zero,
                      value: state.reduceAnimations,
                      onChanged: (value) =>
                          bloc.add(SetReduceAnimations(value)),
                      title: Text(l10n.reduceAnimations),
                      subtitle: Text(l10n.reduceAnimationsSubtitle),
                    ),
                  ],
                ),
                _SettingsSection(
                  title: l10n.motionSection,
                  children: [
                    SwitchListTile.adaptive(
                      key: const Key('settings-shake'),
                      contentPadding: EdgeInsets.zero,
                      value: state.shakeEnabled,
                      onChanged: (value) => bloc.add(SetShakeEnabled(value)),
                      title: Text(l10n.shakeToToggle),
                      subtitle: Text(
                        state.shakeEnabled
                            ? l10n.shakeSubtitleOn
                            : l10n.shakeSubtitleOff,
                      ),
                    ),
                    if (state.shakeEnabled) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.shakeSensitivity,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final sensitivity in ShakeSensitivity.values)
                            ChoiceChip(
                              key: Key(
                                'settings-sensitivity-${sensitivity.name}',
                              ),
                              label: Text(_sensitivityName(l10n, sensitivity)),
                              selected: state.shakeSensitivity == sensitivity,
                              onSelected: (_) =>
                                  bloc.add(SetShakeSensitivity(sensitivity)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ShakeMonitoringNote(state: state),
                    ],
                  ],
                ),
                _SettingsSection(
                  title: l10n.defaultMode,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.defaultModeSubtitle,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<LightMode>(
                          key: const Key('settings-default-mode'),
                          value: state.selectedMode,
                          underline: const SizedBox.shrink(),
                          borderRadius: BorderRadius.circular(14),
                          dropdownColor: AppColors.surfaceHigh,
                          items: [
                            for (final mode in LightMode.values)
                              DropdownMenuItem(
                                value: mode,
                                child: Text(
                                  modeChipLabel(mode, l10n),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                          ],
                          onChanged: (mode) {
                            if (mode != null) {
                              bloc.add(SelectLightMode(mode));
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    SwitchListTile.adaptive(
                      key: const Key('settings-keep-awake'),
                      contentPadding: EdgeInsets.zero,
                      value: state.keepScreenAwake,
                      onChanged: (value) => bloc.add(SetKeepScreenAwake(value)),
                      title: Text(l10n.keepScreenAwake),
                      subtitle: Text(l10n.keepScreenAwakeSubtitle),
                    ),
                  ],
                ),
                _SettingsSection(
                  title: l10n.backgroundSection,
                  children: [
                    SwitchListTile.adaptive(
                      key: const Key('settings-background-torch'),
                      contentPadding: EdgeInsets.zero,
                      value: state.backgroundTorchEnabled,
                      onChanged: state.backgroundTorchSupported
                          ? (value) => bloc.add(SetBackgroundTorch(value))
                          : null,
                      title: Text(l10n.keepFlashlightOnBackground),
                      subtitle: Text(
                        !state.backgroundTorchSupported
                            ? l10n.keepFlashlightOnBackgroundUnsupported
                            : state.backgroundTorchEnabled &&
                                  !state.backgroundNotificationsEnabled
                            ? l10n.backgroundNotificationsOff
                            : l10n.keepFlashlightOnBackgroundSubtitle,
                      ),
                    ),
                  ],
                ),
                const BatteryOptimizationSection(),
                _SettingsSection(
                  title: l10n.aboutSection,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.accent,
                      ),
                      title: Text(l10n.appInfo),
                      subtitle: Text(l10n.versionLabel(AppInfo.fullVersion)),
                    ),
                    const Divider(height: 1),
                    const PrivacyOptionsTile(),
                    ListTile(
                      key: const Key('settings-privacy'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.accent,
                      ),
                      title: Text(l10n.privacyPolicy),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => unawaited(_openPrivacyPolicy(context)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      key: const Key('settings-licenses'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.description_outlined,
                        color: AppColors.accent,
                      ),
                      title: Text(l10n.openSourceLicenses),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: l10n.appName,
                        applicationVersion: AppInfo.fullVersion,
                      ),
                    ),
                  ],
                ),
                _SettingsSection(
                  title: l10n.settingsUpdates,
                  children: const [_UpdateSettingsTile()],
                ),
                const MonetizationNativeAd(
                  placement: AdPlacement.settingsNative,
                ),
                ExpansionTile(
                  key: const Key('settings-device-notes'),
                  tilePadding: EdgeInsets.zero,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  title: Text(
                    l10n.permissionsTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    _NoteBlock(text: l10n.permissionsBody),
                    _NoteBlock(text: l10n.volumeButtonsTitle, title: true),
                    _NoteBlock(text: l10n.volumeButtonsBody),
                    _NoteBlock(text: l10n.iosLimitationsTitle, title: true),
                    _NoteBlock(text: l10n.iosLimitationsBody),
                  ],
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    l10n.madeOffline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Returning from the policy is a natural optional-information transition,
  /// so it is the only place an interstitial may be offered.
  Future<void> _openPrivacyPolicy(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const PrivacyPolicyPage()),
    );
    if (!context.mounted) return;
    final controller = MonetizationScope.maybeOf(context);
    await controller?.maybeShowInterstitial(AdPlacement.privacyPolicyExit);
  }

  String _languageName(AppLocalizations l10n, AppLanguage language) {
    return switch (language) {
      AppLanguage.english => l10n.languageEnglish,
      AppLanguage.bengali => l10n.languageBengali,
    };
  }

  String _sensitivityName(AppLocalizations l10n, ShakeSensitivity sensitivity) {
    return switch (sensitivity) {
      ShakeSensitivity.low => l10n.sensitivityLow,
      ShakeSensitivity.medium => l10n.sensitivityMedium,
      ShakeSensitivity.high => l10n.sensitivityHigh,
    };
  }
}

class _UpdateSettingsTile extends StatelessWidget {
  const _UpdateSettingsTile();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<UpdateCubit, UpdateState>(
      builder: (context, state) {
        final cubit = context.read<UpdateCubit>();
        final action = _actionFor(state, cubit, l10n);

        return ListTile(
          key: const Key('settings-updates'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.system_update_rounded,
            color: AppColors.accent,
          ),
          title: Text(l10n.settingsUpdates),
          subtitle: Text(_statusFor(state, l10n)),
          trailing: action == null
              ? null
              : TextButton(
                  key: const Key('settings-updates-action'),
                  onPressed: action.run,
                  child: Text(action.label),
                ),
        );
      },
    );
  }

  String _statusFor(UpdateState state, AppLocalizations l10n) {
    if (!state.isSupported) return l10n.settingsUpdateStoreManaged;

    return switch (state.phase) {
      UpdatePhase.checking => l10n.settingsUpdateChecking,
      UpdatePhase.downloading => l10n.settingsUpdateDownloading,
      UpdatePhase.downloaded => l10n.settingsUpdateReady,
      UpdatePhase.installing => l10n.settingsUpdateInstalling,
      UpdatePhase.installed => l10n.settingsUpdateInstalled,
      UpdatePhase.upToDate => l10n.settingsUpToDate,
      UpdatePhase.available =>
        state.availableVersionCode == null
            ? l10n.settingsUpdateCheck
            : l10n.settingsUpdateAvailable(state.availableVersionCode!),
      UpdatePhase.idle =>
        state.failure != null
            ? l10n.settingsUpdateFailed
            : l10n.settingsUpToDate,
    };
  }

  _UpdateAction? _actionFor(
    UpdateState state,
    UpdateCubit cubit,
    AppLocalizations l10n,
  ) {
    if (!state.isSupported) return null;

    return switch (state.phase) {
      UpdatePhase.checking ||
      UpdatePhase.downloading ||
      UpdatePhase.installing ||
      UpdatePhase.installed => null,
      UpdatePhase.downloaded => _UpdateAction(
        label: l10n.settingsUpdateInstall,
        run: () => unawaited(cubit.installFlexibleUpdate()),
      ),
      UpdatePhase.available => _UpdateAction(
        label: l10n.settingsUpdateAction,
        run: () => unawaited(cubit.startUpdate()),
      ),
      UpdatePhase.idle || UpdatePhase.upToDate => _UpdateAction(
        label: l10n.settingsUpdateCheckAction,
        run: () => unawaited(cubit.checkForUpdate(force: true)),
      ),
    };
  }
}

class _UpdateAction {
  const _UpdateAction({required this.label, required this.run});

  final String label;
  final VoidCallback run;
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.78),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x14FFFFFF)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _ShakeMonitoringNote extends StatelessWidget {
  const _ShakeMonitoringNote({required this.state});

  final FlashLightState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final (icon, text, color) = !state.shakeMonitoringSupported
        ? (
            Icons.phonelink_erase_rounded,
            l10n.shakeBackgroundUnsupported,
            AppColors.textMuted,
          )
        : !state.shakeMonitoringActive
        ? (
            Icons.error_outline_rounded,
            l10n.shakeMonitoringInactive,
            AppColors.textMuted,
          )
        : !state.shakeNotificationsEnabled
        ? (
            Icons.notifications_off_outlined,
            l10n.shakeNotificationsOff,
            AppColors.textMuted,
          )
        : (
            Icons.check_circle_outline_rounded,
            l10n.shakeMonitoringActive,
            AppColors.accent,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 12.5, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _NoteBlock extends StatelessWidget {
  const _NoteBlock({required this.text, this.title = false});

  final String text;
  final bool title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(top: title ? 12 : 2, bottom: title ? 2 : 8),
        child: Text(
          text,
          style: TextStyle(
            color: title ? AppColors.textPrimary : AppColors.textMuted,
            fontSize: title ? 13.5 : 12.5,
            fontWeight: title ? FontWeight.w600 : FontWeight.w400,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}
