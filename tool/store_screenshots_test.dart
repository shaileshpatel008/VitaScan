// Generates Play Store phone screenshots from the real app screens.
//
//   flutter test tool/store_screenshots_test.dart
//
// Output: store/screenshots/raw/*.png (1080x1920). Not part of the normal test
// suite (lives outside test/). Uses sample data only.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:wellumi/core/constants/app_constants.dart';
import 'package:wellumi/core/services/app_update_service.dart';
import 'package:wellumi/core/services/camera_ppg_service.dart';
import 'package:wellumi/core/services/export_service.dart';
import 'package:wellumi/core/services/health_sync_service.dart';
import 'package:wellumi/core/services/notification_service.dart';
import 'package:wellumi/core/services/pdf_report_service.dart';
import 'package:wellumi/core/services/permission_service.dart';
import 'package:wellumi/core/services/purchase_service.dart';
import 'package:wellumi/core/services/storage_service.dart';
import 'package:wellumi/core/utils/premium_policy.dart';
import 'package:wellumi/data/datasources/local_datasource.dart';
import 'package:wellumi/data/models/app_settings.dart';
import 'package:wellumi/data/models/calibration_point.dart';
import 'package:wellumi/data/models/store_product.dart';
import 'package:wellumi/data/models/user_profile.dart';
import 'package:wellumi/data/models/vital_reading.dart';
import 'package:wellumi/data/repositories/backup_repository.dart';
import 'package:wellumi/data/repositories/calibration_repository.dart';
import 'package:wellumi/data/repositories/reading_repository.dart';
import 'package:wellumi/data/repositories/settings_repository.dart';
import 'package:wellumi/data/repositories/user_repository.dart';
import 'package:wellumi/modules/history/controllers/history_controller.dart';
import 'package:wellumi/modules/home/controllers/home_controller.dart';
import 'package:wellumi/modules/main_shell/controllers/main_shell_controller.dart';
import 'package:wellumi/modules/main_shell/views/main_shell_view.dart';
import 'package:wellumi/modules/premium/controllers/premium_controller.dart';
import 'package:wellumi/modules/premium/views/premium_view.dart';
import 'package:wellumi/modules/reports/controllers/reports_controller.dart';
import 'package:wellumi/modules/result/controllers/result_controller.dart';
import 'package:wellumi/modules/result/views/result_view.dart';
import 'package:wellumi/modules/scan/controllers/scan_controller.dart';
import 'package:wellumi/modules/scan/models/scan_phase.dart';
import 'package:wellumi/modules/scan/views/scan_view.dart';
import 'package:wellumi/modules/scan_guide/views/scan_guide_view.dart';
import 'package:wellumi/modules/settings/controllers/settings_controller.dart';
import 'package:wellumi/modules/welcome/views/welcome_view.dart';
import 'package:wellumi/theme/app_theme.dart';

// ------------------------------------------------------------------ fakes

class _TestStorage extends StorageService {}

