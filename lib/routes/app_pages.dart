import 'package:get/get.dart';

import '../modules/calibration/bindings/calibration_binding.dart';
import '../modules/calibration/views/calibration_view.dart';
import '../modules/consent/bindings/consent_binding.dart';
import '../modules/consent/views/consent_view.dart';
import '../modules/main_shell/bindings/main_shell_binding.dart';
import '../modules/main_shell/views/main_shell_view.dart';
import '../modules/premium/bindings/premium_binding.dart';
import '../modules/premium/views/premium_view.dart';
import '../modules/profile_setup/bindings/profile_setup_binding.dart';
import '../modules/profile_setup/views/profile_setup_view.dart';
import '../modules/result/bindings/result_binding.dart';
import '../modules/result/views/result_view.dart';
import '../modules/scan/bindings/scan_binding.dart';
import '../modules/scan/views/poor_signal_view.dart';
import '../modules/scan/views/scan_view.dart';
import '../modules/scan_guide/views/scan_guide_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/welcome/views/welcome_view.dart';
import 'app_routes.dart';
import 'scan_gate_middleware.dart';

class AppPages {
  AppPages._();

  static const _fade = Transition.fadeIn;
  static const _slide = Transition.rightToLeftWithFade;
  static const _up = Transition.downToUp;

  static final pages = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.splash, page: () => const SplashView(), binding: SplashBinding(), transition: _fade),
    GetPage(name: AppRoutes.welcome, page: () => const WelcomeView(), transition: _fade),
    GetPage(
      name: AppRoutes.profileSetup,
      page: () => const ProfileSetupView(),
      binding: ProfileSetupBinding(),
      transition: _slide,
    ),
    GetPage(name: AppRoutes.consent, page: () => const ConsentView(), binding: ConsentBinding(), transition: _slide),
    GetPage(name: AppRoutes.main, page: () => const MainShellView(), binding: MainShellBinding(), transition: _fade),
    GetPage(
      name: AppRoutes.scanGuide,
      page: () => const ScanGuideView(),
      transition: _slide,
      middlewares: [ScanGateMiddleware()],
    ),
    GetPage(
      name: AppRoutes.scan,
      page: () => const ScanView(),
      binding: ScanBinding(),
      transition: _fade,
      middlewares: [ScanGateMiddleware()],
    ),
    GetPage(name: AppRoutes.premium, page: () => const PremiumView(), binding: PremiumBinding(), transition: _up),
    GetPage(name: AppRoutes.poorSignal, page: () => const PoorSignalView(), transition: _up),
    GetPage(name: AppRoutes.result, page: () => const ResultView(), binding: ResultBinding(), transition: _up),
    GetPage(
      name: AppRoutes.calibration,
      page: () => const CalibrationView(),
      binding: CalibrationBinding(),
      transition: _slide,
    ),
  ];
}
