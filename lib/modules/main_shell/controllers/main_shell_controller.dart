import 'package:get/get.dart';

import '../../../core/services/app_update_service.dart';
import '../../../routes/app_routes.dart';

enum MainTab { home, history, reports, profile }

class MainShellController extends GetxController {
  final tab = MainTab.home.obs;

  @override
  void onReady() {
    super.onReady();
    // Give the home screen a moment to settle before checking the store.
    Future.delayed(const Duration(seconds: 3), () {
      if (!isClosed && Get.isRegistered<AppUpdateService>()) Get.find<AppUpdateService>().checkOnLaunch();
    });
  }

  void changeTab(MainTab value) => tab.value = value;

  void startScan() => Get.toNamed(AppRoutes.scanGuide);

  /// Android back: return to Home before leaving the app.
  bool handleBack() {
    if (tab.value == MainTab.home) return true;
    tab.value = MainTab.home;
    return false;
  }
}
