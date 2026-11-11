/// Store-facing details for the lifetime Remove Ads purchase.
class RemoveAdsProduct {
  const RemoveAdsProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currencyCode,
  });

  final String id;
  final String title;
  final String description;

  /// Localized, formatted price supplied by the store.
  final String price;
  final String currencyCode;
}

enum BillingPurchaseStatus { pending, purchased, restored, canceled, error }

/// A purchase event mapped out of the platform purchase stream so the
/// monetization layer does not depend on `in_app_purchase` types.
class BillingPurchase {
  const BillingPurchase({
    required this.productId,
    required this.status,
    required this.needsCompletion,
    this.raw,
  });

  final String productId;
  final BillingPurchaseStatus status;

  /// Whether the store requires `completePurchase` before the transaction can
  /// be finalised. Always honoured, including for duplicate deliveries.
  final bool needsCompletion;
  final Object? raw;
}

enum RemoveAdsPhase {
  loading,
  ready,
  purchasing,
  pending,
  restoring,
  purchased,
  unavailable,
  failed,
}

enum RemoveAdsNotice {
  none,
  purchaseFailed,
  purchaseCanceled,
  restoreFailed,
  storeUnavailable,
  productNotFound,
  noPurchaseFound,
}
