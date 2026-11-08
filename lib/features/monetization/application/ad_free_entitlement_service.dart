import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/billing_gateway.dart';
import '../data/entitlement_store.dart';
import '../domain/monetization_models.dart';
import 'ad_diagnostics.dart';

/// Owns the lifetime Remove Ads entitlement state.
///
/// The local cache makes the app ad-free immediately at startup, but it is
/// never the only source of purchase truth: Android performs a silent restore
/// on launch and every platform exposes a user-initiated restore action.
class AdFreeEntitlementService extends ChangeNotifier {
  AdFreeEntitlementService({
    required this.store,
    required this.gateway,
    this.restoreGrace = const Duration(seconds: 2),
  });

  static const String productId = 'flash_light_pro_remove_ads';

  final AdFreeStore store;
  final BillingGateway gateway;
  final Duration restoreGrace;

  StreamSubscription<BillingPurchase>? _subscription;
  Timer? _restoreTimer;
  Future<void>? _initializeFuture;
  bool _localLoaded = false;
  bool _disposed = false;

  bool _isAdFree = false;
  RemoveAdsPhase _phase = RemoveAdsPhase.loading;
  RemoveAdsNotice _notice = RemoveAdsNotice.none;
  RemoveAdsProduct? _product;

  bool get isAdFree => _isAdFree;
  RemoveAdsPhase get phase => _phase;
  RemoveAdsNotice get notice => _notice;
  RemoveAdsProduct? get product => _product;
  String? get localizedPrice => _product?.price;
  bool get isStoreSupported => gateway.isSupported;

  bool get canPurchase =>
      !_isAdFree &&
      _product != null &&
      _phase != RemoveAdsPhase.purchasing &&
      _phase != RemoveAdsPhase.pending &&
      _phase != RemoveAdsPhase.restoring;

  bool get canRetryStore => !_isAdFree && _product == null && isStoreSupported;

  /// Loads the cached entitlement and starts listening for purchases. This is
  /// the only part of initialization that must finish before ads can start.
  Future<void> loadLocal() async {
    if (_localLoaded) return;
    _localLoaded = true;

    try {
      _isAdFree = await store.loadOwned();
    } catch (error) {
      AdDiagnostics.log('entitlement cache read failed', error);
      _isAdFree = false;
    }
    if (_disposed) return;
    AdDiagnostics.log('entitlement cache loaded', 'adFree=$_isAdFree');
    _subscription ??= gateway.purchases.listen(
      _handlePurchase,
      onError: _handleStreamError,
    );
    _notify();
  }

  /// Completes local loading and then reconciles with the store. Safe to call
  /// more than once; the store work runs once per service instance.
  Future<void> initialize({bool reconcileSilently = true}) {
    return _initializeFuture ??= _initialize(
      reconcileSilently: reconcileSilently,
    );
  }

  Future<void> _initialize({required bool reconcileSilently}) async {
    await loadLocal();
    if (_disposed) return;

    if (!gateway.isSupported) {
      _phase = RemoveAdsPhase.unavailable;
      _notice = RemoveAdsNotice.storeUnavailable;
      AdDiagnostics.log('store unsupported on this platform');
      _notify();
      return;
    }

    final available = await gateway.isAvailable();
    if (_disposed) return;
    if (!available) {
      _phase = RemoveAdsPhase.unavailable;
      _notice = RemoveAdsNotice.storeUnavailable;
      AdDiagnostics.log('store unavailable');
      _notify();
      return;
    }

    await refreshProduct();

    if (reconcileSilently &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      unawaited(_silentRestore());
    }
  }

  Future<void> refreshProduct() async {
    if (!gateway.isSupported) {
      _phase = RemoveAdsPhase.unavailable;
      _notice = RemoveAdsNotice.storeUnavailable;
      _notify();
      return;
    }

    _phase = _isAdFree ? RemoveAdsPhase.purchased : RemoveAdsPhase.loading;
    _notice = RemoveAdsNotice.none;
    _notify();

    final product = await gateway.queryProduct(productId);
    if (_disposed) return;

    _product = product;
    if (product == null) {
      _phase = _isAdFree
          ? RemoveAdsPhase.purchased
          : RemoveAdsPhase.unavailable;
      _notice = gateway.lastQueryError == null
          ? RemoveAdsNotice.productNotFound
          : RemoveAdsNotice.storeUnavailable;
      AdDiagnostics.log(
        'remove ads product unavailable',
        'notice=${_notice.name}, error=${gateway.lastQueryError ?? 'none'}',
      );
    } else {
      _phase = _isAdFree ? RemoveAdsPhase.purchased : RemoveAdsPhase.ready;
      _notice = RemoveAdsNotice.none;
      AdDiagnostics.log(
        'remove ads product ready',
        'price=${product.price} ${product.currencyCode}',
      );
    }
    _notify();
  }

