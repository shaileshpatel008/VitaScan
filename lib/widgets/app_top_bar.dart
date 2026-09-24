import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.showBack = true,
    this.color = AppColors.ink,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showBack;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              tooltip: 'Back',
              onPressed: onBack ?? Get.back,
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: color, size: 20),
              style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: AppTextStyles.title.copyWith(color: color)),
          ),
          ?trailing,
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
