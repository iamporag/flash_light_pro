import 'dart:async';
import 'dart:math' as math;

import 'package:flash_light_pro/features/flashlight/services/torch_service.dart';
import 'package:flash_light_pro/features/lighting/domain/light_mode.dart';
import 'package:flash_light_pro/features/monetization/domain/ad_models.dart';
import 'package:flash_light_pro/features/monetization/presentation/monetization_scope.dart';
import 'package:flash_light_pro/features/monetization/presentation/torch_banner_ad.dart';
import 'package:flash_light_pro/features/morse/domain/morse_codec.dart';
import 'package:flash_light_pro/src/bloc/flash_light/flash_light_bloc.dart';
import 'package:flash_light_pro/src/presentation/screens/home/widgets/mode_panels.dart';
import 'package:flash_light_pro/src/presentation/screens/home/widgets/mode_selector.dart';
import 'package:flash_light_pro/src/presentation/screens/home/widgets/power_button.dart';
import 'package:flash_light_pro/src/presentation/screens/home/widgets/timer_sheet.dart';
import 'package:flash_light_pro/src/presentation/screens/screen_light/screen_light_page.dart';
import 'package:flash_light_pro/src/presentation/screens/settings/settings_page.dart';
import 'package:flash_light_pro/src/presentation/theme/app_theme.dart';
import 'package:flash_light_pro/src/presentation/utils/light_mode_labels.dart';
import 'package:flash_light_pro/src/presentation/utils/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _morseController = TextEditingController();
  bool _isErrorDialogOpen = false;
  bool _screenLightOpen = false;
  LightMode? _lastActiveLight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _morseController.addListener(_handleMorseTextChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _morseController.removeListener(_handleMorseTextChanged);
    _morseController.dispose();
    super.dispose();
  }

  void _handleMorseTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    final bloc = context.read<FlashLightBloc>();
    switch (state) {
      case AppLifecycleState.resumed:
        bloc.add(const AppResumed());
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // `hidden` is synthesized before `paused` on mobile; both are safe to
        // send because the Bloc ignores cleanup requests when everything is off.
        bloc.add(const AppPaused());
      case AppLifecycleState.detached:
        bloc.add(const AppDetached());
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _HomeBackground()),
          SafeArea(
            child: MultiBlocListener(
              listeners: [
                BlocListener<FlashLightBloc, FlashLightState>(
                  listenWhen: (previous, current) =>
                      current.error != null && previous.error != current.error,
                  listener: (context, state) =>
                      _showErrorDialog(context, state.error!),
                ),
                BlocListener<FlashLightBloc, FlashLightState>(
                  listenWhen: (previous, current) =>
                      previous.activeLight != current.activeLight,
                  listener: (context, state) =>
                      _handleActiveLightChanged(context, state),
                ),
              ],
              child: BlocBuilder<FlashLightBloc, FlashLightState>(
                builder: (context, state) => _buildContent(context, state),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, FlashLightState state) {
    final l10n = context.l10n;
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 360;
    final short = size.height < 620;
    final animate =
        !MediaQuery.disableAnimationsOf(context) && !state.reduceAnimations;
    final powerSize = compact || short
        ? 132.0
        : math.min(size.width * 0.46, 188.0);
    final isScreenFallback =
        state.activeLight == LightMode.morse && !state.isAvailable;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 24,
            10,
            compact ? 16 : 24,
            18,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 28),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    _Header(
                      timerLabel: _timerLabel(state),
                      hasTimer: state.timerPresetMinutes != null,
                      onTimer: () => showAutoOffTimerSheet(context),
                      onSettings: () => _openSettings(context),
                    ),
                    const SizedBox(height: 18),
                    ModeSelector(
                      selected: state.selectedMode,
                      onSelected: (mode) {
                        _selectionClick();
                        context.read<FlashLightBloc>().add(
                          SelectLightMode(mode),
                        );
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 26),
                  child: Column(
                    children: [
                      PowerButton(
                        isOn: state.activeLight != null,
                        isBusy: state.isBusy,
                        enabled: _canUsePowerButton(state),
                        label: _statusLabel(state),
                        hint: _powerHint(state),
                        onPressed: () => _handlePower(state),
                        size: powerSize,
                        animate: animate,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _statusLabel(state),
                        key: const Key('power-status'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: state.activeLight != null
                              ? AppColors.accent
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: Text(
                          _subtitle(state),
                          key: const Key('power-subtitle'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ModeDetails(
                        state: state,
                        morseController: _morseController,
                        onPlayMorse: _playMorse,
                      ),
                    ],
                  ),
                ),
                Text(
                  isScreenFallback
                      ? l10n.screenFallbackFooter
                      : l10n.offlineFooter,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                  ),
                ),
                const TorchBannerAd(),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _canUsePowerButton(FlashLightState state) {
    if (state.activeLight != null) return true;
    return switch (state.selectedMode) {
      LightMode.torch || LightMode.sos || LightMode.strobe => state.isAvailable,
      LightMode.screenLight || LightMode.morse => true,
    };
  }

  Future<void> _handlePower(FlashLightState state) async {
    final l10n = context.l10n;
    final bloc = context.read<FlashLightBloc>();

    if (state.activeLight != null) {
      _mediumImpact();
      bloc.add(const StopActiveLight());
      return;
    }

    switch (state.selectedMode) {
      case LightMode.torch:
        _mediumImpact();
        bloc.add(const TurnOnFlashLight());
      case LightMode.screenLight:
        _mediumImpact();
        bloc.add(const StartScreenLight());
      case LightMode.sos:
      case LightMode.strobe:
        if (!state.isAvailable) {
          _showMessage(
            state.selectedMode == LightMode.sos
                ? l10n.sosNeedsTorch
                : l10n.strobeNeedsTorchMessage,
          );
          return;
        }
        _mediumImpact();
        bloc.add(
          state.selectedMode == LightMode.sos
              ? const StartSos()
              : const StartStrobe(),
        );
      case LightMode.morse:
        _playMorse();
    }
  }

  void _playMorse() {
    final l10n = context.l10n;
    final text = _morseController.text.trim();
    if (text.isEmpty) {
      _showMessage(l10n.typeMessage);
      return;
    }

    final result = MorseCodec.encode(text);
    if (!result.isPlayable) {
      _showMessage(l10n.unsupportedCharacters(result.unsupported.join(' ')));
      return;
    }

    _selectionClick();
    context.read<FlashLightBloc>().add(StartMorse(text));
  }

  void _handleActiveLightChanged(BuildContext context, FlashLightState state) {
    final active = state.activeLight;

    if (active == LightMode.screenLight) {
      _openScreenLight(context);
    }

    if (active != null) {
      _announce(context, context.l10n.announcementOn(_announcementFor(active)));
    } else if (_lastActiveLight != null) {
      _announce(
        context,
        context.l10n.announcementOff(_announcementFor(_lastActiveLight!)),
      );
    }
    _lastActiveLight = active;
  }

  void _openScreenLight(BuildContext context) {
    if (_screenLightOpen) return;

    _screenLightOpen = true;
    unawaited(
      Navigator.of(context, rootNavigator: true)
          .push(
            MaterialPageRoute<void>(
              builder: (context) => const ScreenLightPage(),
            ),
          )
          .whenComplete(() => _screenLightOpen = false),
    );
  }

  void _openSettings(BuildContext context) {
    final controller = MonetizationScope.maybeOf(context);
    unawaited(controller?.registerEligibleAction(AdActionId.openSettings));
    unawaited(
      Navigator.of(context, rootNavigator: true)
          .push(
            MaterialPageRoute<void>(builder: (context) => const SettingsPage()),
          )
          .whenComplete(() {
            unawaited(
              controller?.registerEligibleAction(AdActionId.closeSettings),
            );
          }),
    );
  }

  void _announce(BuildContext context, String message) {
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );
  }

  String _announcementFor(LightMode mode) {
    return modeDisplayName(mode, context.l10n);
  }

  String _statusLabel(FlashLightState state) {
    final l10n = context.l10n;
    final active = state.activeLight;
    if (active != null) {
      return switch (active) {
        LightMode.torch => l10n.statusTorchOn,
        LightMode.screenLight => l10n.statusScreenOn,
        LightMode.sos => l10n.statusSosActive,
        LightMode.strobe => l10n.statusStrobeOn,
        LightMode.morse =>
          state.sequencePaused
              ? l10n.statusMorsePaused
              : l10n.statusSendingMorse,
      };
    }

    if (state.availability == TorchAvailability.unknown ||
        state.availability == TorchAvailability.checking) {
      return l10n.statusChecking;
    }

    return switch (state.selectedMode) {
      LightMode.torch =>
        state.isAvailable ? l10n.statusTorchOff : l10n.statusTorchUnavailable,
      LightMode.screenLight => l10n.statusScreenOff,
      LightMode.sos =>
        state.isAvailable ? l10n.statusSosReady : l10n.statusSosNeedsTorch,
      LightMode.strobe =>
        state.isAvailable
            ? l10n.statusStrobeReady
            : l10n.statusStrobeNeedsTorch,
      LightMode.morse => l10n.statusMorseReady,
    };
  }

  String _subtitle(FlashLightState state) {
    final l10n = context.l10n;
    if (state.timerSecondsRemaining != null) {
      return l10n.subtitleAutoOff(
        formatCountdown(context, state.timerSecondsRemaining!),
      );
    }

    if (state.activeLight != null) {
      if (state.activeLight == LightMode.morse && state.sequencePaused) {
        return l10n.subtitleMorsePaused;
      }
      return l10n.subtitleTapStop;
    }

    if (state.availability == TorchAvailability.checking ||
        state.availability == TorchAvailability.unknown) {
      return l10n.subtitleCheckingHardware;
    }

    return switch (state.selectedMode) {
      LightMode.torch =>
        state.isAvailable
            ? l10n.subtitleTorchReady
            : l10n.subtitleTorchUnavailable,
      LightMode.screenLight => l10n.subtitleScreenReady,
      LightMode.sos => l10n.subtitleSosReady,
      LightMode.strobe => l10n.subtitleStrobeReady,
      LightMode.morse => l10n.subtitleMorseReady,
    };
  }

  String _powerHint(FlashLightState state) {
    final l10n = context.l10n;
    if (state.activeLight != null) {
      return l10n.hintStop;
    }
    return switch (state.selectedMode) {
      LightMode.torch => l10n.hintTorchOn,
      LightMode.screenLight => l10n.hintScreen,
      LightMode.sos => l10n.hintSos,
      LightMode.strobe => l10n.hintStrobe,
      LightMode.morse => l10n.hintMorse,
    };
  }

  String _timerLabel(FlashLightState state) {
    final l10n = context.l10n;
    if (state.timerSecondsRemaining != null) {
      return l10n.timerCountdown(
        formatCountdown(context, state.timerSecondsRemaining!),
      );
    }
    final preset = state.timerPresetMinutes;
    return preset == null ? l10n.timerOff : l10n.timerPreset(preset);
  }

  bool _hapticsEnabled() => context.read<FlashLightBloc>().state.hapticsEnabled;

  void _selectionClick() {
    if (_hapticsEnabled()) HapticFeedback.selectionClick();
  }

  void _mediumImpact() {
    if (_hapticsEnabled()) HapticFeedback.mediumImpact();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showErrorDialog(
    BuildContext context,
    TorchFailure failure,
  ) async {
    if (_isErrorDialogOpen) return;

    _isErrorDialogOpen = true;
    final l10n = context.l10n;
    final bloc = context.read<FlashLightBloc>();
    final mode = bloc.state.selectedMode;
    final canRetry =
        failure.kind != TorchFailureKind.platformUnavailable &&
        mode != LightMode.morse;

    final shouldRetry = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.lightingError),
        content: Text(_messageFor(failure)),
        actions: [
          TextButton(
            key: const Key('error-dismiss'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.dismiss),
          ),
          if (canRetry)
            TextButton(
              key: const Key('error-retry'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.retry),
            ),
        ],
      ),
    );

    _isErrorDialogOpen = false;
    if (!mounted) return;

    bloc.add(const ClearFlashLightError());
    if (shouldRetry != true) return;

    switch (mode) {
      case LightMode.torch:
        bloc.add(
          bloc.state.isTorchOn
              ? const TurnOffFlashLight()
              : const TurnOnFlashLight(),
        );
      case LightMode.screenLight:
        bloc.add(const StartScreenLight());
      case LightMode.sos:
        bloc.add(const StartSos());
      case LightMode.strobe:
        bloc.add(const StartStrobe());
      case LightMode.morse:
        break;
    }
  }

  String _messageFor(TorchFailure failure) {
    final l10n = context.l10n;
    return switch (failure.kind) {
      TorchFailureKind.unavailable => l10n.errorUnavailable,
      TorchFailureKind.cameraInUse => l10n.errorCameraInUse,
      TorchFailureKind.enableFailed => l10n.errorEnable,
      TorchFailureKind.disableFailed => l10n.errorDisable,
      TorchFailureKind.availabilityFailed => l10n.errorCheck,
      TorchFailureKind.platformUnavailable => l10n.errorPlatform,
      TorchFailureKind.unexpected => l10n.errorUnexpected,
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.timerLabel,
    required this.hasTimer,
    required this.onTimer,
    required this.onSettings,
  });

  final String timerLabel;
  final bool hasTimer;
  final VoidCallback onTimer;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accent, Color(0xFFFFE9A8)],
            ),
          ),
          child: const Icon(
            Icons.flashlight_on_rounded,
            size: 21,
            color: Color(0xFF231A02),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                l10n.appTagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          key: const Key('settings-button'),
          tooltip: l10n.openSettings,
          onPressed: onSettings,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface.withValues(alpha: 0.75),
            minimumSize: const Size(48, 48),
          ),
          icon: const Icon(Icons.settings_outlined, size: 21),
        ),
        const SizedBox(width: 8),
        IconButton(
          key: const Key('timer-button'),
          tooltip: timerLabel,
          onPressed: onTimer,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface.withValues(alpha: 0.75),
            minimumSize: const Size(48, 48),
          ),
          icon: Badge(
            isLabelVisible: hasTimer,
            smallSize: 8,
            backgroundColor: AppColors.accent,
            child: const Icon(Icons.timer_outlined, size: 21),
          ),
        ),
      ],
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.15,
          colors: [AppColors.backgroundGlow, AppColors.background],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

/// Behind the controls, so a Morse screen-flash fallback never hides the stop
/// button while it flashes.
class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

  @override
  Widget build(BuildContext context) {
    final player = context.read<FlashLightBloc>().sequencePlayer;

    return BlocBuilder<FlashLightBloc, FlashLightState>(
      buildWhen: (previous, current) =>
          previous.activeLight != current.activeLight ||
          previous.availability != current.availability,
      builder: (context, state) {
        if (state.activeLight == LightMode.morse && !state.isAvailable) {
          return ValueListenableBuilder<bool>(
            valueListenable: player.screenFlash,
            builder: (context, isFlashing, _) => AnimatedContainer(
              duration: const Duration(milliseconds: 60),
              color: isFlashing ? Colors.white : AppColors.background,
            ),
          );
        }
        return const _AmbientBackground();
      },
    );
  }
}
