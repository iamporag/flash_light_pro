import 'package:equatable/equatable.dart';

class LightStep extends Equatable {
  const LightStep({required this.isOn, required this.duration});

  final bool isOn;
  final Duration duration;

  @override
  List<Object?> get props => [isOn, duration];
}
