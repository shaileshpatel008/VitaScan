import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Eager: SplashView never reads `controller`, so a lazyPut would never be
    // created and onReady (which navigates onward) would never fire.
    Get.put(SplashController(Get.find(), Get.find()));
  }
}
