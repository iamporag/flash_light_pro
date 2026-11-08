import 'package:flash_light_pro/features/lighting/domain/light_mode.dart';
import 'package:flash_light_pro/l10n/app_localizations.dart';

String modeChipLabel(LightMode mode, AppLocalizations l10n) => switch (mode) {
  LightMode.torch => l10n.modeTorch,
  LightMode.screenLight => l10n.modeScreen,
  LightMode.sos => l10n.modeSos,
  LightMode.strobe => l10n.modeStrobe,
  LightMode.morse => l10n.modeMorse,
};

String modeDisplayName(LightMode mode, AppLocalizations l10n) => switch (mode) {
  LightMode.torch => l10n.modeFlashlight,
  LightMode.screenLight => l10n.modeScreenLight,
  LightMode.sos => l10n.modeSosSignal,
  LightMode.strobe => l10n.modeStrobe,
  LightMode.morse => l10n.modeMorsePlayback,
};
