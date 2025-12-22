import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:torch_light/torch_light.dart';

part 'flash_light_event.dart';
part 'flash_light_state.dart';

class FlashLightBloc extends Bloc<FlashLightEvent, FlashLightState> {
  FlashLightBloc() : super(FlashLightState(isFlashOn: false)) {
    on<TurnOnFlashLight>(_onTurnOnFlashLight);
    on<TurnOffFlashLight>(_onTurnOffFlashLight);
    on<ClearFlashLightError>((event, emit) {
      emit(state.copyWith(error: null));
    });
  }

  Future<void> _onTurnOnFlashLight(
    TurnOnFlashLight event,
    Emitter<FlashLightState> emit,
  ) async {
    try {
      await TorchLight.enableTorch();
      emit(state.copyWith(isFlashOn: true, error: null));
    } catch (e) {
      emit(state.copyWith(
        isFlashOn: false,
        error: _mapTorchError(e),
      ));
    }
  }

  String _mapTorchError(Object e) {
    final msg = e.toString().toLowerCase();

    if (msg.contains('not available') ||
        msg.contains('no camera') ||
        msg.contains('torch')) {
      return "This device does not support flashlight";
    }

    return "Unable to use flashlight on this device";
  }

  Future<void> _onTurnOffFlashLight(
      TurnOffFlashLight event, Emitter<FlashLightState> emit) async {
    try {
      await TorchLight.disableTorch();
      emit(state.copyWith(isFlashOn: false));
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
