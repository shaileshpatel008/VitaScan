import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/vital_reading.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../controllers/history_controller.dart';

/// Systolic / diastolic lines over the selected period.
class BpTrendChart extends StatelessWidget {
  const BpTrendChart({super.key, required this.readings, required this.range});

  /// Oldest first, all with BP.
  final List<VitalReading> readings;
  final HistoryRange range;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: range.days));
    double x(DateTime t) => t.difference(start).inMinutes / (60 * 24);

    final sys = readings.map((r) => FlSpot(x(r.timestamp), r.systolic!.toDouble())).toList();
    final dia = readings.map((r) => FlSpot(x(r.timestamp), r.diastolic!.toDouble())).toList();

    final lo = readings.isEmpty ? 60.0 : readings.map((r) => r.diastolic!).reduce(math.min).toDouble();
    final hi = readings.isEmpty ? 140.0 : readings.map((r) => r.systolic!).reduce(math.max).toDouble();
    final minY = ((math.min(lo, 70) - 10) / 20).floor() * 20.0;
    final maxY = ((math.max(hi, 130) + 10) / 20).ceil() * 20.0;

    final labelEvery = switch (range) {
      HistoryRange.week => 1.0,
      HistoryRange.month => 7.0,
      HistoryRange.quarter => 15.0,
    };

    LineChartBarData line(List<FlSpot> spots, Color color, {bool fill = false}) => LineChartBarData(
      spots: spots,
      isCurved: spots.length > 2,
      curveSmoothness: 0.25,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: spots.length <= 31,
        getDotPainter: (_, _, _, _) => FlDotCirclePainter(radius: 3.2, color: color, strokeWidth: 0),
      ),
      belowBarData: BarAreaData(
        show: fill,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0)],
        ),
      ),
    );

    return Semantics(
      label: readings.isEmpty
          ? 'No blood pressure readings in this period'
          : 'Blood pressure chart with ${readings.length} readings',
      child: SizedBox(
        height: 190,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: range.days.toDouble(),
            minY: minY,
            maxY: maxY,
            clipData: const FlClipData.all(),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.line, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 20,
                  getTitlesWidget: (v, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(v.toInt().toString(), style: AppTextStyles.body(10, color: AppColors.muted)),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: labelEvery,
                  getTitlesWidget: (v, meta) {
                    if (v == meta.max) return const SizedBox.shrink();
                    final d = start.add(Duration(minutes: (v * 24 * 60).round()));
                    final text = range == HistoryRange.week
                        ? DateFormat('EEE').format(d)
                        : DateFormat('d MMM').format(d);
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(text, style: AppTextStyles.body(10, color: AppColors.muted)),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.ink,
                getTooltipItems: (spots) => spots
                    .map(
                      (s) => LineTooltipItem(
                        '${s.barIndex == 0 ? 'Sys' : 'Dia'} ${s.y.toInt()}',
                        AppTextStyles.body(12, color: Colors.white, weight: FontWeight.w600),
                      ),
                    )
                    .toList(),
              ),
            ),
            lineBarsData: [line(sys, AppColors.primary, fill: true), line(dia, AppColors.diastolic)],
          ),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }
}
