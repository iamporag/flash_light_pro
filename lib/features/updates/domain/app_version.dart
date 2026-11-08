/// A lenient semantic version value used for update policy comparisons.
///
/// Build metadata (`+N`) is parsed but ignored by [compareTo], matching semantic
/// version precedence. [isOlderThan] uses it when both sides declare a build.
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch, {this.build});

  final int major;
  final int minor;
  final int patch;
  final int? build;

  static AppVersion? tryParse(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return null;

    int? build;
    final plusIndex = value.indexOf('+');
    if (plusIndex >= 0) {
      final buildText = value.substring(plusIndex + 1);
      build = int.tryParse(buildText);
      if (build == null || build < 0) return null;
      value = value.substring(0, plusIndex);
    }

    final prereleaseIndex = value.indexOf('-');
    if (prereleaseIndex >= 0) {
      value = value.substring(0, prereleaseIndex);
    }

    final parts = value.split('.');
    if (parts.isEmpty || parts.length > 3) return null;

    final numbers = <int>[];
    for (final part in parts) {
      if (part.isEmpty) return null;
      final number = int.tryParse(part);
      if (number == null || number < 0) return null;
      numbers.add(number);
    }

    while (numbers.length < 3) {
      numbers.add(0);
    }

    return AppVersion(numbers[0], numbers[1], numbers[2], build: build);
  }

  /// Whether this installed version is below [minimum].
  ///
  /// When [minimum] includes a build number and the core versions match, the
  /// build numbers are compared as well.
  bool isOlderThan(AppVersion minimum) => compareIncludingBuild(minimum) < 0;

  int compareIncludingBuild(AppVersion other) {
    final core = compareTo(other);
    if (core != 0) return core;

    final thisBuild = build;
    final otherBuild = other.build;
    if (thisBuild == null || otherBuild == null) return 0;
    return thisBuild.compareTo(otherBuild);
  }

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  bool operator ==(Object other) =>
      other is AppVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch &&
      other.build == build;

  @override
  int get hashCode => Object.hash(major, minor, patch, build);

  @override
  String toString() {
    final value = '$major.$minor.$patch';
    return build == null ? value : '$value+$build';
  }
}
