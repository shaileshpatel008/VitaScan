import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/heartbeat.dart';
import '../controllers/main_shell_controller.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current, required this.onSelect, required this.onScan});

  final MainTab current;
  final ValueChanged<MainTab> onSelect;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              _item(MainTab.home, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _item(MainTab.history, Icons.insights_outlined, Icons.insights_rounded, 'History'),
              Expanded(child: _ScanButton(onTap: onScan)),
              _item(MainTab.reports, Icons.description_outlined, Icons.description_rounded, 'Reports'),
              _item(MainTab.profile, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(MainTab tab, IconData icon, IconData activeIcon, String label) {
    final active = tab == current;
    final color = active ? AppColors.primary : AppColors.subtle;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: InkResponse(
          onTap: () => onSelect(tab),
          radius: 36,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: active ? 1.12 : 1,
                duration: AppDurations.medium,
                curve: Curves.easeOutBack,
                child: Icon(active ? activeIcon : icon, color: color, size: 23),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: AppDurations.fast,
                style: AppTextStyles.body(
                  11,
                  color: color,
                  weight: active ? FontWeight.w700 : FontWeight.w500,
                  height: 1.1,
                ),
                child: Text(label),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: AppDurations.medium,
                curve: Curves.easeOutCubic,
                width: active ? 16 : 0,
                height: 3,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Start scan',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Transform.translate(
          offset: const Offset(0, -16),
          child: Center(
            child: Heartbeat(
              bpm: 48,
              amount: 0.05,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 26),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
