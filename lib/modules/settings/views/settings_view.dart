import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/datetime_extensions.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/entrance.dart';
import '../controllers/settings_controller.dart';
import '../widgets/settings_tile.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return SafeArea(
      bottom: false,
      child: Obx(() {
        final p = c.profile;
        final s = c.settings;
        final chevron = const Icon(Icons.chevron_right_rounded, color: AppColors.muted);
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 16, AppSpacing.screen, 24),
          children: [
            Text('Profile', style: AppTextStyles.display(28)),
            const SizedBox(height: 14),
            AppCard(
              onTap: c.editProfile,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      p?.initials ?? '?',
                      style: AppTextStyles.body(18, weight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p?.name ?? 'Your profile', style: AppTextStyles.body(16, weight: FontWeight.w600)),
                        if (p != null)
                          Text(
                            '${p.age} yrs · ${p.heightCm.toStringAsFixed(0)} cm · ${p.weightKg.toStringAsFixed(0)} kg',
                            style: AppTextStyles.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    'Edit',
                    style: AppTextStyles.body(14, weight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
            ).entrance(0),
            const SectionLabel('Reminders'),
            SettingsTile(
              icon: Icons.wb_sunny_outlined,
              title: 'Morning scan',
              subtitle: 'Every day, ${s.morningReminderMinutes.asTimeOfDay} · tap to change',
              onTap: () => c.pickReminderTime(context, morning: true),
              trailing: Switch(
                value: s.morningReminderEnabled,
                onChanged: (v) => c.toggleReminder(morning: true, enabled: v),
              ),
            ).entrance(1),
            SettingsTile(
              icon: Icons.nights_stay_outlined,
              title: 'Evening scan',
              subtitle: 'Every day, ${s.eveningReminderMinutes.asTimeOfDay} · tap to change',
              onTap: () => c.pickReminderTime(context, morning: false),
              trailing: Switch(
                value: s.eveningReminderEnabled,
                onChanged: (v) => c.toggleReminder(morning: false, enabled: v),
              ),
            ).entrance(2),
            const SectionLabel('Data'),
            if (AppConstants.enableHealthSync)
              SettingsTile(
                icon: Icons.sync_rounded,
                title: 'Sync with Health Connect / Apple Health',
                subtitle: 'Heart rate, breathing & cuff BP',
                trailing: c.busy.value
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : Switch(value: s.healthSyncEnabled, onChanged: c.toggleHealthSync),
              ).entrance(3),
            if (AppConstants.enableCloudBackup)
              SettingsTile(
                icon: Icons.cloud_outlined,
                title: 'Cloud backup',
                subtitle: s.cloudBackupEnabled ? 'On' : 'Off: data stays on this phone',
                trailing: Switch(value: s.cloudBackupEnabled, onChanged: c.toggleBackup),
              ).entrance(4),
            SettingsTile(
              icon: Icons.track_changes_rounded,
              title: 'BP calibration',
              subtitle: c.calibrationCount >= AppConstants.calibrationTargetReadings
                  ? 'Calibrated · ${c.calibrationCount} cuff readings'
                  : '${c.calibrationCount} of ${AppConstants.calibrationTargetReadings} cuff readings',
              onTap: c.openCalibration,
              trailing: chevron,
            ).entrance(5),
            SettingsTile(
              icon: Icons.file_download_outlined,
              title: 'Export all data (CSV)',
              subtitle: '${c.readingCount} readings',
              onTap: c.exportCsv,
              trailing: chevron,
            ).entrance(6),
            SettingsTile(
              icon: Icons.delete_outline_rounded,
              title: 'Delete all my data',
              destructive: true,
              onTap: c.deleteAllData,
            ).entrance(7),
            const SectionLabel('About'),
            SettingsTile(
              icon: Icons.system_update_rounded,
              title: 'Check for updates',
              subtitle: 'Version ${c.appVersion}',
              onTap: c.checkingUpdate ? null : c.checkForUpdates,
              trailing: c.checkingUpdate
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : chevron,
            ).entrance(8),
            SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About & medical disclaimer',
              onTap: c.showAbout,
              trailing: chevron,
            ).entrance(9),
            SettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy policy',
              onTap: c.openPrivacyPolicy,
              trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.muted),
            ).entrance(10),
            SettingsTile(
              icon: Icons.description_outlined,
              title: 'Terms of use',
              onTap: c.openTerms,
              trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.muted),
            ).entrance(11),
            SettingsTile(
              icon: Icons.code_rounded,
              title: 'Open-source licences',
              onTap: () => c.showLicences(context),
              trailing: chevron,
            ).entrance(12),
            const SizedBox(height: 16),
            Text(
              '${AppConstants.appName} v${c.appVersion} (${c.buildNumber}) · For wellness use only, not a medical device.',
              style: AppTextStyles.caption,
            ),
          ],
        );
      }),
    );
  }
}
