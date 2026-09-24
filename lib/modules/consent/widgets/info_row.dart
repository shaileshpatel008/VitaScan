import 'package:flutter/material.dart';

import '../../../theme/app_text_styles.dart';
import '../../../widgets/icon_badge.dart';

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBadge(icon: icon),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.body(15, weight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(text, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
