part of 'flash_light_bloc.dart';

enum TorchAvailability { unknown, checking, available, unavailable }

class FlashLightState extends Equatable {
  const FlashLightState({
    this.availability = TorchAvailability.unknown,
    this.isBusy = false,
    this.error,
    this.selectedMode = LightMode.torch,
    this.activeLight,
    this.screenColorValue = LightingDefaults.screenColorValue,
    this.screenBrightness = LightingDefaults.screenBrightness,
    this.torchLevel = LightingDefaults.torchLevel,
    this.isTorchLevelSupported = false,
    this.strobeIntervalMs = LightingDefaults.strobeIntervalMs,
    this.timerPresetMinutes,
    this.timerSecondsRemaining,
    this.sequencePaused = false,
    this.appLanguage = AppLanguage.english,
    this.hapticsEnabled = true,
    this.shakeEnabled = false,
    this.shakeSensitivity = ShakeSensitivity.medium,
    this.shakeMonitoringSupported = false,
    this.shakeMonitoringActive = false,
    this.shakeNotificationsEnabled = true,
    this.keepScreenAwake = true,
    this.reduceAnimations = false,
    this.backgroundTorchEnabled = true,
    this.backgroundTorchSupported = false,
    this.backgroundNotificationsEnabled = true,
    this.backgroundTorchActive = false,
  }) : assert(
         activeLight != LightMode.torch ||
             availability == TorchAvailability.available ||
             availability == TorchAvailability.checking,
         'The torch cannot be on while availability is unknown or unavailable.',
       ),
       assert(
         screenBrightness >= LightingDefaults.minScreenBrightness &&
             screenBrightness <= LightingDefaults.maxScreenBrightness,
         'Screen brightness is out of range.',
       ),
       assert(
         torchLevel >= 0.0 && torchLevel <= 1.0,
         'Torch level is out of range.',
       ),
       assert(
         strobeIntervalMs >= LightingDefaults.minStrobeIntervalMs &&
             strobeIntervalMs <= LightingDefaults.maxStrobeIntervalMs,
         'Strobe interval is out of range.',
       ),
       assert(
         timerSecondsRemaining == null || timerSecondsRemaining >= 0,
         'Timer seconds cannot be negative.',
       );

  final TorchAvailability availability;
  final bool isBusy;
  final TorchFailure? error;

  /// Which mode panel the user is viewing.
  final LightMode selectedMode;

  /// The single light currently active, or null when everything is off.
  final LightMode? activeLight;

  final int screenColorValue;
  final double screenBrightness;
  final double torchLevel;
  final bool isTorchLevelSupported;
  final int strobeIntervalMs;

  /// Last preset chosen, kept even after a timer completes or is cancelled.
  final int? timerPresetMinutes;
  final int? timerSecondsRemaining;
  final bool sequencePaused;

  final AppLanguage appLanguage;
  final bool hapticsEnabled;
  final bool shakeEnabled;
  final ShakeSensitivity shakeSensitivity;

  /// Android-only native accelerometer monitor. False on iOS and on Android
  /// versions or devices without the foreground service or a sensor.
  final bool shakeMonitoringSupported;

  /// Whether the native shake service is running, including while the Flutter
  /// UI is closed.
  final bool shakeMonitoringActive;

  /// Android 13+ notification permission for the monitoring notification.
  final bool shakeNotificationsEnabled;

  final bool keepScreenAwake;
  final bool reduceAnimations;

  /// User preference: keep the steady torch on when the app is backgrounded.
  final bool backgroundTorchEnabled;

  /// False on iOS and Android versions without the foreground service.
  final bool backgroundTorchSupported;

  /// Android 13+ notification permission, which enables the Stop action.
  final bool backgroundNotificationsEnabled;

  /// Whether the native foreground service is currently running.
  final bool backgroundTorchActive;

  bool get isAvailable => availability == TorchAvailability.available;

  bool get isTorchOn => activeLight == LightMode.torch;

  bool get isScreenLightOn => activeLight == LightMode.screenLight;

  bool get isSequenceActive => activeLight?.isSequence ?? false;

  bool get isTimerActive => timerSecondsRemaining != null;

  bool get isLoading =>
      availability == TorchAvailability.unknown ||
      availability == TorchAvailability.checking ||
      isBusy;

