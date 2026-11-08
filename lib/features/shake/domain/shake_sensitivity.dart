/// How hard the phone must be shaken before the torch toggles.
enum ShakeSensitivity {
  low(18.0),
  medium(13.0),
  high(8.5);

  const ShakeSensitivity(this.threshold);

  /// Acceleration magnitude in metres per second squared, excluding gravity.
  final double threshold;

  static ShakeSensitivity fromIndex(int? index) {
    if (index == null || index < 0 || index >= values.length) {
      return ShakeSensitivity.medium;
    }
    return values[index];
  }
}
