import 'package:flash_light_pro/features/settings/data/app_settings.dart';
import 'package:flash_light_pro/features/settings/data/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([this.settings = const AppSettings()]);

  AppSettings settings;
  int loadCalls = 0;
  final List<AppSettings> saved = [];

  @override
  Future<AppSettings> load() async {
    loadCalls++;
    return settings;
  }

  @override
  Future<void> save(AppSettings settings) async {
    saved.add(settings);
    this.settings = settings;
  }
}
