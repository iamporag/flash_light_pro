import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flash_light_pro/features/updates/application/update_cubit.dart';
import 'package:flash_light_pro/features/updates/domain/update_config.dart';
import 'package:flash_light_pro/src/bloc/flash_light/flash_light_bloc.dart';
import 'package:flash_light_pro/core/config/app_theme_config.dart';
import 'package:flash_light_pro/core/config/feature_config.dart';
import 'package:flash_light_pro/src/presentation/utils/localization.dart';

import 'update_dialog.dart';

/// Presents update prompts above the whole app without touching flashlight
/// state. Optional prompts wait until no light is active; mandatory prompts do
/// too, so SOS or other emergency lighting is never interrupted.
class UpdateGate extends StatefulWidget {
  const UpdateGate({super.key, required this.child, required this.config});

  final Widget child;
  final UpdateConfig config;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> with WidgetsBindingObserver {
  Timer? _startupTimer;
  bool _startupComplete = false;
  bool _dialogVisible = false;
  int? _readyNoticeVersion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (!FeatureConfig.appUpdates) return;
    if (!context.read<UpdateCubit>().state.isSupported) return;

    _startupTimer = Timer(widget.config.startupCheckDelay, () {
      if (!mounted) return;
      _startupComplete = true;
      unawaited(context.read<UpdateCubit>().checkForUpdate());
    });
  }

  @override
  void dispose() {
    _startupTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_startupComplete) return;
    unawaited(context.read<UpdateCubit>().onAppResumed());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<UpdateCubit, UpdateState>(
          listenWhen: (previous, current) =>
              previous.phase != current.phase ||
              previous.urgency != current.urgency ||
              previous.availableVersionCode != current.availableVersionCode ||
              previous.dismissedForVersion != current.dismissedForVersion ||
              previous.bypassedForVersion != current.bypassedForVersion ||
              previous.canBypass != current.canBypass ||
              previous.failure != current.failure,
          listener: (context, state) {
            _scheduleReadyNotice(state);
            _schedulePrompt();
          },
        ),
        BlocListener<FlashLightBloc, FlashLightState>(
          listenWhen: (previous, current) =>
              previous.activeLight != current.activeLight,
          listener: (context, state) => _schedulePrompt(),
        ),
      ],
      child: widget.child,
    );
  }

  void _schedulePrompt() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_maybeShowPrompt());
    });
  }

  void _scheduleReadyNotice(UpdateState state) {
    if (state.phase != UpdatePhase.downloaded || _dialogVisible) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeShowReadyNotice();
    });
  }

  Future<void> _maybeShowPrompt() async {
    if (!mounted || _dialogVisible) return;

    final update = context.read<UpdateCubit>().state;
    if (!update.shouldPrompt) return;
    if (update.phase != UpdatePhase.available) {
      // Downloads already in progress were either started from an open dialog
      // or from Settings; never pop a prompt back up after the user hid it.
      return;
    }

    final flashlight = context.read<FlashLightBloc>().state;
    if (flashlight.activeLight != null) return;

    await _showUpdateDialog(update.isMandatory);
  }

  Future<void> _showUpdateDialog(bool mandatory) async {
    if (!mounted || _dialogVisible) return;

    _dialogVisible = true;
    try {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: !mandatory,
        builder: (dialogContext) => PopScope(
          canPop: !mandatory,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop && !mandatory) {
              unawaited(context.read<UpdateCubit>().dismissOptional());
            }
          },
          child: UpdateDialog(mandatory: mandatory),
        ),
      );
    } finally {
      _dialogVisible = false;
    }

    if (!mounted) return;
    _maybeShowReadyNotice();

    final update = context.read<UpdateCubit>().state;
    if (update.isMandatory && update.shouldPrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_maybeShowPrompt());
      });
    }
  }

  void _maybeShowReadyNotice() {
    if (!mounted || _dialogVisible) return;

    final update = context.read<UpdateCubit>().state;
    if (!update.isReadyToInstall) return;

    final version = update.availableVersionCode ?? -1;
    if (_readyNoticeVersion == version) return;
    _readyNoticeVersion = version;

    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.updateReadySnack),
          duration: const Duration(seconds: 8),
          backgroundColor: AppColors.surfaceHigh,
          action: SnackBarAction(
            label: l10n.settingsUpdateInstall,
            textColor: AppColors.accent,
            onPressed: () =>
                unawaited(context.read<UpdateCubit>().installFlexibleUpdate()),
          ),
        ),
      );
  }
}
