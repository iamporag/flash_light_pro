import 'package:flash_light_pro/features/monetization/application/ad_free_entitlement_service.dart';
import 'package:flash_light_pro/features/monetization/domain/monetization_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

class _Fixture {
  _Fixture({
    bool owned = false,
    FakeBillingGateway? billing,
    this.purchaseTimeout = const Duration(minutes: 10),
  }) : store = FakeAdFreeStore(owned: owned),
       gateway = billing ?? FakeBillingGateway();

  final FakeAdFreeStore store;
  final FakeBillingGateway gateway;
  final Duration purchaseTimeout;
  late final AdFreeEntitlementService service = AdFreeEntitlementService(
    store: store,
    gateway: gateway,
    restoreGrace: Duration.zero,
    purchaseTimeout: purchaseTimeout,
  );

  Future<void> load({bool reconcileSilently = false}) {
    return service.initialize(reconcileSilently: reconcileSilently);
  }
}

void main() {
  test('the cached entitlement applies immediately at startup', () async {
    final fixture = _Fixture(owned: true);
    await fixture.load();

    expect(fixture.service.isAdFree, isTrue);
    expect(fixture.service.phase, RemoveAdsPhase.purchased);
  });

  test('the store price is exposed exactly as the store returned it', () async {
    final fixture = _Fixture();
    await fixture.load();

    expect(fixture.service.localizedPrice, r'US$4.99');
    expect(fixture.service.product?.id, AdFreeEntitlementService.productId);
    expect(fixture.service.phase, RemoveAdsPhase.ready);
    expect(fixture.service.canPurchase, isTrue);
  });

  test(
    'a purchase is not reported as successful before confirmation',
    () async {
      final fixture = _Fixture();
      await fixture.load();

      await fixture.service.purchase();

      expect(fixture.gateway.bought, [AdFreeEntitlementService.productId]);
      expect(fixture.service.phase, RemoveAdsPhase.purchasing);
      expect(fixture.service.isAdFree, isFalse);
    },
  );

  test('a confirmed purchase grants the entitlement once', () async {
    final fixture = _Fixture();
    await fixture.load();
    await fixture.service.purchase();

    fixture.gateway.emit(status: BillingPurchaseStatus.purchased);
    await pumpEventQueue();

    expect(fixture.service.isAdFree, isTrue);
    expect(fixture.service.phase, RemoveAdsPhase.purchased);
    expect(fixture.store.owned, isTrue);
    expect(fixture.store.saves, 1);
  });

  test(
    'duplicate purchase events neither double-save nor skip completion',
    () async {
      final fixture = _Fixture();
      await fixture.load();

      fixture.gateway.emit(status: BillingPurchaseStatus.purchased);
      fixture.gateway.emit(status: BillingPurchaseStatus.purchased);
      await pumpEventQueue();

      expect(fixture.store.saves, 1);
      expect(fixture.gateway.completed, hasLength(2));
    },
  );

  test('a pending purchase keeps the entitlement locked', () async {
    final fixture = _Fixture();
    await fixture.load();
    await fixture.service.purchase();

    fixture.gateway.emit(status: BillingPurchaseStatus.pending);
    await pumpEventQueue();

    expect(fixture.service.phase, RemoveAdsPhase.pending);
    expect(fixture.service.isAdFree, isFalse);

    fixture.gateway.emit(status: BillingPurchaseStatus.purchased);
    await pumpEventQueue();
    expect(fixture.service.isAdFree, isTrue);
  });

  test('a canceled purchase returns to a buyable state', () async {
    final fixture = _Fixture();
    await fixture.load();
    await fixture.service.purchase();

    fixture.gateway.emit(status: BillingPurchaseStatus.canceled);
    await pumpEventQueue();

    expect(fixture.service.isAdFree, isFalse);
    expect(fixture.service.phase, RemoveAdsPhase.ready);
    expect(fixture.service.notice, RemoveAdsNotice.purchaseCanceled);
    expect(fixture.service.canPurchase, isTrue);
  });

  test(
    'a cancel reported without a product id still clears the purchase',
    () async {
      final fixture = _Fixture();
      await fixture.load();
      await fixture.service.purchase();

      // Google Play reports a cancelled billing flow with an empty product ID.
      fixture.gateway.emit(
        status: BillingPurchaseStatus.canceled,
        productId: '',
      );
      await pumpEventQueue();

      expect(fixture.service.phase, RemoveAdsPhase.ready);
      expect(fixture.service.notice, RemoveAdsNotice.purchaseCanceled);
      expect(fixture.service.canPurchase, isTrue);
    },
  );

  test('a product-less event outside a purchase is ignored', () async {
    final fixture = _Fixture();
    await fixture.load();

    fixture.gateway.emit(status: BillingPurchaseStatus.canceled, productId: '');
    fixture.gateway.emit(status: BillingPurchaseStatus.error, productId: '');
    await pumpEventQueue();

    expect(fixture.service.phase, RemoveAdsPhase.ready);
    expect(fixture.service.notice, RemoveAdsNotice.none);
  });

  test('a billing flow that never answers stops waiting', () async {
    final fixture = _Fixture(purchaseTimeout: const Duration(milliseconds: 5));
    await fixture.load();

    await fixture.service.purchase();
    expect(fixture.service.phase, RemoveAdsPhase.purchasing);

    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(fixture.service.phase, RemoveAdsPhase.failed);
    expect(fixture.service.notice, RemoveAdsNotice.purchaseFailed);
    expect(fixture.service.canPurchase, isTrue);
  });

  test('a store error fails the purchase instead of faking success', () async {
    final fixture = _Fixture();
    await fixture.load();
    await fixture.service.purchase();

    fixture.gateway.emit(status: BillingPurchaseStatus.error);
    await pumpEventQueue();

    expect(fixture.service.isAdFree, isFalse);
    expect(fixture.service.phase, RemoveAdsPhase.failed);
    expect(fixture.service.notice, RemoveAdsNotice.purchaseFailed);
  });

  test('a buy call failure is reported honestly', () async {
    final fixture = _Fixture(billing: FakeBillingGateway()..failBuy = true);
    await fixture.load();

    await fixture.service.purchase();

    expect(fixture.service.isAdFree, isFalse);
    expect(fixture.service.phase, RemoveAdsPhase.failed);
    expect(fixture.service.notice, RemoveAdsNotice.purchaseFailed);
  });

  test('a restored purchase grants the entitlement', () async {
    final fixture = _Fixture();
    await fixture.load();

    final restore = fixture.service.restore();
    fixture.gateway.emit(status: BillingPurchaseStatus.restored);
    await restore;
    await pumpEventQueue();

    expect(fixture.gateway.restoreCount, 1);
    expect(fixture.service.isAdFree, isTrue);
    expect(fixture.service.phase, RemoveAdsPhase.purchased);
  });

  test('restore with no purchase reports that nothing was found', () async {
    final fixture = _Fixture();
    await fixture.load();

    await fixture.service.restore();
    await pumpEventQueue();

    expect(fixture.service.isAdFree, isFalse);
    expect(fixture.service.phase, RemoveAdsPhase.ready);
    expect(fixture.service.notice, RemoveAdsNotice.noPurchaseFound);
  });

  test(
    'a failed restore is reported without changing the entitlement',
    () async {
      final fixture = _Fixture(
        billing: FakeBillingGateway()..failRestore = true,
      );
      await fixture.load();

      await fixture.service.restore();

      expect(fixture.service.isAdFree, isFalse);
      expect(fixture.service.phase, RemoveAdsPhase.failed);
      expect(fixture.service.notice, RemoveAdsNotice.restoreFailed);
    },
  );

  test('an unsupported store disables purchases gracefully', () async {
    final fixture = _Fixture(billing: FakeBillingGateway(supported: false));
    await fixture.load();

    expect(fixture.service.isStoreSupported, isFalse);
    expect(fixture.service.phase, RemoveAdsPhase.unavailable);
    expect(fixture.service.notice, RemoveAdsNotice.storeUnavailable);
    expect(fixture.service.canPurchase, isFalse);
  });

  test('a missing product is retryable and never sells anything', () async {
    final fixture = _Fixture(billing: FakeBillingGateway(product: null));
    await fixture.load();

    expect(fixture.service.phase, RemoveAdsPhase.unavailable);
    expect(fixture.service.notice, RemoveAdsNotice.productNotFound);
    expect(fixture.service.canRetryStore, isTrue);
    expect(fixture.service.canPurchase, isFalse);
  });

  test('a store query error is reported as unavailable', () async {
    final fixture = _Fixture(
      billing: FakeBillingGateway(product: null)
        ..queryError = 'store_connection_failed',
    );
    await fixture.load();

    expect(fixture.service.phase, RemoveAdsPhase.unavailable);
    expect(fixture.service.notice, RemoveAdsNotice.storeUnavailable);
    expect(fixture.service.canRetryStore, isTrue);
  });

  test('retrying the store can recover a missing product', () async {
    final fixture = _Fixture(billing: FakeBillingGateway(product: null));
    await fixture.load();
    expect(fixture.service.canRetryStore, isTrue);

    fixture.gateway.product = testRemoveAdsProduct;
    await fixture.service.refreshProduct();

    expect(fixture.service.phase, RemoveAdsPhase.ready);
    expect(fixture.service.localizedPrice, r'US$4.99');
    expect(fixture.service.canPurchase, isTrue);
  });

  test('events for another product are ignored', () async {
    final fixture = _Fixture();
    await fixture.load();

    fixture.gateway.emit(
      status: BillingPurchaseStatus.purchased,
      productId: 'some_other_product',
    );
    await pumpEventQueue();

    expect(fixture.service.isAdFree, isFalse);
    expect(fixture.store.saves, 0);
  });

  test('dispose cancels the purchase subscription', () async {
    final fixture = _Fixture();
    await fixture.load();
    fixture.service.dispose();

    expect(fixture.gateway.disposed, isTrue);
  });
}
