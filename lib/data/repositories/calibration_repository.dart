import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../datasources/local_datasource.dart';
import '../models/calibration_point.dart';

class CalibrationRepository extends GetxService {
  CalibrationRepository(this._local);

  final LocalDataSource _local;
  final points = <CalibrationPoint>[].obs;

  @override
  void onInit() {
    reload();
    super.onInit();
  }

  void reload() {
    final list = _local.readCalibrations().map(CalibrationPoint.fromMap).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    points.assignAll(list);
  }

  int get count => points.length;
  bool get isComplete => count >= AppConstants.calibrationTargetReadings;
  DateTime? get lastCalibratedAt => points.isEmpty ? null : points.first.timestamp;

  bool isUsed(String scanReadingId) => points.any((p) => p.scanReadingId == scanReadingId);

  Future<void> add(CalibrationPoint point) async {
    await _local.writeCalibration(point.id, point.toMap());
    reload();
  }

  void clear() => points.clear();
}
