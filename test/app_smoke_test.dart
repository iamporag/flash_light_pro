import 'package:flash_light_pro/flash_light_pro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/flashlight/fake_device_controls.dart';
import 'features/flashlight/fake_settings_repository.dart';
import 'features/flashlight/fake_torch_service.dart';

void main() {
  testWidgets('renders the lighting home screen', (tester) async {
    await tester.pumpWidget(
      FlashLightPro(
        torchService: FakeTorchService(),
        deviceControls: FakeDeviceControls(),
        settingsRepository: FakeSettingsRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flash Light Pro'), findsOneWidget);
    expect(find.text('Flash Light Off'), findsOneWidget);
    expect(find.byKey(const Key('power-button')), findsOneWidget);
    expect(find.byKey(const Key('mode-torch')), findsOneWidget);
    expect(find.byKey(const Key('mode-screenLight')), findsOneWidget);
    expect(find.byKey(const Key('mode-sos')), findsOneWidget);
    expect(find.byKey(const Key('mode-strobe')), findsOneWidget);
    expect(find.byKey(const Key('mode-morse')), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });
}
