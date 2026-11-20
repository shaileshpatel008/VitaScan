import '../constants/app_constants.dart';

enum PremiumPlan {
  none(''),
  monthly('Monthly'),
  yearly('Yearly'),
  lifetime('Lifetime');

  const PremiumPlan(this.label);
  final String label;

  bool get isActive => this != PremiumPlan.none;
  bool get isSubscription => this == PremiumPlan.monthly || this == PremiumPlan.yearly;

  static PremiumPlan fromProductId(String id) => switch (id) {
    AppConstants.premiumMonthlyId => PremiumPlan.monthly,
    AppConstants.premiumYearlyId => PremiumPlan.yearly,
    AppConstants.premiumLifetimeId => PremiumPlan.lifetime,
    _ => PremiumPlan.none,
  };

  /// Best plan among the product IDs the user currently owns
  /// (lifetime beats yearly beats monthly).
  static PremiumPlan fromOwned(Iterable<String> productIds) {
    var best = PremiumPlan.none;
    for (final id in productIds) {
      final plan = fromProductId(id);
      if (plan.index > best.index) best = plan;
    }
    return best;
  }

  static PremiumPlan fromName(String? name) =>
      PremiumPlan.values.firstWhere((p) => p.name == name, orElse: () => PremiumPlan.none);
}

/// Free-scan allowance before Premium is required.
class ScanAllowance {
  const ScanAllowance({required this.used, required this.isPremium, this.limit = AppConstants.freeScanLimit});

  final int used;
  final bool isPremium;
  final int limit;

  int get remaining => isPremium ? limit : (limit - used).clamp(0, limit);
  bool get canScan => isPremium || used < limit;
  bool get isLastFreeScan => !isPremium && used == limit - 1;
}

/// Turns a Play billing period (ISO 8601, e.g. "P1M", "P1Y", "P1W") into words.
String billingPeriodLabel(String isoPeriod) {
  final m = RegExp(r'^P(\d+)([DWMY])$').firstMatch(isoPeriod);
  if (m == null) return '';
  final n = int.parse(m.group(1)!);
  final unit = switch (m.group(2)) {
    'D' => 'day',
    'W' => 'week',
    'M' => 'month',
    _ => 'year',
  };
  return n == 1 ? unit : '$n ${unit}s';
}
