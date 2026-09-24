import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/pdf_report_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/app_messenger.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/vital_reading.dart';
import '../../../data/repositories/reading_repository.dart';
import '../../../data/repositories/user_repository.dart';

enum ReportPeriod {
  week('Last 7 days'),
  month('Last 30 days'),
  custom('Custom');

  const ReportPeriod(this.label);
  final String label;
}

class ReportsController extends GetxController {
  ReportsController(this._readings, this._users, this._pdf);

  final ReadingRepository _readings;
  final UserRepository _users;
  final PdfReportService _pdf;

  final period = ReportPeriod.month.obs;
  final customRange = Rxn<DateTimeRange>();
  final includeCharts = true.obs;
  final includeNotes = false.obs;
  final downloading = false.obs;
  final sharing = false.obs;

  UserProfile? get profile => _users.profile.value;

  DateTimeRange get range {
    final now = DateTime.now();
    return switch (period.value) {
      ReportPeriod.week => DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      ReportPeriod.month => DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      ReportPeriod.custom =>
        customRange.value ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
    };
  }

  List<VitalReading> get readings {
    final r = range;
    final end = DateTime(r.end.year, r.end.month, r.end.day, 23, 59, 59);
    return _readings.between(r.start, end);
  }

  ReportSummary get summary => ReportSummary.of(readings);

  List<double> get systolicTrend =>
      readings.where((r) => r.hasBp).toList().reversed.map((r) => r.systolic!.toDouble()).toList();

  Future<void> selectPeriod(BuildContext context, ReportPeriod p) async {
    if (p != ReportPeriod.custom) {
      period.value = p;
      return;
    }
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now,
      initialDateRange: range,
      helpText: 'Choose report period',
    );
    if (picked == null) return;
    customRange.value = picked;
    period.value = ReportPeriod.custom;
  }

  String get _fileName => '${AppConstants.appName}_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

  Future<void> download() => _run(downloading, (bytes) => _pdf.saveOrPrint(bytes, _fileName));

  Future<void> share() => _run(sharing, (bytes) => _pdf.share(bytes, _fileName));

  Future<void> _run(RxBool flag, Future<dynamic> Function(Uint8List) action) async {
    if (flag.value) return;
    final list = readings;
    if (list.isEmpty) {
      AppMessenger.warning(AppStrings.reportNoData, title: 'Nothing to report yet');
      return;
    }
    flag.value = true;
    try {
      final bytes = await _pdf.build(
        profile: profile,
        readings: list,
        from: range.start,
        to: range.end,
        includeCharts: includeCharts.value,
        includeNotes: includeNotes.value,
      );
      await action(bytes);
      AppMessenger.success(AppStrings.reportReady, title: 'Report created');
    } catch (e, st) {
      AppLogger.error('Report failed', e, st);
      AppMessenger.error(AppStrings.reportFailed);
    } finally {
      flag.value = false;
    }
  }
}
