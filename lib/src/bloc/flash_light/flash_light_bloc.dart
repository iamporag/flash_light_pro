import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../features/device/services/device_controls.dart';
import '../../../features/device/services/native_controls.dart';
import '../../../features/flashlight/services/background_torch_service.dart';
import '../../../features/flashlight/services/torch_service.dart';
import '../../../features/lighting/domain/light_mode.dart';
import '../../../features/lighting/domain/lighting_defaults.dart';
import '../../../features/morse/domain/morse_codec.dart';
import '../../../features/morse/domain/morse_pattern.dart';
import '../../../features/sequences/domain/light_step.dart';
import '../../../features/sequences/services/sequence_player.dart';
import '../../../features/settings/data/app_settings.dart';
import '../../../features/settings/data/settings_repository.dart';
import '../../../features/settings/domain/app_language.dart';
import '../../../features/shake/domain/shake_sensitivity.dart';
import '../../../features/shake/services/shake_monitor_service.dart';
import '../../../features/shake/services/shake_service.dart';
import '../../../features/sos/domain/sos_pattern.dart';
import '../../../features/strobe/domain/strobe_pattern.dart';

part 'flash_light_event.dart';
part 'flash_light_state.dart';

class FlashLightBloc extends Bloc<FlashLightEvent, FlashLightState> {
  FlashLightBloc({
    required this.torchService,
    DeviceControls? deviceControls,
    SettingsRepository? settingsRepository,
    SequencePlayer? sequencePlayer,
    this.shakeService,
    TorchStateSource? torchStateSource,
    BackgroundTorchService? backgroundTorchService,
    ShakeMonitorService? shakeMonitorService,
    NativeControlsSource? nativeControlsSource,
    Duration? autoOffTick,
  }) : _deviceControls = deviceControls ?? const MethodChannelDeviceControls(),
       _settingsRepository =
           settingsRepository ?? const NoopSettingsRepository(),
       _sequencePlayer =
           sequencePlayer ?? SequencePlayer(torchService: torchService),
       _backgroundTorchService =
           backgroundTorchService ?? const UnsupportedBackgroundTorchService(),
       _shakeMonitorService =
           shakeMonitorService ?? const UnsupportedShakeMonitorService(),
       _nativeControls =
           nativeControlsSource ?? const UnsupportedNativeControls(),
       _autoOffTick = autoOffTick ?? const Duration(seconds: 1),
       super(const FlashLightState()) {
    on<FlashLightEvent>(_onEvent, transformer: _sequential());
    _torchStateSubscription = torchStateSource?.changes.listen((isOn) {
      if (!isClosed) add(ExternalTorchStateChanged(isOn));
    });
    _backgroundServiceSubscription = _backgroundTorchService.statusChanges
        .listen((status) {
          if (!isClosed) add(BackgroundServiceStatusChanged(status));
        });
    _shakeSubscription = shakeService?.shakes.listen((_) {
      if (!isClosed) add(const ShakeDetected());
    });
    _shakeMonitorSubscription = _shakeMonitorService.statusChanges.listen((
      status,
    ) {
      if (!isClosed) add(ShakeMonitorStatusChanged(status));
    });
    _nativeControlsSubscription = _nativeControls.changes.listen((snapshot) {
      if (!isClosed) add(NativeControlsChanged(snapshot));
    });
    add(const LoadSettings());
    add(const CheckTorchAvailability(force: true));
  }

  final TorchService torchService;
  final DeviceControls _deviceControls;
  final SettingsRepository _settingsRepository;
  final SequencePlayer _sequencePlayer;
  final BackgroundTorchService _backgroundTorchService;
  final ShakeMonitorService _shakeMonitorService;
  final NativeControlsSource _nativeControls;
  final ShakeService? shakeService;
  final Duration _autoOffTick;

  Timer? _timer;
  StreamSubscription<bool>? _torchStateSubscription;
  StreamSubscription<void>? _shakeSubscription;
  StreamSubscription<BackgroundTorchStatus>? _backgroundServiceSubscription;
  StreamSubscription<ShakeMonitorStatus>? _shakeMonitorSubscription;
  StreamSubscription<NativeControlsSnapshot>? _nativeControlsSubscription;
  bool _isResumed = true;
  bool _notificationPermissionRequested = false;
  bool _shakeNotificationPermissionRequested = false;
  bool? _lastMirroredShakeBlocked;

  /// True while SOS or strobe is owned by the native foreground service. Dart
  /// must not drive the torch or claim the mode is off in that case.
  bool _nativePatternActive = false;

  /// True when the torch was started by the tile, widget, or an App Intent,
  /// so pausing Flutter must not switch it off.
  bool _externallyActivated = false;

  /// Exposed so the screen-flash fallback can be painted without rebuilding the
  /// whole Bloc state on every blink.
  SequencePlayer get sequencePlayer => _sequencePlayer;

  /// Hardware calls are processed one at a time so an enable can never overlap
  /// an in-flight disable (unlike `restartable`, which cancels handlers).
  EventTransformer<E> _sequential<E>() {
    return (events, mapper) => events.asyncExpand(mapper);
  }

