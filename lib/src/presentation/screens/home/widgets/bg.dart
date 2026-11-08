import 'package:flash_light_pro/src/utils/assets_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Bg extends StatelessWidget {
  const Bg({super.key, required this.isFlashOn});

  final bool isFlashOn;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SvgPicture.asset(
        isFlashOn
            ? AssetsManager.appBackgroundOn
            : AssetsManager.appBackgroundOff,
        height: MediaQuery.of(context).size.height,
        fit: BoxFit.fitHeight,
      ),
    );
  }
}
