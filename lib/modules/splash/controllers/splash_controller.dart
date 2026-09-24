import 'package:get/get.dart';

import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  SplashController(this._settings, this._users);

  final SettingsRepository _settings;
  final UserRepository _users;

  @override
  void onReady() {
    super.onReady();
    Future.delayed(const Duration(milliseconds: 1700), _route);
  }

  void _route() {
    final s = _settings.current;
    if (s.onboardingComplete && _users.hasProfile) {
      Get.offAllNamed(AppRoutes.main);
    } else if (_users.hasProfile) {
      Get.offAllNamed(AppRoutes.consent);
    } else {
      Get.offAllNamed(AppRoutes.welcome);
    }
  }
}
