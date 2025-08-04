part of 'flash_light_bloc.dart';

sealed class FlashLightEvent extends Equatable {
  const FlashLightEvent();

  @override
  List<Object> get props => [];
}

class TurnOnFlashLight extends FlashLightEvent {}
class TurnOffFlashLight extends FlashLightEvent {}