  Future<void> _onEvent(
    FlashLightEvent event,
    Emitter<FlashLightState> emit,
  ) async {
    switch (event) {
      case LoadSettings():
        await _loadSettings(emit);
      case CheckTorchAvailability(:final force):
        await _checkAvailability(emit, force: force);
      case SelectLightMode(:final mode):
        await _selectMode(emit, mode);
      case TurnOnFlashLight():
        await _turnOn(emit);
      case TurnOffFlashLight():
        await _stopActiveLight(emit);
      case StartScreenLight():
        await _startScreenLight(emit);
      case StartSos():
        await _startPattern(emit, LightMode.sos);
      case StartStrobe():
        await _startPattern(emit, LightMode.strobe);
      case StartMorse(:final text):
        await _startMorse(emit, text);
      case PauseSequence():
        await _pauseSequence(emit);
      case ResumeSequence():
        await _resumeSequence(emit);
      case StopActiveLight():
        await _stopActiveLight(emit);
      case SetScreenLightColor(:final value):
        _setScreenColor(emit, value);
      case SetScreenBrightness(:final value):
        await _setScreenBrightness(emit, value);
      case SetTorchLevel(:final value):
        await _setTorchLevel(emit, value);
      case SetStrobeInterval(:final milliseconds):
        await _setStrobeInterval(emit, milliseconds);
      case SetAutoOffTimer(:final minutes):
        _setAutoOffTimer(emit, minutes);
      case AutoOffTick():
        await _onAutoOffTick(emit);
      case SequenceCompleted(:final mode):
        await _onSequenceCompleted(emit, mode);
      case SequenceFailed(:final mode, :final failure):
        await _onSequenceFailed(emit, mode, failure);
      case ClearFlashLightError():
        emit(state.copyWith(error: null));
      case ExternalTorchStateChanged(:final isOn):
        await _handleExternalTorchState(emit, isOn);
      case ShakeDetected():
        await _toggleFromShake(emit);
      case ShakeMonitorStatusChanged(:final status):
        await _handleShakeMonitorStatus(emit, status);
      case NativeControlsChanged(:final snapshot):
        await _handleNativeControls(emit, snapshot);
      case SetAppLanguage(:final language):
        _setAppLanguage(emit, language);
      case SetHapticsEnabled(:final enabled):
        _setHapticsEnabled(emit, enabled);
      case SetShakeEnabled(:final enabled):
        await _setShakeEnabled(emit, enabled);
      case SetShakeSensitivity(:final sensitivity):
        await _setShakeSensitivity(emit, sensitivity);
      case SetKeepScreenAwake(:final enabled):
        await _setKeepScreenAwake(emit, enabled);
      case SetReduceAnimations(:final enabled):
        _setReduceAnimations(emit, enabled);
      case SetBackgroundTorch(:final enabled):
        await _setBackgroundTorch(emit, enabled);
      case BackgroundServiceStatusChanged(:final status):
        await _handleBackgroundServiceStatus(emit, status);
      case AppPaused():
        await _handlePaused(emit);
      case AppResumed():
        await _handleAppResumed(emit);
      case AppDetached():
        await _handleDetached(emit);
    }

    // The native listener runs without Flutter, so it needs to know whenever
    // SOS, strobe, Morse, or screen light takes ownership of the torch.
    await _mirrorShakeBlockedIfChanged();
  }

  Future<void> _loadSettings(Emitter<FlashLightState> emit) async {
    AppSettings settings;
    try {
      settings = await _settingsRepository.load();
    } catch (_) {
      settings = const AppSettings();
    }
    if (isClosed) return;

    bool levelSupported;
    try {
      levelSupported = await _deviceControls.isTorchLevelSupported();
    } catch (_) {
      levelSupported = false;
    }
    if (isClosed) return;

    var backgroundSupported = false;
    var notificationsEnabled = true;
    try {
      backgroundSupported = await _backgroundTorchService.isSupported();
      if (backgroundSupported) {
        notificationsEnabled = await _backgroundTorchService
            .hasNotificationPermission();
      }
    } catch (_) {
      backgroundSupported = false;
    }
    if (isClosed) return;

    var shakeSupported = false;
    var shakeActive = false;
    var shakeNotifications = true;
    try {
      shakeSupported = await _shakeMonitorService.isSupported();
      if (shakeSupported) {
        shakeActive = await _shakeMonitorService.isRunning();
        shakeNotifications = await _shakeMonitorService
            .hasNotificationPermission();
      }
    } catch (_) {
      shakeSupported = false;
    }
    if (isClosed) return;

    emit(
      state.copyWith(
        selectedMode: settings.selectedMode,
        screenColorValue: settings.screenColorValue,
        screenBrightness: settings.screenBrightness,
        torchLevel: settings.torchLevel,
        strobeIntervalMs: settings.strobeIntervalMs,
        timerPresetMinutes: settings.timerPresetMinutes,
        isTorchLevelSupported: levelSupported,
        appLanguage: settings.appLanguage,
        hapticsEnabled: settings.hapticsEnabled,
        shakeEnabled: settings.shakeEnabled,
        shakeSensitivity: settings.shakeSensitivity,
        shakeMonitoringSupported: shakeSupported,
        shakeMonitoringActive: shakeActive,
        shakeNotificationsEnabled: shakeNotifications,
        keepScreenAwake: settings.keepScreenAwake,
        reduceAnimations: settings.reduceAnimations,
        backgroundTorchSupported: backgroundSupported,
        backgroundNotificationsEnabled: notificationsEnabled,
        backgroundTorchEnabled:
            backgroundSupported && settings.backgroundTorchEnabled,
      ),
    );

    if (backgroundSupported) {
      // The native tile and widget can act without a Flutter engine, so they
      // keep their own copy of the user's background-mode choice.
      unawaited(
        _backgroundTorchService.setBackgroundPreference(
          settings.backgroundTorchEnabled,
        ),
      );
    }
    // The native panel can start strobe without Flutter, so mirror the speed.
    unawaited(
      _deviceControls.setStrobeIntervalPreference(settings.strobeIntervalMs),
    );

    await _syncShakeMonitoring(emit);
  }

  Future<void> _checkAvailability(
    Emitter<FlashLightState> emit, {
    bool force = false,
  }) async {
    if (state.availability == TorchAvailability.checking) return;
    if (!force && state.availability == TorchAvailability.available) return;

    emit(state.copyWith(availability: TorchAvailability.checking));

    try {
      final isAvailable = await torchService.isAvailable();
      if (isClosed) return;

      final levelSupported = isAvailable
          ? await _deviceControls.isTorchLevelSupported()
          : false;
      if (isClosed) return;

      emit(
        state.copyWith(
          availability: isAvailable
              ? TorchAvailability.available
              : TorchAvailability.unavailable,
          isTorchLevelSupported: levelSupported,
        ),
      );
    } on TorchFailure {
      // An unavailable device is a normal state, not a user-facing error.
      if (isClosed) return;
      emit(
        state.copyWith(
          availability: TorchAvailability.unavailable,
          isTorchLevelSupported: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          availability: TorchAvailability.unavailable,
          isTorchLevelSupported: false,
        ),
      );
    }
  }

