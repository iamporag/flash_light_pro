import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:torch_light/torch_light.dart';

part 'flash_light_event.dart';
part 'flash_light_state.dart';

class FlashLightBloc extends Bloc<FlashLightEvent, FlashLightState> {
  FlashLightBloc() : super(FlashLightState(isFlashOn: false)) {
    on<TurnOnFlashLight>(_onTurnOnFlashLight);
    on<TurnOffFlashLight>(_onTurnOffFlashLight);
  }

  Future<void> _onTurnOnFlashLight(TurnOnFlashLight event, Emitter<FlashLightState> emit) async{
     try {
       await TorchLight.enableTorch();
       emit(state.copyWith(isFlashOn: true));
     } catch (e) {
       throw Exception(e.toString());
     }
  }

  Future<void> _onTurnOffFlashLight(TurnOffFlashLight event, Emitter<FlashLightState> emit) async{
    try {
      await TorchLight.disableTorch();
      emit(state.copyWith(isFlashOn: false));
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
