import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Live pulse waveform from the camera signal.
class PulseWaveform extends StatelessWidget {
  const PulseWaveform({super.key, required this.points});

  final List<double> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Pulse waveform (from camera)',
              style: AppTextStyles.body(12, color: Colors.white.withValues(alpha: 0.8)),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 90,
            width: double.infinity,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: points.isEmpty
                  ? Center(
                      key: const ValueKey('wait'),
                      child: Text(
                        'Waveform appears in a moment…',
                        style: AppTextStyles.body(13, color: Colors.white.withValues(alpha: 0.6)),
                      ),
                    )
                  : SizedBox.expand(
                      key: const ValueKey('wave'),
                      child: CustomPaint(painter: _WavePainter(points)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.points);

  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path();
    final dx = size.width / (points.length - 1);
    final mid = size.height / 2;
    final amp = size.height / 2 - 8;
    for (var i = 0; i < points.length; i++) {
      final p = Offset(i * dx, mid - points[i] * amp);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    final shader = const LinearGradient(
      colors: [Color(0x006FD3C4), AppColors.scanAccent, AppColors.scanAccent],
      stops: [0, 0.25, 1],
    ).createShader(Offset.zero & size);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..shader = shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..color = AppColors.scanAccent.withValues(alpha: 0.35),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..shader = shader,
    );
    final last = Offset(size.width, mid - points.last * amp);
    canvas.drawCircle(last, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_WavePainter old) => !identical(old.points, points);
}