  static const Object _unset = Object();

  FlashLightState copyWith({
    TorchAvailability? availability,
    bool? isBusy,
    Object? error = _unset,
    LightMode? selectedMode,
    Object? activeLight = _unset,
    int? screenColorValue,
    double? screenBrightness,
    double? torchLevel,
    bool? isTorchLevelSupported,
    int? strobeIntervalMs,
    Object? timerPresetMinutes = _unset,
    Object? timerSecondsRemaining = _unset,
    bool? sequencePaused,
    AppLanguage? appLanguage,
    bool? hapticsEnabled,
    bool? shakeEnabled,
    ShakeSensitivity? shakeSensitivity,
    bool? shakeMonitoringSupported,
    bool? shakeMonitoringActive,
    bool? shakeNotificationsEnabled,
    bool? keepScreenAwake,
    bool? reduceAnimations,
    bool? backgroundTorchEnabled,
    bool? backgroundTorchSupported,
    bool? backgroundNotificationsEnabled,
    bool? backgroundTorchActive,
  }) {
    final nextAvailability = availability ?? this.availability;
    var nextActiveLight = identical(activeLight, _unset)
        ? this.activeLight
        : activeLight as LightMode?;

    // Keep the State invariant safe when availability is withdrawn.
    if (nextAvailability == TorchAvailability.unavailable &&
        nextActiveLight == LightMode.torch) {
      nextActiveLight = null;
    }

    return FlashLightState(
      availability: nextAvailability,
      isBusy: isBusy ?? this.isBusy,
      error: identical(error, _unset) ? this.error : error as TorchFailure?,
      selectedMode: selectedMode ?? this.selectedMode,
      activeLight: nextActiveLight,
      screenColorValue: screenColorValue ?? this.screenColorValue,
      screenBrightness: screenBrightness ?? this.screenBrightness,
      torchLevel: torchLevel ?? this.torchLevel,
      isTorchLevelSupported:
          isTorchLevelSupported ?? this.isTorchLevelSupported,
      strobeIntervalMs: strobeIntervalMs ?? this.strobeIntervalMs,
      timerPresetMinutes: identical(timerPresetMinutes, _unset)
          ? this.timerPresetMinutes
          : timerPresetMinutes as int?,
      timerSecondsRemaining: identical(timerSecondsRemaining, _unset)
          ? this.timerSecondsRemaining
          : timerSecondsRemaining as int?,
      sequencePaused: sequencePaused ?? this.sequencePaused,
      appLanguage: appLanguage ?? this.appLanguage,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      shakeEnabled: shakeEnabled ?? this.shakeEnabled,
      shakeSensitivity: shakeSensitivity ?? this.shakeSensitivity,
      shakeMonitoringSupported:
          shakeMonitoringSupported ?? this.shakeMonitoringSupported,
      shakeMonitoringActive:
          shakeMonitoringActive ?? this.shakeMonitoringActive,
      shakeNotificationsEnabled:
          shakeNotificationsEnabled ?? this.shakeNotificationsEnabled,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      backgroundTorchEnabled:
          backgroundTorchEnabled ?? this.backgroundTorchEnabled,
      backgroundTorchSupported:
          backgroundTorchSupported ?? this.backgroundTorchSupported,
      backgroundNotificationsEnabled:
          backgroundNotificationsEnabled ?? this.backgroundNotificationsEnabled,
      backgroundTorchActive:
          backgroundTorchActive ?? this.backgroundTorchActive,
    );
  }

  @override
  List<Object?> get props => [
    availability,
    isBusy,
    error,
    selectedMode,
    activeLight,
    screenColorValue,
    screenBrightness,
    torchLevel,
    isTorchLevelSupported,
    strobeIntervalMs,
    timerPresetMinutes,
    timerSecondsRemaining,
    sequencePaused,
    appLanguage,
    hapticsEnabled,
    shakeEnabled,
    shakeSensitivity,
    shakeMonitoringSupported,
    shakeMonitoringActive,
    shakeNotificationsEnabled,
    keepScreenAwake,
    reduceAnimations,
    backgroundTorchEnabled,
    backgroundTorchSupported,
    backgroundNotificationsEnabled,
    backgroundTorchActive,
  ];
}
