import 'package:flash_light_pro/features/updates/domain/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppVersion parsing', () {
    test('parses full semantic versions and build metadata', () {
      final version = AppVersion.tryParse('1.4.2+17');

      expect(version, isNotNull);
      expect(version!.major, 1);
      expect(version.minor, 4);
      expect(version.patch, 2);
      expect(version.build, 17);
      expect(version.toString(), '1.4.2+17');
    });

    test('pads missing segments', () {
      expect(AppVersion.tryParse('2')?.toString(), '2.0.0');
      expect(AppVersion.tryParse('2.3')?.toString(), '2.3.0');
    });

    test('ignores prerelease labels for precedence', () {
      final version = AppVersion.tryParse('1.2.3-beta.4');

      expect(version, isNotNull);
      expect(version.toString(), '1.2.3');
    });

    test('rejects invalid values', () {
      for (final value in <String>[
        '',
        ' ',
        'abc',
        '1.x.0',
        '1.2.3.4',
        '-1.2.3',
        '1.2.3+beta',
        '1.2.3+',
      ]) {
        expect(AppVersion.tryParse(value), isNull, reason: value);
      }
    });
  });

  group('AppVersion comparison', () {
    test('orders older, same, and newer versions', () {
      final older = AppVersion.tryParse('1.2.3')!;
      final same = AppVersion.tryParse('1.2.3')!;
      final newer = AppVersion.tryParse('1.2.4')!;

      expect(older.compareTo(same), 0);
      expect(older.compareTo(newer), lessThan(0));
      expect(newer.compareTo(older), greaterThan(0));
      expect(older.isOlderThan(newer), isTrue);
      expect(newer.isOlderThan(older), isFalse);
    });

    test('compares build numbers only when both are present', () {
      final buildOne = AppVersion.tryParse('1.2.3+1')!;
      final buildTwo = AppVersion.tryParse('1.2.3+2')!;
      final noBuild = AppVersion.tryParse('1.2.3')!;

      expect(buildOne.compareTo(buildTwo), 0);
      expect(buildOne.isOlderThan(buildTwo), isTrue);
      expect(buildTwo.isOlderThan(buildOne), isFalse);
      expect(buildOne.isOlderThan(noBuild), isFalse);
      expect(noBuild.isOlderThan(buildOne), isFalse);
    });

    test('a minimum version with a build number is enforced', () {
      final installed = AppVersion.tryParse('1.2.3+4')!;
      final minimum = AppVersion.tryParse('1.2.3+5')!;

      expect(installed.isOlderThan(minimum), isTrue);
    });
  });
}
