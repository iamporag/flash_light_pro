import 'package:device_preview/device_preview.dart';
import 'package:flash_light_pro/flash_light_pro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    kDebugMode
        ? DevicePreview(
            enabled: true,
            devices: [
              ...Devices.android.all,
              ...Devices.ios.all,
            ],
            builder: (context) => const FlashLightPro(),
          )
        : const FlashLightPro(),
  );
}
