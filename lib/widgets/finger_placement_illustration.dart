import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Looping animation: a fingertip slides onto the rear camera and flash,
/// holds while the flash glows, then lifts. Shows patients exactly what to do.
class FingerPlacementIllustration extends StatefulWidget {
  const FingerPlacementIllustration({super.key, this.size = 200, this.dark = false, this.animate = true});

  final double size;
  final bool dark;
  final bool animate;

  @override
  State<FingerPlacementIllustration> createState() => _FingerPlacementIllustrationState();
}

class _FingerPlacementIllustrationState extends State<FingerPlacementIllustration> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _c.repeat();
    } else {
      _c.value = 0.6;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) _c.value = 0.6;
    return Semantics(
      label: 'Illustration: fingertip covering the rear camera and flash',
      image: true,
      child: SizedBox(
        width: widget.size,
        height: widget.size * 190 / 220,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(painter: _FingerPainter(_c.value, widget.dark)),
        ),
      ),
    );
  }
}

class _FingerPainter extends CustomPainter {
  _FingerPainter(this.t, this.dark);

  final double t;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 220, size.height / 190);
    final ink = dark ? Colors.white.withValues(alpha: 0.85) : AppColors.ink;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = ink;

    // Phone back
    final body = RRect.fromLTRBR(60, 10, 160, 185, const Radius.circular(18));
    canvas.drawRRect(body, Paint()..color = dark ? const Color(0xFF1C302D) : Colors.white);
    canvas.drawRRect(body, stroke);
    final island = RRect.fromLTRBR(72, 22, 116, 80, const Radius.circular(12));
    canvas.drawRRect(island, Paint()..color = dark ? const Color(0xFF2A413D) : AppColors.segment);
    canvas.drawRRect(island, stroke..strokeWidth = 1.5);

    // Finger progress: 0 = away, 1 = on the lens.
    final double on;
    if (t < 0.12) {
      on = 0;
    } else if (t < 0.4) {
      on = Curves.easeOutCubic.transform((t - 0.12) / 0.28);
    } else if (t < 0.85) {
      on = 1;
    } else {
      on = 1 - Curves.easeInCubic.transform((t - 0.85) / 0.15);
    }

    // Flash glows while covered.
    final glow = on * (0.55 + 0.45 * math.sin(t * math.pi * 10).abs());
    if (glow > 0) {
      canvas.drawCircle(
        const Offset(94, 58),
        26,
        Paint()
          ..color = AppColors.flash.withValues(alpha: 0.35 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
    canvas.drawCircle(const Offset(94, 40), 9, Paint()..color = dark ? Colors.black : AppColors.ink);
    canvas.drawCircle(const Offset(94, 64), 5, Paint()..color = AppColors.flash);

    // Target ring when the finger is away.
    if (on < 0.95) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = (dark ? AppColors.scanAccent : AppColors.primary).withValues(alpha: 1 - on);
      _dashedCircle(canvas, const Offset(94, 50), 30, ring);
    }

    // Finger
    canvas.save();
    canvas.translate(46 * (1 - on), 70 * (1 - on));
    final finger = Path()
      ..moveTo(150, 190)
      ..cubicTo(150, 130, 118, 108, 100, 70)
      ..cubicTo(92, 52, 104, 38, 116, 46)
      ..cubicTo(124, 52, 128, 70, 136, 84)
      ..lineTo(176, 150)
      ..lineTo(190, 190)
      ..close();
    canvas.drawPath(finger, Paint()..color = AppColors.skin);
    canvas.drawPath(finger, stroke..strokeWidth = 2);
    // Nail hint
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(112, 56), radius: 7),
      math.pi * 0.9,
      math.pi * 0.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = ink.withValues(alpha: 0.35),
    );
    canvas.restore();
  }

  void _dashedCircle(Canvas canvas, Offset c, double r, Paint p) {
    const dashes = 18;
    for (var i = 0; i < dashes; i++) {
      final a0 = i * 2 * math.pi / dashes;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a0, math.pi / dashes, false, p);
    }
  }

  @override
  bool shouldRepaint(_FingerPainter old) => old.t != t || old.dark != dark;
}
