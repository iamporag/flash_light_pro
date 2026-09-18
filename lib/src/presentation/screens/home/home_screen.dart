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
    return Scaffold(
      body: BlocListener<FlashLightBloc, FlashLightState>(
        listener: (context, state) {
          if (state.error != null) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Flashlight Error"),
                content: Text(state.error!),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);

                      // 🔥 CLEAR ERROR AFTER SHOW
                      context
                          .read<FlashLightBloc>()
                          .add(ClearFlashLightError());
                    },
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
        },
        child: BlocBuilder<FlashLightBloc, FlashLightState>(
          builder: (context, state) {
            return AnimatedContainer(
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              width: double.infinity,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: state.isFlashOn
                      ? [
                          Color.fromARGB(255, 67, 76, 129),
                          Color.fromARGB(255, 63, 75, 152),
                          Color.fromARGB(255, 77, 118, 174),
                        ]
                      : [
                          Color(0xFF0D1441),
                          Color(0xFF283584),
                          Color(0xFF376AB2),
                        ],
                ),
              ),
              child: Stack(
                children: [
                  Sun(
                      duration: const Duration(seconds: 1),
                      isFullSun: state.isFlashOn),
                  Bg(),
                  _content(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, FlashLightState state) {
    return Align(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 50),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Text(
                state.isFlashOn ? "Flash Light On" : "Flash Light Off",
                style: TextStyle(
                  color: state.isFlashOn ? Colors.red : Colors.grey,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: -3.14 / 2,
            child: Transform.scale(
              scale: 2,
              child: Switch(
                value: state.isFlashOn,
                onChanged: (_) {
                  context.read<FlashLightBloc>().add(
                        state.isFlashOn
                            ? TurnOffFlashLight()
                            : TurnOnFlashLight(),
                      );
                },
              ),
<<<<<<< HEAD
            ),
=======
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
                            activeThumbColor: Colors.amber,
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
>>>>>>> 36c12e2 (--)
          ),
        ],
      ),
    );
  }
}