  Future<void> purchase() async {
    if (!canPurchase) {
      AdDiagnostics.log(
        'purchase ignored',
        'phase=${_phase.name}, hasProduct=${_product != null}',
      );
      return;
    }

    _notice = RemoveAdsNotice.none;
    _phase = RemoveAdsPhase.purchasing;
    AdDiagnostics.log('purchase requested', productId);
    _notify();

    try {
      await gateway.buy(productId);
      // The store confirms through `purchases`; success is never assumed here.
    } catch (error) {
      AdDiagnostics.log('purchase failed to start', error);
      if (_disposed) return;
      _phase = RemoveAdsPhase.failed;
      _notice = RemoveAdsNotice.purchaseFailed;
      _notify();
    }
  }

  Future<void> restore() async {
    if (_phase == RemoveAdsPhase.restoring) return;
    if (!gateway.isSupported) {
      _phase = RemoveAdsPhase.unavailable;
      _notice = RemoveAdsNotice.storeUnavailable;
      _notify();
      return;
    }

    _notice = RemoveAdsNotice.none;
    _phase = RemoveAdsPhase.restoring;
    AdDiagnostics.log('restore requested');
    _notify();

    _restoreTimer?.cancel();
    try {
      await gateway.restore();
    } catch (error) {
      AdDiagnostics.log('restore failed to start', error);
      if (_disposed) return;
      _phase = RemoveAdsPhase.failed;
      _notice = RemoveAdsNotice.restoreFailed;
      _notify();
      return;
    }

    // The store reports restored purchases through the purchase stream. Give
    // it a moment before concluding that the account owns nothing.
    _restoreTimer = Timer(restoreGrace, () {
      if (_disposed || _phase != RemoveAdsPhase.restoring) return;
      _phase = _isAdFree ? RemoveAdsPhase.purchased : RemoveAdsPhase.ready;
      if (!_isAdFree) {
        _notice = RemoveAdsNotice.noPurchaseFound;
        AdDiagnostics.log('restore found no purchase');
      }
      _notify();
    });
  }

  Future<void> _silentRestore() async {
    try {
      await gateway.restore();
    } catch (_) {
      // Silent reconciliation must never surface UI or disturb the app.
    }
  }

  void _handlePurchase(BillingPurchase purchase) {
    if (_disposed || purchase.productId != productId) return;

    AdDiagnostics.log('purchase event', purchase.status.name);

    switch (purchase.status) {
      case BillingPurchaseStatus.pending:
        _phase = RemoveAdsPhase.pending;
        _notice = RemoveAdsNotice.none;
      case BillingPurchaseStatus.purchased:
      case BillingPurchaseStatus.restored:
        if (!_isAdFree) {
          _isAdFree = true;
          unawaited(store.saveOwned(true));
        }
        _phase = RemoveAdsPhase.purchased;
        _notice = RemoveAdsNotice.none;
      case BillingPurchaseStatus.canceled:
        if (_phase == RemoveAdsPhase.purchasing ||
            _phase == RemoveAdsPhase.restoring) {
          _phase = _isAdFree ? RemoveAdsPhase.purchased : RemoveAdsPhase.ready;
        }
      case BillingPurchaseStatus.error:
        if (_phase == RemoveAdsPhase.purchasing) {
          _phase = RemoveAdsPhase.failed;
          _notice = RemoveAdsNotice.purchaseFailed;
        } else if (_phase == RemoveAdsPhase.restoring) {
          _phase = RemoveAdsPhase.failed;
          _notice = RemoveAdsNotice.restoreFailed;
        }
    }

    // Always acknowledge the transaction, even for duplicate deliveries, so
    // Google Play never refunds or repeats it indefinitely.
    if (purchase.needsCompletion) {
      unawaited(_complete(purchase));
    }
    _notify();
  }

  Future<void> _complete(BillingPurchase purchase) async {
    try {
      await gateway.complete(purchase);
    } catch (error) {
      // The store retries completion on the next launch.
      AdDiagnostics.log('purchase completion failed', error);
    }
  }

  void _handleStreamError(Object error) {
    AdDiagnostics.log('purchase stream error', error);
    if (_disposed) return;
    if (_phase == RemoveAdsPhase.purchasing) {
      _phase = RemoveAdsPhase.failed;
      _notice = RemoveAdsNotice.purchaseFailed;
    } else if (_phase == RemoveAdsPhase.restoring) {
      _phase = RemoveAdsPhase.failed;
      _notice = RemoveAdsNotice.restoreFailed;
    } else {
      return;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _restoreTimer?.cancel();
    _restoreTimer = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(gateway.dispose());
    super.dispose();
  }
}
