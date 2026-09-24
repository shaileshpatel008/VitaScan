import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_messenger.dart';
import '../../../data/models/vital_reading.dart';
import '../../../data/repositories/reading_repository.dart';
import '../../../routes/app_routes.dart';

enum HistoryRange {
  week('Week', 7),
  month('Month', 30),
  quarter('3 months', 90);

  const HistoryRange(this.label, this.days);
  final String label;
  final int days;
}

class HistorySummary {
  const HistorySummary({this.avgBp, this.avgHr, required this.count});
  final String? avgBp;
  final int? avgHr;
  final int count;
}

class HistoryController extends GetxController {
  HistoryController(this._readings);

  final ReadingRepository _readings;

  final range = HistoryRange.week.obs;

  DateTime get from => DateTime.now().subtract(Duration(days: range.value.days));

  /// Newest first.
  List<VitalReading> get items => _readings.readings.where((r) => r.timestamp.isAfter(from)).toList();

  List<VitalReading> get bpSeries => items.where((r) => r.hasBp).toList().reversed.toList();

  HistorySummary get summary {
    final list = items;
    final bp = list.where((r) => r.hasBp).toList();
    final hr = list.where((r) => r.heartRate != null).toList();
    int avg(Iterable<int> v) => (v.reduce((a, b) => a + b) / v.length).round();
    return HistorySummary(
      avgBp: bp.isEmpty ? null : '${avg(bp.map((r) => r.systolic!))}/${avg(bp.map((r) => r.diastolic!))}',
      avgHr: hr.isEmpty ? null : avg(hr.map((r) => r.heartRate!)),
      count: list.length,
    );
  }

  void open(VitalReading r) => Get.toNamed(AppRoutes.result, arguments: {'readingId': r.id, 'fresh': false});

  void startScan() => Get.toNamed(AppRoutes.scanGuide);

  Future<bool> confirmDelete(VitalReading r) => AppMessenger.confirm(
    title: 'Delete this reading?',
    message: 'It will be removed from your history and reports.',
    confirmText: 'Delete',
    destructive: true,
    icon: Icons.delete_outline_rounded,
  );

  Future<void> delete(VitalReading r) async {
    await _readings.delete(r.id);
    AppMessenger.success('The reading was deleted.', title: 'Deleted');
  }
}
