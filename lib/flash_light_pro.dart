// ignore_for_file: deprecated_member_use

import 'package:device_preview/device_preview.dart';
import 'package:flash_light_pro/src/bloc/flash_light/flash_light_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/presentation/screens/home/home_screen.dart';

class FlashLightPro extends StatelessWidget {
  const FlashLightPro({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FlashLightBloc(),
      child: MaterialApp(
        useInheritedMediaQuery: true,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.grey.shade900,
        ),
        home: HomeScreen(),
      ),
    );
  }
}
