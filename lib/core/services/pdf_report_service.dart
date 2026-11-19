import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/user_profile.dart';
import '../../data/models/vital_reading.dart';
import '../constants/app_constants.dart';

class ReportSummary {
  const ReportSummary({
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.avgHeartRate,
    required this.count,
  });

  final int? avgSystolic;
  final int? avgDiastolic;
  final int? avgHeartRate;
  final int count;

  String get bpText => avgSystolic == null ? '--/--' : '$avgSystolic/$avgDiastolic';

  static ReportSummary of(List<VitalReading> readings) {
    final bp = readings.where((r) => r.hasBp).toList();
    final hr = readings.where((r) => r.heartRate != null).toList();
    int? avg(Iterable<int> v) => v.isEmpty ? null : (v.reduce((a, b) => a + b) / v.length).round();
    return ReportSummary(
      avgSystolic: avg(bp.map((r) => r.systolic!)),
      avgDiastolic: avg(bp.map((r) => r.diastolic!)),
      avgHeartRate: avg(hr.map((r) => r.heartRate!)),
      count: readings.length,
    );
  }
}

/// Builds the shareable PDF health summary.
class PdfReportService {
  static final _teal = PdfColor.fromInt(0xFF0E6B63);
  static final _muted = PdfColor.fromInt(0xFF56625F);
  static final _line = PdfColor.fromInt(0xFFE2DED5);
  static final _soft = PdfColor.fromInt(0xFFF5F3EE);

  Future<Uint8List> build({
    required UserProfile? profile,
    required List<VitalReading> readings,
    required DateTime from,
    required DateTime to,
    required bool includeCharts,
    required bool includeNotes,
  }) async {
    final doc = pw.Document(title: '${AppConstants.appName} health summary', author: AppConstants.appName);
    final sorted = [...readings]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final summary = ReportSummary.of(sorted);
    final df = DateFormat('d MMM yyyy');
    final dtf = DateFormat('d MMM, h:mm a');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}  ·  Camera-based values are wellness estimates, not a diagnosis.',
            style: pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ),
        build: (ctx) => [
          pw.Row(
            children: [
              pw.Container(
                width: 26,
                height: 26,
                decoration: pw.BoxDecoration(color: _teal, borderRadius: pw.BorderRadius.circular(6)),
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                '${AppConstants.appName} health summary',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            [
              if (profile != null) '${profile.name} · ${profile.age} yrs · ${profile.gender.label}',
              '${df.format(from)} – ${df.format(to)}',
            ].join('   |   '),
            style: pw.TextStyle(fontSize: 10, color: _muted),
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            children: [
              _stat('Average BP', '${summary.bpText} mmHg'),
              pw.SizedBox(width: 10),
              _stat('Average heart rate', '${summary.avgHeartRate ?? '--'} bpm'),
              pw.SizedBox(width: 10),
              _stat('Readings', '${summary.count}'),
            ],
          ),
          if (includeCharts && sorted.where((r) => r.hasBp).length >= 2) ...[
            pw.SizedBox(height: 20),
            pw.Text('Blood pressure trend', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.SizedBox(height: 170, child: _bpChart(sorted.where((r) => r.hasBp).toList())),
          ],
          pw.SizedBox(height: 20),
          pw.Text('All readings', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: _teal),
            cellStyle: const pw.TextStyle(fontSize: 9),
            rowDecoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5)),
            ),
            cellAlignment: pw.Alignment.centerLeft,
            headers: [
              'Date',
              'Source',
              'BP (mmHg)',
              'HR',
              'HRV',
              'Breathing',
              if (AppConstants.showSpo2Estimate) 'SpO2',
              if (includeNotes) 'Note',
            ],
            data: sorted.reversed
                .map(
                  (r) => [
                    dtf.format(r.timestamp),
                    r.isScan ? 'Scan (est.)' : 'Cuff',
                    r.bpText,
                    r.heartRate?.toString() ?? '--',
                    r.hrvRmssd == null ? '--' : '${r.hrvRmssd!.round()} ms',
                    r.breathingRate == null ? '--' : '${r.breathingRate}/min',
                    if (AppConstants.showSpo2Estimate) r.spo2 == null ? '--' : '~${r.spo2}%',
                    if (includeNotes) r.note ?? '',
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(color: _soft, borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Text(
              'Readings marked "Scan (est.)" were estimated from the phone camera and are for wellness tracking only. '
              'Cuff readings were entered by the user. Please interpret together with a clinical measurement.',
              style: pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _stat(String label, String value) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: _soft, borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _muted)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    ),
  );

  pw.Widget _bpChart(List<VitalReading> r) {
    final n = r.length;
    return pw.Chart(
      grid: pw.CartesianGrid(
        xAxis: pw.FixedAxis.fromStrings(
          List.generate(n, (i) => n <= 10 || i % (n ~/ 8 + 1) == 0 ? DateFormat('d/M').format(r[i].timestamp) : ''),
          marginStart: 10,
          marginEnd: 10,
          textStyle: const pw.TextStyle(fontSize: 7),
        ),
        yAxis: pw.FixedAxis(
          [60, 80, 100, 120, 140, 160, 180],
          divisions: true,
          textStyle: const pw.TextStyle(fontSize: 7),
        ),
      ),
      datasets: [
        pw.LineDataSet(
          legend: 'Systolic',
          color: _teal,
          drawPoints: true,
          pointSize: 2,
          data: List.generate(n, (i) => pw.PointChartValue(i.toDouble(), r[i].systolic!.toDouble().clamp(60, 180))),
        ),
        pw.LineDataSet(
          legend: 'Diastolic',
          color: PdfColor.fromInt(0xFFC07A2E),
          drawPoints: true,
          pointSize: 2,
          data: List.generate(n, (i) => pw.PointChartValue(i.toDouble(), r[i].diastolic!.toDouble().clamp(60, 180))),
        ),
      ],
    );
  }

  Future<void> share(Uint8List bytes, String fileName) => Printing.sharePdf(bytes: bytes, filename: fileName);

  /// Opens the system print / "Save as PDF" sheet.
  Future<bool> saveOrPrint(Uint8List bytes, String fileName) =>
      Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
}
