import 'package:get/get.dart';

import '../../history/controllers/history_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../reports/controllers/reports_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/main_shell_controller.dart';

class MainShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(MainShellController.new);
    Get.lazyPut(() => HomeController(Get.find(), Get.find(), Get.find()));
    Get.lazyPut(() => HistoryController(Get.find()));
    Get.lazyPut(() => ReportsController(Get.find(), Get.find(), Get.find()));
    Get.lazyPut(
      () => SettingsController(
        users: Get.find(),
        settings: Get.find(),
        readings: Get.find(),
        calibration: Get.find(),
        backup: Get.find(),
        storage: Get.find(),
        notifications: Get.find(),
        health: Get.find(),
        export: Get.find(),
      ),
    );
  }
}
