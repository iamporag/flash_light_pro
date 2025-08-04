// ignore_for_file: dead_code, no_leading_underscores_for_local_identifiers

import 'package:flash_light_pro/src/bloc/flash_light/flash_light_bloc.dart';
import 'package:flash_light_pro/src/presentation/screens/home/widgets/bg.dart';
import 'package:flash_light_pro/src/presentation/screens/home/widgets/sun.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Duration _duration = Duration(seconds: 1);

    List<Color> lightBgColors = [
      Color.fromARGB(255, 67, 76, 129),
      Color.fromARGB(255, 63, 75, 152),
      Color.fromARGB(255, 77, 118, 174),
    ];
    var darkBgColors = [
      Color(0xFF0D1441),
      Color(0xFF283584),
      Color(0xFF376AB2),
    ];

    return Scaffold(body: BlocBuilder<FlashLightBloc, FlashLightState>(
      builder: (context, state) {
        return AnimatedContainer(
          duration: _duration,
          curve: Curves.easeInOut,
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: state.isFlashOn ? lightBgColors : darkBgColors,
            ),
          ),
          child: Stack(
            children: [
              Sun(
                duration: _duration,
                isFullSun: state.isFlashOn,
              ),
              Bg(),
              Align(
                alignment: Alignment.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 50.0),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.grey.shade900.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8.0)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            state.isFlashOn
                                ? "Flash Light On"
                                : "Flash Light Off",
                            style: TextStyle(
                              color: state.isFlashOn ? Colors.red : Colors.grey,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Transform.rotate(
                        angle: -3.14 / 2,
                        child: Transform.scale(
                          scale: 2.0,
                          child: Switch(
                            activeColor: Colors.amber,
                            activeTrackColor: Color(0xFF0D1441),
                            trackOutlineColor:
                                WidgetStatePropertyAll(Colors.grey.shade500),
                            // thumbColor: WidgetStatePropertyAll(
                            //   Colors.grey.shade500,
                            // ),
                            // trackColor: WidgetStatePropertyAll(
                            //   Colors.grey.shade900,
                            // ),
                            // trackOutlineColor: WidgetStatePropertyAll(
                            //   Colors.grey.shade500,
                            // ),
                            value: state.isFlashOn,
                            onChanged: (value) {
                              if (state.isFlashOn) {
                                context
                                    .read<FlashLightBloc>()
                                    .add(TurnOffFlashLight());
                              } else {
                                context
                                    .read<FlashLightBloc>()
                                    .add(TurnOnFlashLight());
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    ));
  }
}
