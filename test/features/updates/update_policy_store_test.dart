import 'package:flash_light_pro/features/updates/data/update_policy_store.dart';
import 'package:flash_light_pro/features/updates/domain/update_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const store = SharedPreferencesUpdatePolicyStore();
  final verifiedAt = DateTime.fromMillisecondsSinceEpoch(1_760_000_000_000);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('trusted policy cache', () {
    test('is empty when nothing was stored', () async {
      expect(await store.loadTrustedPolicy(), isNull);
    });

    test('round-trips a verified policy', () async {
      await store.saveTrustedPolicy(
        TrustedUpdatePolicy(
          urgency: UpdateUrgency.mandatory,
          verifiedAt: verifiedAt,
          availableVersionCode: 42,
          updatePriority: 5,
        ),
      );

      final loaded = await store.loadTrustedPolicy();

      expect(loaded, isNotNull);
      expect(loaded!.urgency, UpdateUrgency.mandatory);
      expect(loaded.verifiedAt, verifiedAt);
      expect(loaded.availableVersionCode, 42);
      expect(loaded.updatePriority, 5);
    });

    test('supports a policy without a known version code', () async {
      await store.saveTrustedPolicy(
        TrustedUpdatePolicy(
          urgency: UpdateUrgency.recommended,
          verifiedAt: verifiedAt,
        ),
      );

      final loaded = await store.loadTrustedPolicy();

      expect(loaded!.urgency, UpdateUrgency.recommended);
      expect(loaded.availableVersionCode, isNull);
      expect(loaded.updatePriority, 0);
    });

    test('clearing removes every policy field', () async {
      await store.saveTrustedPolicy(
        TrustedUpdatePolicy(
          urgency: UpdateUrgency.mandatory,
          verifiedAt: verifiedAt,
          availableVersionCode: 42,
          updatePriority: 5,
        ),
      );

      await store.clearTrustedPolicy();

      expect(await store.loadTrustedPolicy(), isNull);
    });

    test('ignores an unknown urgency or a missing timestamp', () async {
      SharedPreferences.setMockInitialValues({
        'updates.policy.urgency': 'surprise',
        'updates.policy.verified_at': verifiedAt.millisecondsSinceEpoch,
      });
      expect(await store.loadTrustedPolicy(), isNull);

      SharedPreferences.setMockInitialValues({
        'updates.policy.urgency': 'mandatory',
      });
      expect(await store.loadTrustedPolicy(), isNull);
    });

    test('never caches the none urgency', () async {
      await store.saveTrustedPolicy(
        TrustedUpdatePolicy(
          urgency: UpdateUrgency.none,
          verifiedAt: verifiedAt,
        ),
      );

      expect(await store.loadTrustedPolicy(), isNull);
    });
  });

  group('dismissal and throttling', () {
    test('round-trips the dismissed version code', () async {
      expect(await store.loadDismissedVersionCode(), isNull);

      await store.saveDismissedVersionCode(11);

      expect(await store.loadDismissedVersionCode(), 11);
    });

    test('round-trips the last check timestamp', () async {
      expect(await store.loadLastCheckAt(), isNull);

      await store.saveLastCheckAt(verifiedAt);

      expect(await store.loadLastCheckAt(), verifiedAt);
    });

    test('a fresh install has no thundering-herd timestamp', () async {
      expect(await store.loadLastCheckAt(), isNull);
      expect(await store.loadDismissedVersionCode(), isNull);
    });
  });
}
