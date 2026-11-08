abstract final class LightingDefaults {
  static const int screenColorValue = 0xFFFFFFFF;
  static const double screenBrightness = 0.85;
  static const double minScreenBrightness = 0.05;
  static const double maxScreenBrightness = 1.0;

  static const double torchLevel = 1.0;

  static const int strobeIntervalMs = 400;
  static const int minStrobeIntervalMs = 200;
  static const int maxStrobeIntervalMs = 1000;

  static const List<int> timerPresets = [1, 5, 10, 15, 30, 60];
  static const int maxCustomTimerMinutes = 180;

  static const Duration sosUnit = Duration(milliseconds: 180);
  static const Duration morseUnit = Duration(milliseconds: 200);

  static double clampBrightness(double value) =>
      value.clamp(minScreenBrightness, maxScreenBrightness).toDouble();

  static double clampTorchLevel(double value) =>
      value.clamp(0.0, 1.0).toDouble();

  static int clampStrobeInterval(int value) =>
      value.clamp(minStrobeIntervalMs, maxStrobeIntervalMs);

  static int opaqueColor(int value) => (value & 0xFFFFFF) | 0xFF000000;

  static double strobeFrequencyHz(int intervalMs) =>
      1000 / clampStrobeInterval(intervalMs);
}
