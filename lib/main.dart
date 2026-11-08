import 'package:flash_light_pro/features/flashlight/services/background_torch_service.dart';
import 'package:flash_light_pro/features/monetization/domain/ad_config.dart';
import 'package:flash_light_pro/features/shake/services/shake_monitor_service.dart';
import 'package:flash_light_pro/flash_light_pro.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    FlashLightPro(
      backgroundTorchService: MethodChannelBackgroundTorchService(),
      shakeMonitorService: MethodChannelShakeMonitorService(),
      monetization: AdConfig.fromEnvironment(),
    ),
  );
}
