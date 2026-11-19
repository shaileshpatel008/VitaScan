import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wellumi/data/models/app_settings.dart';
import 'package:wellumi/data/models/user_profile.dart';
import 'package:wellumi/data/repositories/settings_repository.dart';
import 'package:wellumi/data/repositories/user_repository.dart';
import 'package:wellumi/modules/splash/bindings/splash_binding.dart';
import 'package:wellumi/modules/splash/views/splash_view.dart';
import 'package:wellumi/routes/app_routes.dart';

class _FakeSettings extends GetxService implements SettingsRepository {
  @override
  late final Rx<AppSettings> settings = const AppSettings().obs;
  @override
  AppSettings get current => settings.value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUsers extends GetxService implements UserRepository {
  @override
  final profile = Rxn<UserProfile>();
  @override
  bool get hasProfile => profile.value != null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('splash moves on to the welcome screen for a new user', (tester) async {
    Get.testMode = true;
    // Load the bundled fonts up front (real async I/O), so no font finishes
    // loading after the test ends and schedules a stray frame.
    await tester.runAsync(() async {
      for (final w in [FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700]) {
        GoogleFonts.dmSans(fontWeight: w);
      }
      GoogleFonts.fraunces(fontWeight: FontWeight.w600);
      await GoogleFonts.pendingFonts();
    });
    Get.put<SettingsRepository>(_FakeSettings());
    Get.put<UserRepository>(_FakeUsers());

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.splash,
        getPages: [
          GetPage(name: AppRoutes.splash, page: () => const SplashView(), binding: SplashBinding()),
          GetPage(
            name: AppRoutes.welcome,
            page: () => const Scaffold(body: Text('welcome-screen')),
          ),
        ],
      ),
    );
    expect(find.text('welcome-screen'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    expect(find.text('welcome-screen'), findsOneWidget);
    Get.reset();
  });
}
