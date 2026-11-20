import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../core/utils/premium_policy.dart';

/// A purchasable Premium plan, with prices formatted by the store in the user's currency.
class StoreProduct {
  const StoreProduct({
    required this.details,
    required this.plan,
    required this.price,
    required this.priceMicros,
    required this.period,
    this.trial,
  });

  final ProductDetails details;
  final PremiumPlan plan;

  /// Recurring price for subscriptions (after any trial), one-time price for lifetime.
  final String price;
  final int priceMicros;

  /// "month" / "year" for subscriptions, empty for lifetime.
  final String period;

  /// e.g. "1 week free", when the store offers this user a free trial.
  final String? trial;

  String get id => details.id;

  factory StoreProduct.from(ProductDetails d) {
    final plan = PremiumPlan.fromProductId(d.id);
    if (d is GooglePlayProductDetails && d.subscriptionIndex != null) {
      final offer = d.productDetails.subscriptionOfferDetails![d.subscriptionIndex!];
      final phases = offer.pricingPhases;
      final recurring = phases.last;
      String? trial;
      if (phases.length > 1 && phases.first.priceAmountMicros == 0) {
        final p = phases.first;
        final label = billingPeriodLabel(p.billingPeriod);
        trial = label.isEmpty ? 'Free trial' : '$label free';
      }
      return StoreProduct(
        details: d,
        plan: plan,
        price: recurring.formattedPrice,
        priceMicros: recurring.priceAmountMicros,
        period: billingPeriodLabel(recurring.billingPeriod),
        trial: trial,
      );
    }
    return StoreProduct(
      details: d,
      plan: plan,
      price: d.price,
      priceMicros: (d.rawPrice * 1000000).round(),
      period: switch (plan) {
        PremiumPlan.monthly => 'month',
        PremiumPlan.yearly => 'year',
        _ => '',
      },
    );
  }

  /// Google Play returns one entry per eligible offer of a subscription. Keep one
  /// per product: a special offer (e.g. free trial) if the user qualifies,
  /// otherwise the base plan.
  static List<StoreProduct> pickBestOffers(List<ProductDetails> all) {
    final byId = <String, ProductDetails>{};
    for (final d in all) {
      final current = byId[d.id];
      if (current == null || (_hasOffer(d) && !_hasOffer(current))) byId[d.id] = d;
    }
    final products = byId.values.map(StoreProduct.from).where((p) => p.plan.isActive).toList()
      ..sort((a, b) => _order(a.plan).compareTo(_order(b.plan)));
    return products;
  }

  static bool _hasOffer(ProductDetails d) =>
      d is GooglePlayProductDetails &&
      d.subscriptionIndex != null &&
      d.productDetails.subscriptionOfferDetails![d.subscriptionIndex!].offerId != null;

  /// Paywall order: yearly (best value), monthly, lifetime.
  static int _order(PremiumPlan p) => switch (p) {
    PremiumPlan.yearly => 0,
    PremiumPlan.monthly => 1,
    PremiumPlan.lifetime => 2,
    PremiumPlan.none => 3,
  };
}
