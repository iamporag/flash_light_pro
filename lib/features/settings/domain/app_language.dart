/// App language options. English is the default regardless of device locale;
/// the user can switch manually from Settings.
enum AppLanguage {
  english('en'),
  bengali('bn');

  const AppLanguage(this.languageCode);

  final String languageCode;

  static AppLanguage fromIndex(int? index) {
    if (index == null || index < 0 || index >= values.length) {
      return AppLanguage.english;
    }
    return values[index];
  }
}
