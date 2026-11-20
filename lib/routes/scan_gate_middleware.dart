import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/services/purchase_service.dart';
import 'app_routes.dart';

/// Sends the user to the Premium screen once their free scans are used up.
/// Applied to every route that starts a scan.
class ScanGateMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<PurchaseService>()) return null;
    return Get.find<PurchaseService>().allowance.canScan ? null : const RouteSettings(name: AppRoutes.premium);
  }
}
