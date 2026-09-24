import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/vital_reading.dart';
import '../constants/app_constants.dart';

/// Exports all readings as a CSV file through the share sheet.
class ExportService {
  Future<void> shareCsv(List<VitalReading> readings) async {
    final buffer = StringBuffer()
      ..writeln(
        'timestamp,source,systolic,diastolic,heart_rate,hrv_rmssd_ms,stress_score,'
        'breathing_rate,spo2,signal_quality,calibrated,note',
      );
    final sorted = [...readings]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    for (final r in sorted) {
      buffer.writeln(
        [
          r.timestamp.toIso8601String(),
          r.source.name,
          r.systolic ?? '',
          r.diastolic ?? '',
          r.heartRate ?? '',
          r.hrvRmssd?.toStringAsFixed(1) ?? '',
          r.stressScore ?? '',
          r.breathingRate ?? '',
          r.spo2 ?? '',
          r.signalQuality ?? '',
          r.isCalibrated,
          _escape(r.note ?? ''),
        ].join(','),
      );
    }

    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${dir.path}/${AppConstants.appName.toLowerCase()}_export_$stamp.csv');
    await file.writeAsString(buffer.toString());
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: '${AppConstants.appName} data export',
      ),
    );
  }

  String _escape(String v) => v.contains(RegExp(r'[,"\n]')) ? '"${v.replaceAll('"', '""')}"' : v;
}
