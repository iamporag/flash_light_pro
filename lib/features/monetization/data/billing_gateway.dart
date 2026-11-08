import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../application/ad_diagnostics.dart';
import '../domain/monetization_models.dart';

/// Billing boundary. The production implementation wraps `in_app_purchase`;
/// tests substitute a controllable fake.
abstract class BillingGateway {
  bool get isSupported;

  Stream<BillingPurchase> get purchases;

  Future<bool> isAvailable();

  /// Returns null when the store has no matching product or cannot be reached.
  Future<RemoveAdsProduct?> queryProduct(String productId);

  /// Error from the most recent product query, or null when the query reached
  /// the store and the product is simply not configured there.
  String? get lastQueryError;

  Future<void> buy(String productId);

  Future<void> restore();

  Future<void> complete(BillingPurchase purchase);

  Future<void> dispose();
}

class InAppPurchaseBillingGateway implements BillingGateway {
  InAppPurchaseBillingGateway() {
    if (isSupported) {
      _subscription = InAppPurchase.instance.purchaseStream.listen(
        _onPurchases,
        onError: (Object error) {
          AdDiagnostics.log('purchase stream error', error);
        },
      );
    }
  }

  final StreamController<BillingPurchase> _events =
      StreamController<BillingPurchase>.broadcast();
  final Map<String, ProductDetails> _details = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  String? _lastQueryError;

  @override
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Stream<BillingPurchase> get purchases => _events.stream;

  @override
  String? get lastQueryError => _lastQueryError;

  @override
  Future<bool> isAvailable() async {
    if (!isSupported) return false;
    try {
      final available = await InAppPurchase.instance.isAvailable();
      AdDiagnostics.log('store availability', available);
      return available;
    } catch (error) {
      AdDiagnostics.log('store availability check failed', error);
      return false;
    }
  }

  @override
  Future<RemoveAdsProduct?> queryProduct(String productId) async {
    _lastQueryError = null;
    if (!isSupported) {
      _lastQueryError = 'In-app purchases are not supported on this platform.';
      return null;
    }
    try {
      AdDiagnostics.log('product query started', productId);
      final response = await InAppPurchase.instance.queryProductDetails({
        productId,
      });
      final error = response.error;
      if (error != null) {
        _lastQueryError = '${error.code}: ${error.message}';
        AdDiagnostics.log('product query failed', _lastQueryError);
        return null;
      }
      if (response.productDetails.isEmpty) {
        AdDiagnostics.log(
          'product not found',
          'requested=$productId, notFound=${response.notFoundIDs.join(',')}',
        );
        return null;
      }

      final details = response.productDetails.first;
      _details[details.id] = details;
      AdDiagnostics.log('product query succeeded', details.id);
      return RemoveAdsProduct(
        id: details.id,
        title: details.title,
        description: details.description,
        price: details.price,
        currencyCode: details.currencyCode,
      );
    } catch (error) {
      _lastQueryError = error.toString();
      AdDiagnostics.log('product query threw', error);
      return null;
    }
  }

  @override
  Future<void> buy(String productId) async {
    var details = _details[productId];
    if (details == null) {
      await queryProduct(productId);
      details = _details[productId];
    }
    if (details == null) {
      throw StateError('The Remove Ads product is not available.');
    }

    AdDiagnostics.log('purchase started', productId);
    await InAppPurchase.instance.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
  }

  @override
  Future<void> restore() async {
    if (!isSupported) return;
    AdDiagnostics.log('restore started');
    await InAppPurchase.instance.restorePurchases();
  }

  @override
  Future<void> complete(BillingPurchase purchase) async {
    final raw = purchase.raw;
    if (raw is PurchaseDetails && raw.pendingCompletePurchase) {
      await InAppPurchase.instance.completePurchase(raw);
    }
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _events.close();
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (_events.isClosed) return;
      _events.add(
        BillingPurchase(
          productId: purchase.productID,
          status: switch (purchase.status) {
            PurchaseStatus.pending => BillingPurchaseStatus.pending,
            PurchaseStatus.purchased => BillingPurchaseStatus.purchased,
            PurchaseStatus.restored => BillingPurchaseStatus.restored,
            PurchaseStatus.canceled => BillingPurchaseStatus.canceled,
            PurchaseStatus.error => BillingPurchaseStatus.error,
          },
          needsCompletion: purchase.pendingCompletePurchase,
          raw: purchase,
        ),
      );
    }
  }
}
