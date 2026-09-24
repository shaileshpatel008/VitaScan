import 'package:get/get.dart';

import '../../../routes/app_routes.dart';

enum MainTab { home, history, reports, profile }

class MainShellController extends GetxController {
  final tab = MainTab.home.obs;

  void changeTab(MainTab value) => tab.value = value;

  void startScan() => Get.toNamed(AppRoutes.scanGuide);

  /// Android back: return to Home before leaving the app.
  bool handleBack() {
    if (tab.value == MainTab.home) return true;
    tab.value = MainTab.home;
    return false;
  }
}