  Future<void> _handleAppResumed(Emitter<FlashLightState> emit) async {
    _isResumed = true;
    await _syncShakeMonitoring(emit);
    if (state.availability != TorchAvailability.available) {
      await _checkAvailability(emit, force: true);
    }
    // The notification action, a background shake, or the OS may have changed
    // the hardware while Flutter was not rendering. Reconcile, never toggle.
    await _syncNativeTorchState(emit);
    await _syncBackgroundService(emit);
  }

  /// The Dart sensor listener is only the foreground fallback. While the
  /// native monitor runs, Dart must stay quiet so one shake never toggles
  /// twice.
  void _syncShakeDetection() {
    final service = shakeService;
    if (service == null) return;

    if (_isResumed && state.shakeEnabled && !state.shakeMonitoringActive) {
      service.start(sensitivity: state.shakeSensitivity);
    } else {
      unawaited(service.stop());
    }
  }

  /// Reconciles the native monitor with the user's choice. Never changes the
  /// torch: disabling monitoring leaves an active flashlight running.
  Future<void> _syncShakeMonitoring(Emitter<FlashLightState> emit) async {
    if (!state.shakeMonitoringSupported) {
      _syncShakeDetection();
      return;
    }

    await _mirrorShakeState();
    if (isClosed) return;

    if (!state.shakeEnabled) {
      if (state.shakeMonitoringActive) {
        await _shakeMonitorService.stop();
        if (isClosed) return;
        emit(state.copyWith(shakeMonitoringActive: false));
      }
      _syncShakeDetection();
      return;
    }

    bool running;
    try {
      running = await _shakeMonitorService.isRunning();
    } catch (_) {
      running = false;
    }
    if (isClosed) return;

    if (!running) {
      final result = await _shakeMonitorService.start();
      if (isClosed) return;

      if (result.started) {
        emit(
          state.copyWith(
            shakeMonitoringActive: true,
            shakeNotificationsEnabled: result.notificationsEnabled,
          ),
        );
      } else if (state.shakeMonitoringActive) {
        emit(state.copyWith(shakeMonitoringActive: false));
      }
    } else if (!state.shakeMonitoringActive) {
      emit(state.copyWith(shakeMonitoringActive: true));
    }

    // The user can change the notification permission in system settings while
    // the monitor keeps running, so refresh the explanation on every sync.
    bool notificationsEnabled = state.shakeNotificationsEnabled;
    try {
      notificationsEnabled = await _shakeMonitorService
          .hasNotificationPermission();
    } catch (_) {
      notificationsEnabled = state.shakeNotificationsEnabled;
    }
    if (isClosed) return;
    if (notificationsEnabled != state.shakeNotificationsEnabled) {
      emit(state.copyWith(shakeNotificationsEnabled: notificationsEnabled));
    }

    _syncShakeDetection();
  }

  bool get _isShakeBlocked =>
      state.isSequenceActive || state.isScreenLightOn || _nativePatternActive;

  Future<void> _mirrorShakeState() async {
    final blocked = _isShakeBlocked;
    _lastMirroredShakeBlocked = blocked;
    await _shakeMonitorService.setPreference(
      enabled: state.shakeEnabled,
      sensitivity: state.shakeSensitivity,
      blocked: blocked,
    );
  }

  Future<void> _mirrorShakeBlockedIfChanged() async {
    if (!state.shakeMonitoringSupported) return;

    final blocked = _isShakeBlocked;
    if (_lastMirroredShakeBlocked == blocked) return;
    await _mirrorShakeState();
  }

  Future<void> _handleShakeMonitorStatus(
    Emitter<FlashLightState> emit,
    ShakeMonitorStatus status,
  ) async {
    final running = status == ShakeMonitorStatus.running;
    if (state.shakeMonitoringActive != running ||
        (running && !state.shakeMonitoringSupported)) {
      emit(
        state.copyWith(
          shakeMonitoringActive: running,
          shakeMonitoringSupported: running || state.shakeMonitoringSupported,
        ),
      );
    }
    // A failed or stopped service falls back to the visible-app listener.
    _syncShakeDetection();
  }

  /// Applies the consolidated native state after the notification panel, tile,
  /// widget, or background shake listener acted without a Flutter UI.
  Future<void> _handleNativeControls(
    Emitter<FlashLightState> emit,
    NativeControlsSnapshot snapshot,
  ) async {
    final shakeChanged =
        snapshot.shakeEnabled != state.shakeEnabled ||
        snapshot.shakeMonitoring != state.shakeMonitoringActive ||
        snapshot.backgroundServiceRunning != state.backgroundTorchActive ||
        snapshot.notificationsEnabled != state.backgroundNotificationsEnabled;
    final persistShake = snapshot.shakeEnabled != state.shakeEnabled;

    if (shakeChanged) {
      emit(
        state.copyWith(
          shakeEnabled: snapshot.shakeEnabled,
          shakeMonitoringActive: snapshot.shakeMonitoring,
          shakeMonitoringSupported:
              state.shakeMonitoringSupported || snapshot.shakeMonitoring,
          shakeNotificationsEnabled: snapshot.notificationsEnabled,
          backgroundTorchActive: snapshot.backgroundServiceRunning,
          backgroundNotificationsEnabled: snapshot.notificationsEnabled,
        ),
      );
      if (persistShake) _persistSettings();
      _syncShakeDetection();
    }

    final nativeModeActive = snapshot.mode != NativePatternMode.off;
    if (!nativeModeActive) {
      if (!_nativePatternActive) return;

      _nativePatternActive = false;
      _cancelTimer();
      await _deviceControls.setKeepScreenOn(false);
      if (isClosed) return;
      emit(
        state.copyWith(
          activeLight: null,
          isBusy: false,
          sequencePaused: false,
          timerSecondsRemaining: null,
          error: null,
        ),
      );
      await _stopBackgroundServiceIfIdle(emit);
      return;
    }

    final wasNative = _nativePatternActive;
    _nativePatternActive = true;
    final mode = snapshot.mode == NativePatternMode.sos
        ? LightMode.sos
        : LightMode.strobe;

    if (!wasNative) {
      // A mode started outside Flutter. Release any Dart-owned output before
      // claiming the mode, because the native player now owns the hardware.
      await _sequencePlayer.stop();
      if (state.isScreenLightOn) {
        await _deviceControls.restoreScreenBrightness();
      }
      _cancelTimer();
      _externallyActivated = false;
    }

    final paused = snapshot.paused;
    if (state.activeLight != mode || state.sequencePaused != paused) {
      emit(
        state.copyWith(
          activeLight: mode,
          selectedMode: mode,
          isBusy: false,
          sequencePaused: paused,
          error: null,
          timerSecondsRemaining: null,
        ),
      );
    }
    await _deviceControls.setKeepScreenOn(state.keepScreenAwake);
  }

