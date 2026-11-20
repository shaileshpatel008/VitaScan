import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/utils/premium_policy.dart';
import '../../../data/models/store_product.dart';
import '../../../routes/app_routes.dart';

class PremiumController extends GetxController {
  PremiumController(this.purchases);

  final PurchaseService purchases;
  final selected = Rxn<StoreProduct>();

  late final Worker _productsWorker;

  @override
  void onInit() {
    super.onInit();
    _productsWorker = ever<List<StoreProduct>>(purchases.products, (_) => _selectDefault());
    _selectDefault();
    if (purchases.products.isEmpty) purchases.loadProducts();
  }

  void _selectDefault() {
    if (selected.value != null && purchases.products.contains(selected.value)) return;
    selected.value = purchases.products.isEmpty ? null : purchases.products.first; // yearly first
  }

  void select(StoreProduct p) => selected.value = p;

  /// "Save 40%" for the yearly plan compared with paying monthly for a year.
  int? yearlySavingsPercent() {
    StoreProduct? find(PremiumPlan p) => purchases.products.firstWhereOrNull((x) => x.plan == p);
    final monthly = find(PremiumPlan.monthly), yearly = find(PremiumPlan.yearly);
    if (monthly == null || yearly == null || monthly.priceMicros <= 0) return null;
    final percent = (100 - yearly.priceMicros * 100 / (monthly.priceMicros * 12)).round();
    return percent >= 5 ? percent : null;
  }

  Future<void> buy() async {
    final p = selected.value;
    if (p != null) await purchases.buy(p);
  }

  void startScan() => Get.offNamed(AppRoutes.scanGuide);

  void openTerms() => launchUrl(Uri.parse(AppConstants.termsUrl), mode: LaunchMode.externalApplication);

  void openPrivacy() => launchUrl(Uri.parse(AppConstants.privacyPolicyUrl), mode: LaunchMode.externalApplication);

  @override
  void onClose() {
    _productsWorker.dispose();
    super.onClose();
  }
}
