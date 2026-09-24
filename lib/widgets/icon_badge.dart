import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.size = 40,
    this.color = AppColors.primary,
    this.background = AppColors.primarySoft,
    this.radius = 12,
  });

  final IconData icon;
  final double size;
  final Color color;
  final Color background;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