  Future<void> _toggleFromShake(Emitter<FlashLightState> emit) async {
    if (!state.shakeEnabled || !_isResumed) return;
    // While native monitoring is on, it owns shake detection.
    if (state.shakeMonitoringActive) return;
    if (state.isSequenceActive || state.isScreenLightOn) return;
    if (!state.isAvailable) return;

    _externallyActivated = false;
    if (state.isTorchOn) {
      await _stopActiveLight(emit);
    } else {
      await _turnOn(emit);
    }
  }

  void _setAppLanguage(Emitter<FlashLightState> emit, AppLanguage language) {
    if (state.appLanguage == language) return;
    emit(state.copyWith(appLanguage: language));
    _persistSettings();
  }

  void _setHapticsEnabled(Emitter<FlashLightState> emit, bool enabled) {
    if (state.hapticsEnabled == enabled) return;
    emit(state.copyWith(hapticsEnabled: enabled));
    _persistSettings();
  }

  Future<void> _setShakeEnabled(
    Emitter<FlashLightState> emit,
    bool enabled,
  ) async {
    if (state.shakeEnabled == enabled) return;
    emit(state.copyWith(shakeEnabled: enabled));

    // Android 13+ needs notification permission for the monitoring
    // notification. Ask once, while the user is looking at the switch; denial
    // still leaves monitoring available and is explained in settings.
    if (enabled &&
        state.shakeMonitoringSupported &&
        !state.shakeNotificationsEnabled &&
        !_shakeNotificationPermissionRequested) {
      _shakeNotificationPermissionRequested = true;
      final granted = await _shakeMonitorService
          .requestNotificationPermission();
      if (isClosed) return;
      emit(state.copyWith(shakeNotificationsEnabled: granted));
    }

    await _syncShakeMonitoring(emit);
    _persistSettings();
  }

  Future<void> _setShakeSensitivity(
    Emitter<FlashLightState> emit,
    ShakeSensitivity sensitivity,
  ) async {
    if (state.shakeSensitivity == sensitivity) return;
    emit(state.copyWith(shakeSensitivity: sensitivity));
    await _syncShakeMonitoring(emit);
    _persistSettings();
  }

  Future<void> _setKeepScreenAwake(
    Emitter<FlashLightState> emit,
    bool enabled,
  ) async {
    if (state.keepScreenAwake == enabled) return;
    emit(state.copyWith(keepScreenAwake: enabled));

    if (state.activeLight != null) {
      await _deviceControls.setKeepScreenOn(enabled);
    }
    _persistSettings();
  }

  void _setReduceAnimations(Emitter<FlashLightState> emit, bool enabled) {
    if (state.reduceAnimations == enabled) return;
    emit(state.copyWith(reduceAnimations: enabled));
    _persistSettings();
  }

  Future<void> _handleExternalTorchState(
    Emitter<FlashLightState> emit,
    bool isOn,
  ) async {
    // Sequences own the torch while they run; letting a tile tap interrupt
    // them would leave the sequence and the state disagreeing. A native
    // pattern also fires hardware updates on every blink.
    if (state.isSequenceActive || state.isBusy || _nativePatternActive) return;

    if (isOn == state.isTorchOn) return;

    if (isOn) {
      if (state.isScreenLightOn) {
        final stopped = await _stopActiveLight(emit);
        if (!stopped) return;
      }

      _cancelTimer();
      _externallyActivated = true;
      emit(
        state.copyWith(
          availability: TorchAvailability.available,
          activeLight: LightMode.torch,
          selectedMode: LightMode.torch,
          isBusy: false,
          error: null,
          sequencePaused: false,
          timerSecondsRemaining: null,
        ),
      );
      await _deviceControls.setKeepScreenOn(state.keepScreenAwake);
      if (_isResumed &&
          state.backgroundTorchEnabled &&
          state.backgroundTorchSupported) {
        await _ensureBackgroundService(emit);
      }
      return;
    }

    _externallyActivated = false;
    _cancelTimer();
    await _deviceControls.setKeepScreenOn(false);
    if (state.isTorchOn) {
      emit(
        state.copyWith(
          activeLight: null,
          isBusy: false,
          timerSecondsRemaining: null,
        ),
      );
    }
    await _stopBackgroundServiceIfIdle(emit);
  }

  Future<void> _selectMode(
    Emitter<FlashLightState> emit,
    LightMode mode,
  ) async {
    if (state.selectedMode == mode) return;

    if (state.activeLight != null && state.activeLight != mode) {
      final stopped = await _stopActiveLight(emit);
      if (!stopped) return;
    }

    emit(state.copyWith(selectedMode: mode));
    _persistSettings();
  }

