import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/entrance.dart';
import '../widgets/feature_row.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                AppAssets.appIcon,
                width: 64,
                height: 64,
                semanticLabel: '${AppConstants.appName} logo',
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 28),
              Text(
                AppConstants.appName.toUpperCase(),
                style: AppTextStyles.body(
                  14,
                  weight: FontWeight.w700,
                  color: AppColors.primary,
                ).copyWith(letterSpacing: 1.2),
              ).entrance(1),
              const SizedBox(height: 10),
              Text(AppStrings.welcomeTitle, style: AppTextStyles.display(36)).entrance(2),
              const SizedBox(height: 12),
              Text(AppStrings.welcomeSubtitle, style: AppTextStyles.bodyLarge).entrance(3),
              const SizedBox(height: 28),
              const FeatureRow(
                icon: Icons.favorite_border_rounded,
                text: 'Heart rate & heart-rate variability',
              ).entrance(4),
              const FeatureRow(icon: Icons.speed_rounded, text: 'Stress level').entrance(5),
              const FeatureRow(icon: Icons.air_rounded, text: 'Breathing rate').entrance(6),
              const FeatureRow(icon: Icons.bloodtype_outlined, text: 'Blood pressure estimate').entrance(7),
              const Spacer(),
              AppButton(
                label: AppStrings.getStarted,
                icon: Icons.arrow_forward_rounded,
                onPressed: () => Get.toNamed(AppRoutes.profileSetup),
              ).entrance(8),
              const SizedBox(height: AppSpacing.md),
              Center(child: Text('Takes about a minute to set up', style: AppTextStyles.caption)).entrance(9),
            ],
          ),
        ),
      ),
    );
  }
}
