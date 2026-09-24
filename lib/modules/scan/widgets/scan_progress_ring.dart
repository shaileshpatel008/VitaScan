import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Circular countdown ring. When [indeterminate] it spins while analysing.
class ScanProgressRing extends StatefulWidget {
  const ScanProgressRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 240,
    this.indeterminate = false,
  });

  final double progress;
  final Widget child;
  final double size;
  final bool indeterminate;

  @override
  State<ScanProgressRing> createState() => _ScanProgressRingState();
}

class _ScanProgressRingState extends State<ScanProgressRing> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  void didUpdateWidget(covariant ScanProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.indeterminate && !_spin.isAnimating) _spin.repeat();
    if (!widget.indeterminate && _spin.isAnimating) _spin.stop();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Scan progress ${(widget.progress * 100).round()} percent',
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: widget.progress),
              duration: const Duration(milliseconds: 180),
              builder: (context, p, _) => AnimatedBuilder(
                animation: _spin,
                builder: (context, _) => CustomPaint(
                  size: Size.square(widget.size),
                  painter: _RingPainter(
                    progress: widget.indeterminate ? 0.25 : p,
                    rotation: widget.indeterminate ? _spin.value * 2 * math.pi : 0,
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.rotation});

  final double progress;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final c = size.center(Offset.zero);
    final r = size.width / 2 - stroke;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.12),
    );
    if (progress <= 0) return;
    final rect = Rect.fromCircle(center: c, radius: r);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: const [Color(0xFF3FB5A5), AppColors.scanAccent, Color(0xFFB6F0E6)],
        transform: GradientRotation(-math.pi / 2 + rotation),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2 + rotation, 2 * math.pi * progress, false, arc);

    // Glowing head of the arc
    final a = -math.pi / 2 + rotation + 2 * math.pi * progress;
    final head = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
    canvas.drawCircle(
      head,
      9,
      Paint()
        ..color = AppColors.scanAccent.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.rotation != rotation;
}