  Future<void> _turnOn(Emitter<FlashLightState> emit) async {
    if (state.availability != TorchAvailability.available || state.isTorchOn) {
      return;
    }
    if (state.activeLight != null) {
      final stopped = await _stopActiveLight(emit);
      if (!stopped) return;
    }

    emit(state.copyWith(isBusy: true));

    try {
      await torchService.enable();
      if (isClosed) return;

      if (state.isTorchLevelSupported) {
        await _deviceControls.setTorchLevel(state.torchLevel);
        if (isClosed) return;
      }
      _externallyActivated = false;
      await _deviceControls.setKeepScreenOn(state.keepScreenAwake);
      if (isClosed) return;

      emit(
        state.copyWith(
          activeLight: LightMode.torch,
          selectedMode: LightMode.torch,
          isBusy: false,
          error: null,
          sequencePaused: false,
        ),
      );
      _startTimerFromPreset(emit);
      _persistSettings();
      if (state.backgroundTorchEnabled && state.backgroundTorchSupported) {
        // The activity is visible here, which is the safest moment to start
        // the foreground service on Android 12+.
        await _ensureBackgroundService(emit);
      }
    } on TorchFailure catch (failure) {
      if (isClosed) return;

      if (failure.kind == TorchFailureKind.unavailable) {
        emit(
          state.copyWith(
            availability: TorchAvailability.unavailable,
            isBusy: false,
          ),
        );
      } else {
        emit(state.copyWith(isBusy: false, error: failure));
      }
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isBusy: false,
          error: const TorchFailure(TorchFailureKind.unexpected),
        ),
      );
    }
  }

  Future<void> _startScreenLight(Emitter<FlashLightState> emit) async {
    if (state.isScreenLightOn) return;

    if (state.activeLight != null) {
      final stopped = await _stopActiveLight(emit);
      if (!stopped) return;
    }

    emit(
      state.copyWith(
        activeLight: LightMode.screenLight,
        selectedMode: LightMode.screenLight,
        isBusy: false,
        error: null,
        sequencePaused: false,
      ),
    );

    _externallyActivated = false;
    await _deviceControls.setKeepScreenOn(state.keepScreenAwake);
    if (isClosed) return;
    await _deviceControls.setScreenBrightness(state.screenBrightness);
    if (isClosed) return;

    _startTimerFromPreset(emit);
    _persistSettings();
  }

  Future<void> _startMorse(Emitter<FlashLightState> emit, String text) async {
    final result = MorseCodec.encode(text);
    if (!result.isPlayable) return;

    await _startSequence(
      emit,
      LightMode.morse,
      MorsePattern.build(result.morse),
    );
  }

  /// SOS and strobe are owned by the native foreground service on Android so
  /// they keep running after the UI closes. The Dart player remains the
  /// fallback on platforms without native playback.
  Future<void> _startPattern(
    Emitter<FlashLightState> emit,
    LightMode mode,
  ) async {
    if (state.activeLight == mode || !state.isAvailable) return;
    if (state.activeLight != null) {
      final stopped = await _stopActiveLight(emit);
      if (!stopped) return;
    }

    final wire = mode == LightMode.sos ? 'sos' : 'strobe';
    final started = await _deviceControls.startTorchMode(wire);
    if (isClosed) return;

    if (!started) {
      await _startSequence(
        emit,
        mode,
        mode == LightMode.sos
            ? SosPattern.build()
            : StrobePattern.build(state.strobeIntervalMs),
      );
      return;
    }

    _nativePatternActive = true;
    _externallyActivated = false;
    _lastMirroredShakeBlocked = true;
    emit(
      state.copyWith(
        activeLight: mode,
        selectedMode: mode,
        isBusy: false,
        error: null,
        sequencePaused: false,
      ),
    );
    await _deviceControls.setKeepScreenOn(state.keepScreenAwake);
    if (isClosed) return;
    _startTimerFromPreset(emit);
    _persistSettings();
  }

  Future<void> _startSequence(
    Emitter<FlashLightState> emit,
    LightMode mode,
    List<LightStep> steps,
  ) async {
    if (steps.isEmpty || state.activeLight == mode) return;

    // SOS and strobe need the torch. Morse can fall back to the screen.
    final useTorch = state.isAvailable;
    if (!useTorch && mode != LightMode.morse) return;

    if (state.activeLight != null) {
      final stopped = await _stopActiveLight(emit);
      if (!stopped) return;
    }

    emit(
      state.copyWith(
        activeLight: mode,
        selectedMode: mode,
        isBusy: false,
        error: null,
        sequencePaused: false,
      ),
    );

    _externallyActivated = false;
    await _deviceControls.setKeepScreenOn(state.keepScreenAwake);
    if (isClosed) return;

    _startTimerFromPreset(emit);
    _playSequence(mode, steps, useTorch: useTorch);
    _persistSettings();
  }

  void _playSequence(
    LightMode mode,
    List<LightStep> steps, {
    required bool useTorch,
  }) {
    unawaited(
      _sequencePlayer.play(
        steps: steps,
        useTorch: useTorch,
        repeat: mode != LightMode.morse,
        onComplete: () {
          if (!isClosed) add(SequenceCompleted(mode));
        },
        onError: (failure) {
          if (!isClosed) add(SequenceFailed(mode: mode, failure: failure));
        },
      ),
    );
  }

  Future<void> _pauseSequence(Emitter<FlashLightState> emit) async {
    if (!state.isSequenceActive || state.sequencePaused) return;

    if (_nativePatternActive) {
      final paused = await _deviceControls.pauseTorchMode();
      if (isClosed || !paused) return;
    } else {
      await _sequencePlayer.pause();
      if (isClosed) return;
    }

    _cancelTimer();
    emit(state.copyWith(sequencePaused: true, timerSecondsRemaining: null));
  }

  Future<void> _resumeSequence(Emitter<FlashLightState> emit) async {
    if (!state.isSequenceActive || !state.sequencePaused) return;

    if (_nativePatternActive) {
      final resumed = await _deviceControls.resumeTorchMode();
      if (isClosed || !resumed) return;
    } else {
      _sequencePlayer.resume();
    }
    emit(state.copyWith(sequencePaused: false));
    _startTimerFromPreset(emit);
  }

  void _setScreenColor(Emitter<FlashLightState> emit, int value) {
    final color = LightingDefaults.opaqueColor(value);
    if (state.screenColorValue == color) return;

    emit(state.copyWith(screenColorValue: color));
    _persistSettings();
  }

  Future<void> _setScreenBrightness(
    Emitter<FlashLightState> emit,
    double value,
  ) async {
    final brightness = LightingDefaults.clampBrightness(value);
    if (state.screenBrightness == brightness) return;

    emit(state.copyWith(screenBrightness: brightness));
    if (state.isScreenLightOn) {
      await _deviceControls.setScreenBrightness(brightness);
    }
    _persistSettings();
  }

  Future<void> _setTorchLevel(
    Emitter<FlashLightState> emit,
    double value,
  ) async {
    final level = LightingDefaults.clampTorchLevel(value);
    if (state.torchLevel == level) return;

    emit(state.copyWith(torchLevel: level));
    if (state.isTorchOn && state.isTorchLevelSupported) {
      await _deviceControls.setTorchLevel(level);
    }
    _persistSettings();
  }

  Future<void> _setStrobeInterval(
    Emitter<FlashLightState> emit,
    int milliseconds,
  ) async {
    final interval = LightingDefaults.clampStrobeInterval(milliseconds);
    if (state.strobeIntervalMs == interval) return;

    emit(state.copyWith(strobeIntervalMs: interval));

    // Native playback (including a pattern started from the notification)
    // reads this mirrored value, so update it even when the Dart fallback runs.
    await _deviceControls.setStrobeIntervalPreference(interval);
    if (isClosed) return;

    if (_nativePatternActive && state.activeLight == LightMode.strobe) {
      // The native player rebuilt its schedule from the preference above.
    } else if (state.activeLight == LightMode.strobe) {
      _playSequence(
        LightMode.strobe,
        StrobePattern.build(interval),
        useTorch: state.isAvailable,
      );
    }
    _persistSettings();
  }

  void _setAutoOffTimer(Emitter<FlashLightState> emit, int? minutes) {
    final preset = minutes == null || minutes <= 0
        ? null
        : minutes.clamp(1, LightingDefaults.maxCustomTimerMinutes);

    _cancelTimer();
    emit(
      state.copyWith(timerPresetMinutes: preset, timerSecondsRemaining: null),
    );

    if (preset != null && state.activeLight != null) {
      emit(state.copyWith(timerSecondsRemaining: preset * 60));
      _startTicker();
    }
    _persistSettings();
  }

  void _startTimerFromPreset(Emitter<FlashLightState> emit) {
    final preset = state.timerPresetMinutes;
    if (preset == null || state.timerSecondsRemaining != null) return;

    emit(state.copyWith(timerSecondsRemaining: preset * 60));
    _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(_autoOffTick, (_) {
      if (!isClosed) add(const AutoOffTick());
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _onAutoOffTick(Emitter<FlashLightState> emit) async {
    final remaining = state.timerSecondsRemaining;
    if (remaining == null) {
      _cancelTimer();
      return;
    }

    if (state.activeLight == null) {
      _cancelTimer();
      emit(state.copyWith(timerSecondsRemaining: null));
      return;
    }

    if (remaining <= 1) {
      _cancelTimer();
      emit(state.copyWith(timerSecondsRemaining: null));
      await _stopActiveLight(emit, keepTimer: true);
      return;
    }

    emit(state.copyWith(timerSecondsRemaining: remaining - 1));
  }

  Future<void> _onSequenceCompleted(
    Emitter<FlashLightState> emit,
    LightMode mode,
  ) async {
    if (state.activeLight != mode) return;

    _cancelTimer();
    await _deviceControls.setKeepScreenOn(false);
    if (isClosed) return;

    emit(
      state.copyWith(
        activeLight: null,
        sequencePaused: false,
        timerSecondsRemaining: null,
      ),
    );
  }

  Future<void> _onSequenceFailed(
    Emitter<FlashLightState> emit,
    LightMode mode,
    TorchFailure failure,
  ) async {
    if (state.activeLight != mode) return;

    _cancelTimer();
    await _deviceControls.setKeepScreenOn(false);
    if (isClosed) return;

    final unavailable = failure.kind == TorchFailureKind.unavailable;
    emit(
      state.copyWith(
        activeLight: null,
        sequencePaused: false,
        timerSecondsRemaining: null,
        availability: unavailable
            ? TorchAvailability.unavailable
            : state.availability,
        error: unavailable ? null : failure,
      ),
    );
  }

  /// Stops whatever is active. Returns false when the hardware refused to turn
  /// off, so the caller does not start a conflicting mode.
  Future<bool> _stopActiveLight(
    Emitter<FlashLightState> emit, {
    bool keepTimer = false,
  }) async {
    final active = state.activeLight;
    if (active == null) {
      if (_nativePatternActive) {
        _nativePatternActive = false;
        await _deviceControls.stopTorchMode();
      }
      await _stopBackgroundServiceIfIdle(emit);
      if (!keepTimer) {
        _cancelTimer();
        if (state.timerSecondsRemaining != null) {
          emit(state.copyWith(timerSecondsRemaining: null));
        }
      }
      return true;
    }

    if (active.isSequence) {
      if (_nativePatternActive) {
        _nativePatternActive = false;
        await _deviceControls.stopTorchMode();
        if (isClosed) return true;
      } else {
        await _sequencePlayer.stop();
        if (isClosed) return true;
      }

      _cancelTimer();
      await _deviceControls.setKeepScreenOn(false);
      if (isClosed) return true;

      emit(
        state.copyWith(
          activeLight: null,
          isBusy: false,
          sequencePaused: false,
          timerSecondsRemaining: null,
        ),
      );
      await _stopBackgroundServiceIfIdle(emit);
      return true;
    }

    if (active == LightMode.screenLight) {
      if (!keepTimer) _cancelTimer();
      await _deviceControls.restoreScreenBrightness();
      await _deviceControls.setKeepScreenOn(false);
      if (isClosed) return true;

      emit(
        state.copyWith(
          activeLight: null,
          isBusy: false,
          timerSecondsRemaining: null,
        ),
      );
      await _stopBackgroundServiceIfIdle(emit);
      return true;
    }

    if (_nativePatternActive) {
      // Defensive: the native mode flag and activeLight should agree, but a
      // stop must always release whichever owner holds the torch.
      _nativePatternActive = false;
      await _deviceControls.stopTorchMode();
      if (isClosed) return true;
    }

    emit(state.copyWith(isBusy: true));

    try {
      _externallyActivated = false;
      await torchService.disable();
      if (isClosed) return true;

      if (!keepTimer) _cancelTimer();
      await _deviceControls.setKeepScreenOn(false);
      if (isClosed) return true;

      emit(
        state.copyWith(
          activeLight: null,
          isBusy: false,
          error: null,
          timerSecondsRemaining: null,
        ),
      );
      if (state.backgroundTorchActive) {
        // An explicit stop always tears the foreground service down unless
        // shake monitoring still needs it, so no notification or background
        // process outlives every requested feature.
        await _stopBackgroundServiceIfIdle(emit);
      }
      return true;
    } on TorchFailure catch (failure) {
      if (isClosed) return true;

      if (failure.kind == TorchFailureKind.unavailable) {
        if (!keepTimer) _cancelTimer();
        emit(
          state.copyWith(
            availability: TorchAvailability.unavailable,
            isBusy: false,
            activeLight: null,
            timerSecondsRemaining: null,
          ),
        );
        if (state.backgroundTorchActive) {
          await _stopBackgroundServiceIfIdle(emit);
        }
        return true;
      }

      // The hardware may still be on; keep the last known state and surface an
      // actionable error instead of claiming the torch is off.
      emit(state.copyWith(isBusy: false, error: failure));
      return false;
    } catch (_) {
      if (isClosed) return true;

      emit(
        state.copyWith(
          isBusy: false,
          error: const TorchFailure(TorchFailureKind.unexpected),
        ),
      );
      return false;
    }
  }

  Future<void> _handlePaused(Emitter<FlashLightState> emit) async {
    _isResumed = false;
    // Only the Dart fallback stops. The native monitor intentionally keeps
    // running so shakes still toggle the torch without a visible UI.
    _syncShakeDetection();

    // Native SOS/strobe runs inside the foreground service and must survive
    // the UI leaving the foreground.
    if (_nativePatternActive) {
      _cancelTimer();
      if (state.timerSecondsRemaining != null) {
        emit(state.copyWith(timerSecondsRemaining: null));
      }
      return;
    }

    // Background mode intentionally keeps only the steady torch alive. SOS,
    // strobe, and Morse are driven by Dart timers, and the screen light needs
    // a visible screen, so they stop safely instead of leaving a stuck torch.
    if (state.backgroundTorchEnabled && state.isTorchOn) {
      return;
    }

    if (_externallyActivated && state.isTorchOn) {
      _cancelTimer();
      if (state.timerSecondsRemaining != null) {
        emit(state.copyWith(timerSecondsRemaining: null));
      }
      return;
    }

    _cancelTimer();
    if (state.activeLight == null) {
      if (state.timerSecondsRemaining != null) {
        emit(state.copyWith(timerSecondsRemaining: null));
      }
      return;
    }
    await _stopActiveLight(emit);
  }

  /// Keeps the steady torch alive through Activity detach when the user opted
  /// into background mode. Otherwise the existing best-effort cleanup runs.
  Future<void> _handleDetached(Emitter<FlashLightState> emit) async {
    _cancelTimer();
    final keepSteadyTorch = state.backgroundTorchEnabled && state.isTorchOn;
    final keepNativePattern = _nativePatternActive;
    final keepService =
        keepSteadyTorch || keepNativePattern || state.shakeEnabled;
    try {
      await _sequencePlayer.stop();
      if (!keepNativePattern &&
          state.isTorchOn &&
          !_externallyActivated &&
          !keepSteadyTorch) {
        await torchService.disable().timeout(const Duration(milliseconds: 800));
      }
      if (state.isScreenLightOn) {
        await _deviceControls.restoreScreenBrightness();
      }
      await _deviceControls.setKeepScreenOn(false);
      if (!keepService) {
        await _backgroundTorchService.stop();
      }
    } catch (_) {
      // Nothing actionable remains during shutdown.
    }

    if (isClosed) return;
    emit(
      state.copyWith(
        activeLight: keepSteadyTorch || keepNativePattern
            ? state.activeLight
            : (_externallyActivated ? state.activeLight : null),
        isBusy: false,
        sequencePaused: false,
        timerSecondsRemaining: null,
        backgroundTorchActive: keepService,
      ),
    );
  }

  Future<void> _setBackgroundTorch(
    Emitter<FlashLightState> emit,
    bool enabled,
  ) async {
    if (state.backgroundTorchEnabled == enabled) return;
    if (enabled && !state.backgroundTorchSupported) return;

    emit(state.copyWith(backgroundTorchEnabled: enabled));
    _persistSettings();
    await _backgroundTorchService.setBackgroundPreference(enabled);
    if (isClosed) return;

    if (!enabled) {
      await _stopBackgroundServiceIfIdle(emit);
      return;
    }

    // Android 13+ needs notification permission for the Turn OFF action.
    // Denial does not disable the light; it only hides the shade action.
    _notificationPermissionRequested = true;
    final granted = await _backgroundTorchService
        .requestNotificationPermission();
    if (isClosed) return;
    emit(state.copyWith(backgroundNotificationsEnabled: granted));

    if (state.isTorchOn) {
      await _ensureBackgroundService(emit);
    }
  }

  Future<void> _ensureBackgroundService(Emitter<FlashLightState> emit) async {
    if (!state.backgroundTorchSupported ||
        !state.backgroundTorchEnabled ||
        !state.isTorchOn) {
      return;
    }

    // Ask once per session while a user action is on screen, so the required
    // notification and its Turn OFF action can actually be shown on Android 13+.
    if (!state.backgroundNotificationsEnabled &&
        !_notificationPermissionRequested) {
      _notificationPermissionRequested = true;
      final granted = await _backgroundTorchService
          .requestNotificationPermission();
      if (isClosed) return;
      emit(state.copyWith(backgroundNotificationsEnabled: granted));
    }

    final result = await _backgroundTorchService.start();
    if (isClosed) return;

    emit(
      state.copyWith(
        backgroundTorchActive: result.started,
        backgroundNotificationsEnabled: result.notificationsEnabled,
      ),
    );
  }

  Future<void> _stopBackgroundService(Emitter<FlashLightState> emit) async {
    await _backgroundTorchService.stop();
    if (isClosed) return;
    if (state.backgroundTorchActive) {
      emit(state.copyWith(backgroundTorchActive: false));
    }
  }

  /// Keeps the single foreground service alive while any feature still needs
  /// it: a background flashlight, shake monitoring, or a native pattern.
  Future<void> _stopBackgroundServiceIfIdle(
    Emitter<FlashLightState> emit,
  ) async {
    final needed =
        (state.backgroundTorchEnabled && state.isTorchOn) ||
        state.shakeEnabled ||
        _nativePatternActive;
    if (needed || !state.backgroundTorchActive) return;
    await _stopBackgroundService(emit);
  }

  Future<void> _handleBackgroundServiceStatus(
    Emitter<FlashLightState> emit,
    BackgroundTorchStatus status,
  ) async {
    final active = status == BackgroundTorchStatus.running;
    if (state.backgroundTorchActive != active) {
      emit(state.copyWith(backgroundTorchActive: active));
    }

    if (status != BackgroundTorchStatus.running) {
      // The service or its Stop action may have changed the hardware while
      // Flutter was not looking. Reconcile without toggling.
      await _syncNativeTorchState(emit);
    }
  }

  Future<void> _syncNativeTorchState(Emitter<FlashLightState> emit) async {
    // A native pattern alternates the hardware, so one read is not a state.
    if (state.isBusy || state.isSequenceActive || _nativePatternActive) return;

    bool nativeOn;
    try {
      nativeOn = await torchService.isOn();
    } catch (_) {
      return;
    }
    if (isClosed) return;
    await _handleExternalTorchState(emit, nativeOn);
  }

  Future<void> _syncBackgroundService(Emitter<FlashLightState> emit) async {
    if (!state.backgroundTorchSupported) return;

    final steadyTorch = state.backgroundTorchEnabled && state.isTorchOn;
    final shouldRun = steadyTorch || state.shakeEnabled || _nativePatternActive;
    if (!shouldRun) {
      await _stopBackgroundServiceIfIdle(emit);
      return;
    }

    bool running = false;
    try {
      running = await _backgroundTorchService.isRunning();
    } catch (_) {
      running = false;
    }
    if (isClosed) return;

    if (!running) {
      // The app is visible again, so Android permits starting the service.
      if (steadyTorch) {
        await _ensureBackgroundService(emit);
      } else {
        final result = await _backgroundTorchService.start();
        if (isClosed) return;
        emit(
          state.copyWith(
            backgroundTorchActive: result.started,
            backgroundNotificationsEnabled: result.notificationsEnabled,
          ),
        );
      }
      return;
    }

    if (!state.backgroundTorchActive) {
      emit(state.copyWith(backgroundTorchActive: true));
    }
  }

  void _persistSettings() {
    unawaited(_saveSettings());
  }

  Future<void> _saveSettings() async {
    try {
      await _settingsRepository.save(
        AppSettings(
          selectedMode: state.selectedMode,
          screenColorValue: state.screenColorValue,
          screenBrightness: state.screenBrightness,
          torchLevel: state.torchLevel,
          strobeIntervalMs: state.strobeIntervalMs,
          timerPresetMinutes: state.timerPresetMinutes,
          appLanguage: state.appLanguage,
          hapticsEnabled: state.hapticsEnabled,
          shakeEnabled: state.shakeEnabled,
          shakeSensitivity: state.shakeSensitivity,
          keepScreenAwake: state.keepScreenAwake,
          reduceAnimations: state.reduceAnimations,
          backgroundTorchEnabled: state.backgroundTorchEnabled,
        ),
      );
    } catch (_) {
      // Persistence is best effort and must never break lighting controls.
    }
  }

  @override
  Future<void> close() async {
    _cancelTimer();
    final keepSteadyTorch = state.backgroundTorchEnabled && state.isTorchOn;
    final keepNativePattern = _nativePatternActive;
    final keepService =
        keepSteadyTorch || keepNativePattern || state.shakeEnabled;
    try {
      await _sequencePlayer.stop();
      if (state.isScreenLightOn) {
        await _deviceControls.restoreScreenBrightness();
      }
      if (!keepNativePattern &&
          state.isTorchOn &&
          !_externallyActivated &&
          !keepSteadyTorch) {
        await torchService.disable();
      }
      await _deviceControls.setKeepScreenOn(false);
      if (!keepService) {
        await _backgroundTorchService.stop();
      }
    } catch (_) {
      // Closing must not throw; the OS also forces the torch off.
    }
    await shakeService?.dispose();
    await _torchStateSubscription?.cancel();
    await _backgroundServiceSubscription?.cancel();
    await _shakeSubscription?.cancel();
    // The native monitor is intentionally not stopped here: it must outlive
    // the Flutter engine so shake still toggles the torch when the UI closes.
    await _shakeMonitorSubscription?.cancel();
    await _nativeControlsSubscription?.cancel();
    _sequencePlayer.dispose();
    return super.close();
  }
}
