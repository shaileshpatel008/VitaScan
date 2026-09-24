import 'package:get/get.dart';

import '../../../core/services/camera_ppg_service.dart';
import '../controllers/scan_controller.dart';

class ScanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(CameraPpgService.new);
    Get.lazyPut(
      () => ScanController(
        camera: Get.find(),
        readings: Get.find(),
        users: Get.find(),
        calibration: Get.find(),
        settings: Get.find(),
        health: Get.find(),
        permissions: Get.find(),
      ),
    );
  }
}
