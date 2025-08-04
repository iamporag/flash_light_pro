// ignore_for_file: unused_element

import 'package:flash_light_pro/src/bloc/flash_light/flash_light_bloc.dart';
import 'package:flash_light_pro/src/utils/assets_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Bg extends StatelessWidget {
  const Bg({super.key});

  @override
  Widget build(BuildContext context) {

    
    double getProportionateScreenWidth(double inputWidth) {
  double? screenWidth = MediaQuery.of(context).size.height;
  // 414 is the layout width that designer use or you can say iPhone 11  width
  return (inputWidth / 414.0) * screenWidth;
}

    return BlocBuilder<FlashLightBloc,FlashLightState>(
      builder: (context, state) {
        return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SvgPicture.asset(
       state.isFlashOn ? AssetsManager.APP_BACKGROUND_ON : AssetsManager.APP_BACKGROUND_OFF,
        height: MediaQuery.of(context).size.height,
        fit: BoxFit.fitHeight,
      ),
    );
      },
    );
  }
}
