import 'dart:async';

import 'package:get/get.dart';

import '../../../core/services/purchase_service.dart';
import '../../../core/utils/ppg/signal_math.dart';
import '../../../core/utils/premium_policy.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/vital_reading.dart';
import '../../../data/repositories/calibration_repository.dart';
import '../../../data/repositories/reading_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../routes/app_routes.dart';
import '../../main_shell/controllers/main_shell_controller.dart';

class HomeController extends GetxController {
  HomeController(this._users, this._readings, this._calibration);

  final UserRepository _users;
  final ReadingRepository _readings;
  final CalibrationRepository _calibration;

  static const tips = [
    'Scan at the same time each day. Mornings before coffee give the most comparable readings.',
    'Avoid caffeine, smoking and exercise for 30 minutes before a scan.',
    'Sit with your back supported and feet flat on the floor.',
    'Cold fingers give weak signals. Rub your hands together first.',
    'Add a cuff reading now and then to keep your BP estimate accurate.',
  ];

  final tipIndex = 0.obs;
  Timer? _tipTimer;

  @override
  void onInit() {
    super.onInit();
    tipIndex.value = DateTime.now().day % tips.length;
    _tipTimer = Timer.periodic(const Duration(seconds: 9), (_) => tipIndex.value = (tipIndex.value + 1) % tips.length);
  }

  UserProfile? get profile => _users.profile.value;
  VitalReading? get latest => _readings.readings.isEmpty ? null : _readings.readings.first;
  int get calibrationCount => _calibration.points.length;
  DateTime? get lastCalibratedAt => _calibration.points.isEmpty ? null : _calibration.points.first.timestamp;

  /// BP readings from the last 7 days, oldest first.
  List<VitalReading> get weekBp {
    final from = DateTime.now().subtract(const Duration(days: 7));
    return _readings.readings.where((r) => r.hasBp && r.timestamp.isAfter(from)).toList().reversed.toList();
  }

  String get trendLabel {
    final w = weekBp;
    if (w.length < 3) return 'Building';
    final half = w.length ~/ 2;
    final first = SignalMath.mean(w.take(half).map((r) => r.systolic!.toDouble()).toList());
    final last = SignalMath.mean(w.skip(half).map((r) => r.systolic!.toDouble()).toList());
    if (last - first > 5) return 'Rising';
    if (first - last > 5) return 'Falling';
    return 'Stable';
  }

  ScanAllowance get allowance => Get.find<PurchaseService>().allowance;

  /// Short status for the scan card: Premium, free scans left, or none left.
  String get scanStatus {
    final a = allowance;
    if (a.isPremium) return 'Premium · unlimited scans';
    if (!a.canScan) return 'You\'ve used your ${a.limit} free scans';
    return a.remaining == 1 ? '1 free scan left' : '${a.remaining} free scans left';
  }

  /// The scan gate sends locked users to the Premium screen.
  void startScan() => Get.toNamed(AppRoutes.scanGuide);

  void openLatest() {
    final r = latest;
    if (r != null) Get.toNamed(AppRoutes.result, arguments: {'readingId': r.id, 'fresh': false});
  }

  void openReminders() => Get.find<MainShellController>().changeTab(MainTab.profile);

  void openHistory() => Get.find<MainShellController>().changeTab(MainTab.history);

  @override
  void onClose() {
    _tipTimer?.cancel();
    super.onClose();
  }
}
