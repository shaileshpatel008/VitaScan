import 'package:get/get.dart';

import '../datasources/local_datasource.dart';
import '../models/vital_reading.dart';
import 'calibration_repository.dart';

/// All readings, newest first, kept in a reactive list so every screen updates.
class ReadingRepository extends GetxService {
  ReadingRepository(this._local);

  final LocalDataSource _local;
  final readings = <VitalReading>[].obs;

  @override
  void onInit() {
    final list = <VitalReading>[];
    for (final map in _local.readReadings()) {
      try {
        list.add(VitalReading.fromMap(map));
      } catch (_) {
        // Skip a corrupt record rather than failing the whole app.
      }
    }
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    readings.assignAll(list);
    super.onInit();
  }

  VitalReading? get latest => readings.isEmpty ? null : readings.first;

  VitalReading? get latestScan => readings.firstWhereOrNull((r) => r.isScan);

  VitalReading? byId(String id) => readings.firstWhereOrNull((r) => r.id == id);

  List<VitalReading> between(DateTime from, DateTime to) =>
      readings.where((r) => !r.timestamp.isBefore(from) && !r.timestamp.isAfter(to)).toList();

  Future<void> save(VitalReading reading) async {
    await _local.writeReading(reading.id, reading.toMap());
    readings.removeWhere((r) => r.id == reading.id);
    readings.add(reading);
    readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Removes from the in-memory list first so swipe-to-delete updates instantly.
  Future<void> delete(String id) async {
    readings.removeWhere((r) => r.id == id);
    await _local.deleteReading(id);
    await _local.deleteCalibrationsForReading(id);
    if (Get.isRegistered<CalibrationRepository>()) Get.find<CalibrationRepository>().reload();
  }

  void clear() => readings.clear();
}
