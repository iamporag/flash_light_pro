part of 'flash_light_bloc.dart';

class FlashLightState extends Equatable {
  final bool isFlashOn;
  const FlashLightState({required this.isFlashOn});

  FlashLightState copyWith({bool? isFlashOn}) {
    return FlashLightState(isFlashOn: isFlashOn ?? this.isFlashOn);
  }

  @override
  List<Object> get props => [isFlashOn];
}
