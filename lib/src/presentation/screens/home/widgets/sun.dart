// ignore_for_file: unused_element

import 'package:flash_light_pro/src/utils/assets_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Sun extends StatelessWidget {
  final Duration duration;
  final bool isFullSun;

  const Sun({super.key, required this.duration, required this.isFullSun});

  @override
  Widget build(BuildContext context) {
    double getProportionateScreenHeight(double inputHeight) {
      double screenHeight = MediaQuery.of(context).size.height;
      // Our designer use iPhone 11 , that's why we use 896.0
      return (inputHeight / 896.0) * screenHeight;
    }

    double getProportionateScreenWidth(double inputWidth) {
      double? screenWidth = MediaQuery.of(context).size.height;
      // 414 is the layout width that designer use or you can say iPhone 11  width
      return (inputWidth / 414.0) * screenWidth;
    }

    return AnimatedPositioned(
      duration: duration,
      curve: Curves.easeInOut,
      left: getProportionateScreenWidth(28),
      bottom: getProportionateScreenWidth(!isFullSun ? -80 : 230),
      child: SvgPicture.asset(
        AssetsManager.MOON_ICON,
        width: 300,
      ),
    );
  }
}
