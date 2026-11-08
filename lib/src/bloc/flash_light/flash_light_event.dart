part of 'flash_light_bloc.dart';

sealed class FlashLightEvent extends Equatable {
  const FlashLightEvent();

  @override
  List<Object?> get props => const [];
}

class LoadSettings extends FlashLightEvent {
  const LoadSettings();
}

class CheckTorchAvailability extends FlashLightEvent {
  const CheckTorchAvailability({this.force = false});

  final bool force;

  @override
  List<Object?> get props => [force];
}

class SelectLightMode extends FlashLightEvent {
  const SelectLightMode(this.mode);

  final LightMode mode;

  @override
  List<Object?> get props => [mode];
}

class TurnOnFlashLight extends FlashLightEvent {
  const TurnOnFlashLight();
}

class TurnOffFlashLight extends FlashLightEvent {
  const TurnOffFlashLight();
}

class StartScreenLight extends FlashLightEvent {
  const StartScreenLight();
}

class StartSos extends FlashLightEvent {
  const StartSos();
}

class StartStrobe extends FlashLightEvent {
  const StartStrobe();
}

class StartMorse extends FlashLightEvent {
  const StartMorse(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

class PauseSequence extends FlashLightEvent {
  const PauseSequence();
}

class ResumeSequence extends FlashLightEvent {
  const ResumeSequence();
}

/// Stops the torch, screen light, or sequence, and cancels a running timer.
class StopActiveLight extends FlashLightEvent {
  const StopActiveLight();
}

class SetScreenLightColor extends FlashLightEvent {
  const SetScreenLightColor(this.value);

  final int value;

  @override
  List<Object?> get props => [value];
}

class SetScreenBrightness extends FlashLightEvent {
  const SetScreenBrightness(this.value);

  final double value;

  @override
  List<Object?> get props => [value];
}

class SetTorchLevel extends FlashLightEvent {
  const SetTorchLevel(this.value);

  final double value;

  @override
  List<Object?> get props => [value];
}

class SetStrobeInterval extends FlashLightEvent {
  const SetStrobeInterval(this.milliseconds);

  final int milliseconds;

  @override
  List<Object?> get props => [milliseconds];
}

class SetAutoOffTimer extends FlashLightEvent {
  const SetAutoOffTimer(this.minutes);

  final int? minutes;

  @override
  List<Object?> get props => [minutes];
}

class AutoOffTick extends FlashLightEvent {
  const AutoOffTick();
}

class SequenceCompleted extends FlashLightEvent {
  const SequenceCompleted(this.mode);

  final LightMode mode;

  @override
  List<Object?> get props => [mode];
}

class SequenceFailed extends FlashLightEvent {
  const SequenceFailed({required this.mode, required this.failure});

  final LightMode mode;
  final TorchFailure failure;

  @override
  List<Object?> get props => [mode, failure];
}

class ClearFlashLightError extends FlashLightEvent {
  const ClearFlashLightError();
}

/// The native torch state changed outside Flutter (Quick Settings tile, home
/// screen widget, or an App Intent).
class ExternalTorchStateChanged extends FlashLightEvent {
  const ExternalTorchStateChanged(this.isOn);

  final bool isOn;

  @override
  List<Object?> get props => [isOn];
}

class ShakeDetected extends FlashLightEvent {
  const ShakeDetected();
}

class SetAppLanguage extends FlashLightEvent {
  const SetAppLanguage(this.language);

  final AppLanguage language;

  @override
  List<Object?> get props => [language];
}

class SetHapticsEnabled extends FlashLightEvent {
  const SetHapticsEnabled(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

/// The native shake-monitor foreground service changed state or failed.
class ShakeMonitorStatusChanged extends FlashLightEvent {
  const ShakeMonitorStatusChanged(this.status);

  final ShakeMonitorStatus status;

  @override
  List<Object?> get props => [status];
}

class SetShakeEnabled extends FlashLightEvent {
  const SetShakeEnabled(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

class SetShakeSensitivity extends FlashLightEvent {
  const SetShakeSensitivity(this.sensitivity);

  final ShakeSensitivity sensitivity;

  @override
  List<Object?> get props => [sensitivity];
}

class SetKeepScreenAwake extends FlashLightEvent {
  const SetKeepScreenAwake(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

class SetReduceAnimations extends FlashLightEvent {
  const SetReduceAnimations(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

/// Enables or disables keeping the steady torch on in the background.
class SetBackgroundTorch extends FlashLightEvent {
  const SetBackgroundTorch(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

/// The native Android foreground service changed state or failed to start.
class BackgroundServiceStatusChanged extends FlashLightEvent {
  const BackgroundServiceStatusChanged(this.status);

  final BackgroundTorchStatus status;

  @override
  List<Object?> get props => [status];
}

/// The native Android control panel, tile, widget, or shake listener changed
/// the shared mode or shake state while Flutter may not have been looking.
class NativeControlsChanged extends FlashLightEvent {
  const NativeControlsChanged(this.snapshot);

  final NativeControlsSnapshot snapshot;

  @override
  List<Object?> get props => [snapshot];
}

/// Emitted when the app moves to the background.
class AppPaused extends FlashLightEvent {
  const AppPaused();
}

/// Emitted when the app returns to the foreground. Never turns the torch on.
class AppResumed extends FlashLightEvent {
  const AppResumed();
}

/// Emitted when the Flutter engine is detached; cleanup is best effort.
class AppDetached extends FlashLightEvent {
  const AppDetached();
}
