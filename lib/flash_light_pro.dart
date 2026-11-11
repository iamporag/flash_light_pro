import 'package:flash_light_pro/features/device/services/device_controls.dart';
import 'package:flash_light_pro/features/device/services/native_controls.dart';
import 'package:flash_light_pro/features/flashlight/services/background_torch_service.dart';
import 'package:flash_light_pro/features/flashlight/services/torch_service.dart';
import 'package:flash_light_pro/core/config/admob/admob_config.dart';
import 'package:flash_light_pro/features/monetization/presentation/monetization_host.dart';
import 'package:flash_light_pro/features/sequences/services/sequence_player.dart';
import 'package:flash_light_pro/features/settings/data/settings_repository.dart';
import 'package:flash_light_pro/core/config/app_info.dart';
import 'package:flash_light_pro/features/shake/services/shake_monitor_service.dart';
import 'package:flash_light_pro/features/shake/services/shake_service.dart';
import 'package:flash_light_pro/features/updates/application/update_cubit.dart';
import 'package:flash_light_pro/features/updates/data/store_launcher.dart';
import 'package:flash_light_pro/features/updates/data/update_gateway.dart';
import 'package:flash_light_pro/features/updates/data/update_policy_store.dart';
import 'package:flash_light_pro/features/updates/domain/app_version.dart';
import 'package:flash_light_pro/features/updates/domain/update_config.dart';
import 'package:flash_light_pro/features/updates/presentation/update_gate.dart';
import 'package:flash_light_pro/l10n/app_localizations.dart';
import 'package:flash_light_pro/src/bloc/flash_light/flash_light_bloc.dart';
import 'package:flash_light_pro/src/presentation/screens/home/home_screen.dart';
import 'package:flash_light_pro/core/config/app_theme_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FlashLightPro extends StatelessWidget {
  const FlashLightPro({
    super.key,
    this.torchService,
    this.torchStateSource,
    this.backgroundTorchService,
    this.shakeService,
    this.shakeMonitorService,
    this.nativeControlsSource,
    this.deviceControls,
    this.settingsRepository,
    this.sequencePlayer,
    this.updateGateway,
    this.updatePolicyStore,
    this.storeLauncher,
    this.updateConfig = const UpdateConfig(),
    this.updateCurrentVersion,
    this.updateClock,
    this.monetization,
  });

  final TorchService? torchService;
  final TorchStateSource? torchStateSource;
  final BackgroundTorchService? backgroundTorchService;
  final ShakeService? shakeService;
  final ShakeMonitorService? shakeMonitorService;
  final NativeControlsSource? nativeControlsSource;
  final DeviceControls? deviceControls;
  final SettingsRepository? settingsRepository;
  final SequencePlayer? sequencePlayer;

  final UpdateGateway? updateGateway;
  final UpdatePolicyStore? updatePolicyStore;
  final StoreLauncher? storeLauncher;
  final UpdateConfig updateConfig;
  final AppVersion? updateCurrentVersion;
  final DateTime Function()? updateClock;

  /// Null keeps monetization disabled, which is the default for tests and for
  /// embedders that do not want ads.
  final AdConfig? monetization;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => FlashLightBloc(
            torchService: torchService ?? const MethodChannelTorchService(),
            torchStateSource:
                torchStateSource ?? EventChannelTorchStateSource(),
            backgroundTorchService: backgroundTorchService,
            shakeService: shakeService ?? SensorShakeService(),
            shakeMonitorService: shakeMonitorService,
            nativeControlsSource:
                nativeControlsSource ?? MethodChannelNativeControls(),
            deviceControls:
                deviceControls ?? const MethodChannelDeviceControls(),
            settingsRepository:
                settingsRepository ??
                const SharedPreferencesSettingsRepository(),
            sequencePlayer: sequencePlayer,
          ),
        ),
        BlocProvider(
          create: (context) => UpdateCubit(
            gateway: updateGateway ?? const PlayUpdateGateway(),
            store:
                updatePolicyStore ?? const SharedPreferencesUpdatePolicyStore(),
            storeLauncher: storeLauncher ?? const UrlStoreLauncher(),
            config: updateConfig,
            currentVersion:
                updateCurrentVersion ??
                AppVersion.tryParse(AppInfo.fullVersion) ??
                const AppVersion(0, 0, 0),
            clock: updateClock,
          ),
        ),
      ],
      child: MonetizationHost(
        config: monetization,
        child: BlocBuilder<FlashLightBloc, FlashLightState>(
          buildWhen: (previous, current) =>
              previous.appLanguage != current.appLanguage ||
              previous.reduceAnimations != current.reduceAnimations,
          builder: (context, state) => MaterialApp(
            onGenerateTitle: (context) => AppLocalizations.of(context).appName,
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            locale: Locale(state.appLanguage.languageCode),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: state.reduceAnimations
                    ? media.copyWith(disableAnimations: true)
                    : media,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: UpdateGate(config: updateConfig, child: const HomeScreen()),
          ),
        ),
      ),
    );
  }
}
