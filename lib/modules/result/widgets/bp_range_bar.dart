import 'package:flutter/material.dart';

import '../../../core/utils/health_classifier.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Four-band BP scale with a marker that glides into place.
class BpRangeBar extends StatelessWidget {
  const BpRangeBar({super.key, required this.systolic});

  final int systolic;

  @override
  Widget build(BuildContext context) {
    final pos = BpCategory.barPosition(systolic);
    return Semantics(
      label: 'Blood pressure scale',
      value: BpCategory.classify(systolic, 0).label,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(flex: 3, child: ColoredBox(color: AppColors.bpNormal)),
                  SizedBox(width: 2),
                  Expanded(flex: 1, child: ColoredBox(color: AppColors.bpElevated)),
                  SizedBox(width: 2),
                  Expanded(flex: 2, child: ColoredBox(color: AppColors.bpStage1)),
                  SizedBox(width: 2),
                  Expanded(flex: 2, child: ColoredBox(color: AppColors.bpStage2)),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 14,
            child: LayoutBuilder(
              builder: (context, box) => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pos),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutBack,
                builder: (context, v, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: (v.clamp(0.0, 1.0) * box.maxWidth) - 7,
                      top: 3,
                      child: const CustomPaint(size: Size(14, 9), painter: _Triangle()),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final l in ['Normal', 'Elevated', 'High 1', 'High 2'])
                Text(l, style: AppTextStyles.body(11, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Triangle extends CustomPainter {
  const _Triangle();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(_Triangle old) => false;
}
