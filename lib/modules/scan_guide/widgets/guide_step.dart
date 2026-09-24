import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class GuideStep extends StatelessWidget {
  const GuideStep({super.key, required this.number, required this.title, required this.text});

  final int number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: AppTextStyles.body(14, weight: FontWeight.w700, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.body(15, weight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(text, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