class _Fake {
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeHealth extends _Fake implements HealthSyncService {}

class _FakePermissions extends _Fake implements PermissionService {}

class _FakeNotifications extends _Fake implements NotificationService {}

class _FakePdf extends _Fake implements PdfReportService {}

class _FakeExport extends _Fake implements ExportService {}

class _FakeBackup extends _Fake implements BackupRepository {}

class _FakeCamera extends CameraPpgService {
  @override
  Future<void> dispose() async {}
}

class _FakeUpdates extends GetxService implements AppUpdateService {
  @override
  final checking = false.obs;
  @override
  final version = '1.0.0'.obs;
  @override
  final buildNumber = '1'.obs;
  @override
  Future<void> checkOnLaunch() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakePurchases extends GetxService implements PurchaseService {
  @override
  final plan = PremiumPlan.none.obs;
  @override
  final freeScansUsed = 1.obs;
  @override
  final products = <StoreProduct>[].obs;
  @override
  final storeAvailable = true.obs;
  @override
  final loadingProducts = false.obs;
  @override
  final purchasing = false.obs;
  @override
  final restoring = false.obs;
  @override
  bool get isPremium => plan.value.isActive;
  @override
  bool get adsRemoved => isPremium;
  @override
  ScanAllowance get allowance => ScanAllowance(used: freeScansUsed.value, isPremium: isPremium);
  @override
  Future<void> loadProducts() async {}
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

/// Shows a frozen mid-scan state without touching the camera.
class _StillScanController extends ScanController {
  _StillScanController()
    : super(
        camera: _FakeCamera(),
        readings: Get.find(),
        users: Get.find(),
        calibration: Get.find(),
        settings: Get.find(),
        health: _FakeHealth(),
        permissions: _FakePermissions(),
      );

  @override
  void onReady() {}

  @override
  void onClose() {}
}

// ------------------------------------------------------------------ sample data

const _dpr = 2.625; // 1080 x 1920 px
final _logical = const Size(1080 / _dpr, 1920 / _dpr);

StoreProduct _product(String id, PremiumPlan plan, String price, double raw, String period, {String? trial}) =>
    StoreProduct(
      details: ProductDetails(
        id: id,
        title: 'Wellumi Premium',
        description: '',
        price: price,
        rawPrice: raw,
        currencyCode: 'USD',
      ),
      plan: plan,
      price: price,
      priceMicros: (raw * 1000000).round(),
      period: period,
      trial: trial,
    );

Future<void> _seed(LocalDataSource local) async {
  final now = DateTime.now();
  await local.writeProfile(
    UserProfile(
      name: 'John Smith',
      age: 42,
      gender: Gender.male,
      heightCm: 178,
      weightKg: 76,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
    ).toMap(),
  );
  await local.writeSettings(
    AppSettings(onboardingComplete: true, consentAcceptedAt: now, morningReminderEnabled: true).toMap(),
  );
  final rnd = math.Random(7);
  final sys = [121, 118, 123, 117, 120, 116, 119, 118];
  final dia = [79, 77, 81, 76, 78, 75, 77, 76];
  for (var i = 0; i < sys.length; i++) {
    final day = now.subtract(Duration(days: sys.length - 1 - i, hours: i.isEven ? 1 : 12));
    final isCuff = i == 3;
    final r = VitalReading(
      id: 'r$i',
      timestamp: i == sys.length - 1 ? now.subtract(const Duration(minutes: 3)) : day,
      source: isCuff ? ReadingSource.cuff : ReadingSource.scan,
      systolic: sys[i],
      diastolic: dia[i],
      heartRate: 66 + rnd.nextInt(9),
      hrvRmssd: isCuff ? null : 42 + rnd.nextInt(14).toDouble(),
      stressScore: isCuff ? null : 24 + rnd.nextInt(12),
      breathingRate: isCuff ? null : 13 + rnd.nextInt(3),
      signalQuality: isCuff ? null : 88 + rnd.nextInt(8),
      rawSystolic: isCuff ? null : sys[i] - 3,
      rawDiastolic: isCuff ? null : dia[i] - 2,
      isCalibrated: !isCuff,
    );
    await local.writeReading(r.id, r.toMap());
  }
  for (var i = 0; i < 3; i++) {
    final p = CalibrationPoint(
      id: 'c$i',
      timestamp: now.subtract(Duration(days: 6 - i)),
      scanReadingId: 'r$i',
      cuffSystolic: 122,
      cuffDiastolic: 80,
      estimatedSystolic: 119,
      estimatedDiastolic: 78,
    );
    await local.writeCalibration(p.id, p.toMap());
  }
}

// ------------------------------------------------------------------ harness

final _boundary = GlobalKey();
final _outDir = Directory('store/screenshots/raw');

Future<void> _setUpApp(WidgetTester tester) async {
  tester.view.physicalSize = _logical * _dpr;
  tester.view.devicePixelRatio = _dpr;

  await tester.runAsync(() async {
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
    final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    final loader = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(await icons.readAsBytes())));
    await loader.load();
    for (final w in [FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700]) {
      GoogleFonts.dmSans(fontWeight: w);
    }
    GoogleFonts.fraunces(fontWeight: FontWeight.w600);
    await GoogleFonts.pendingFonts();

    final dir = await Directory.systemTemp.createTemp('wellumi_shots');
    Hive.init(dir.path);
    final storage = _TestStorage()
      ..profileBox = await Hive.openBox('p')
      ..readingsBox = await Hive.openBox('r')
      ..calibrationBox = await Hive.openBox('c')
      ..settingsBox = await Hive.openBox('s');
    final local = LocalDataSource(storage);
    await _seed(local);

    Get.testMode = true;
    Get.put<StorageService>(storage);
    Get.put(local);
    Get.put(SettingsRepository(local));
    Get.put(UserRepository(local));
    Get.put(CalibrationRepository(local));
    Get.put(ReadingRepository(local));
    Get.put<AppUpdateService>(_FakeUpdates());
    final purchases = _FakePurchases();
    purchases.products.assignAll([
      _product(AppConstants.premiumYearlyId, PremiumPlan.yearly, r'$29.99', 29.99, 'year', trial: '1 week free'),
      _product(AppConstants.premiumMonthlyId, PremiumPlan.monthly, r'$4.99', 4.99, 'month'),
      _product(AppConstants.premiumLifetimeId, PremiumPlan.lifetime, r'$59.99', 59.99, ''),
    ]);
    Get.put<PurchaseService>(purchases);
  });
}

Future<void> _shoot(
  WidgetTester tester,
  String name,
  Widget screen, {
  Duration settle = const Duration(seconds: 3),
  Future<void> Function()? beforeCapture,
}) async {
  await tester.pumpWidget(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (_, child) => RepaintBoundary(key: _boundary, child: child),
      home: screen,
    ),
  );
  await tester.pump();
  // Decode images (logo etc.) with real async I/O, then let entrance animations finish.
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  for (var t = Duration.zero; t < settle; t += const Duration(milliseconds: 100)) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  if (beforeCapture != null) {
    await beforeCapture();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _dpr);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    _outDir.createSync(recursive: true);
    File('${_outDir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });

  // Tear down so repeating animations and timers stop.
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

void _shellControllers() {
  Get.put(MainShellController());
  Get.put(HomeController(Get.find(), Get.find(), Get.find()));
  Get.put(HistoryController(Get.find()));
  Get.put(ReportsController(Get.find(), Get.find(), _FakePdf()));
  Get.put(
    SettingsController(
      users: Get.find(),
      settings: Get.find(),
      readings: Get.find(),
      calibration: Get.find(),
      backup: _FakeBackup(),
      storage: Get.find(),
      notifications: _FakeNotifications(),
      health: _FakeHealth(),
      export: _FakeExport(),
      updates: Get.find(),
    ),
  );
}

void _dropShellControllers() {
  Get.delete<HomeController>(force: true);
  Get.delete<HistoryController>(force: true);
  Get.delete<ReportsController>(force: true);
  Get.delete<SettingsController>(force: true);
  Get.delete<MainShellController>(force: true);
}

Future<void> _shell(WidgetTester tester, String name, MainTab tab) async {
  _shellControllers();
  Get.find<MainShellController>().tab.value = tab;
  await _shoot(tester, name, const MainShellView());
  _dropShellControllers();
}

void main() {
  testWidgets('store screenshots', (tester) async {
    await _setUpApp(tester);

    await _shell(tester, '01_home', MainTab.home);

    // Mid-scan
    final scan = Get.put<ScanController>(_StillScanController());
    scan.phase.value = ScanPhase.measuring;
    scan.progress.value = 0.62;
    scan.secondsLeft.value = 17;
    scan.liveHeartRate.value = 72;
    scan.signalQuality.value = 86;
    scan.fingerDetected.value = true;
    scan.hint.value = 'Hold still and keep your finger light on the camera';
    scan.waveform.assignAll(
      List.generate(120, (i) {
        final p = (i / 26) % 1.0;
        final y = math.exp(-math.pow((p - 0.18) / 0.075, 2)) + 0.38 * math.exp(-math.pow((p - 0.47) / 0.09, 2));
        return y * 1.6 - 0.7;
      }),
    );
    await _shoot(tester, '02_scanning', const ScanView());
    Get.delete<ScanController>(force: true);

    // Results of the latest scan
    final latestId = Get.find<ReadingRepository>().latestScan!.id;
    await _withArgs(tester, {'readingId': latestId, 'fresh': true}, () async {
      Get.put(ResultController(Get.find(), Get.find()));
      await _shoot(tester, '03_results', const ResultView());
      Get.delete<ResultController>(force: true);
    });

    await _shell(tester, '04_history', MainTab.history);
    await _shoot(tester, '05_scan_guide', const ScanGuideView());
    await _shell(tester, '06_reports', MainTab.reports);

    Get.put(PremiumController(Get.find()));
    await _shoot(
      tester,
      '07_premium',
      const PremiumView(),
      beforeCapture: () async {
        await tester.drag(find.byType(ListView), const Offset(0, -560));
      },
    );
    Get.delete<PremiumController>(force: true);

    await _shoot(tester, '08_welcome', const WelcomeView());

    Get.reset();
    await tester.pump(const Duration(seconds: 2));
  });
}

/// ResultController reads Get.arguments in onInit; route arguments are faked here.
Future<void> _withArgs(WidgetTester tester, Map<String, dynamic> args, Future<void> Function() body) async {
  Get.routing.args = args;
  await body();
  Get.routing.args = null;
}
