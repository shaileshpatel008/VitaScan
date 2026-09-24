import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Minimal animated trend line with a soft fill.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.height = 54, this.color = AppColors.primary});

  final List<double> values;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return SizedBox(
        height: height,
        child: CustomPaint(painter: _DashedLinePainter(color.withValues(alpha: 0.35)), size: Size.infinite),
      );
    }
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    final pad = (hi - lo).abs() < 4 ? 4.0 : (hi - lo) * 0.2;
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: lo - pad,
          maxY: hi + pad,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
              isCurved: true,
              curveSmoothness: 0.3,
              preventCurveOverShooting: true,
              color: color,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, bar) => spot.x == bar.spots.last.x,
                getDotPainter: (_, _, _, _) =>
                    FlDotCirclePainter(radius: 3.5, color: color, strokeWidth: 2, strokeColor: Colors.white),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0)],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(x + 5, size.height / 2), p);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}
