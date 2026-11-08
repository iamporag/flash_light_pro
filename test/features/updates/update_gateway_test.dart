import 'package:flash_light_pro/features/updates/data/update_gateway.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('the Play in-app update API is used only on Android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(const PlayUpdateGateway().isSupported, isTrue);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(const PlayUpdateGateway().isSupported, isFalse);

    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(const PlayUpdateGateway().isSupported, isFalse);
  });
}
