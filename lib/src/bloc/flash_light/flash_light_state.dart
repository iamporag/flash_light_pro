part of 'flash_light_bloc.dart';

class FlashLightState extends Equatable {
  final bool isFlashOn;
  final String? error;
  const FlashLightState({
    required this.isFlashOn,
    this.error,
  });

  FlashLightState copyWith({
    bool? isFlashOn,
    String? error,
  }) {
    return FlashLightState(
      isFlashOn: isFlashOn ?? this.isFlashOn,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isFlashOn, error];
}
