/// Configuration for the one-time Remove Ads purchase.
///
/// Product identity and timing values live here only. User-facing purchase
/// text is localized in the ARB files, and the Google Play Billing
/// implementation, verification, persistence, restore, and cancellation
/// handling are unchanged.
abstract final class PurchaseConfig {
  /// Lifetime Remove Ads product ID. It must match the product configured in
  /// Google Play Console.
  static const String removeAdsProductId = 'flash_light_pro_remove_ads';

  /// How long a store restore may take to report restored purchases before the
  /// app concludes the account owns nothing.
  static const Duration restoreGrace = Duration(seconds: 2);

  /// Safety net for a billing flow that never reports back. Without it an
  /// unanswered flow would leave the purchase card spinning forever.
  static const Duration purchaseTimeout = Duration(minutes: 10);
}
