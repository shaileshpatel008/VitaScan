import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/health_sync_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/app_messenger.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/backup_repository.dart';
import '../../../data/repositories/calibration_repository.dart';
import '../../../data/repositories/reading_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../routes/app_routes.dart';

class SettingsController extends GetxController {
  SettingsController({
    required this._users,
    required this._settings,
    required this._readings,
    required this._calibration,
    required this._backup,
    required this._storage,
    required this._notifications,
    required this._health,
    required this._export,
    required this._updates,
  });

  final UserRepository _users;
  final SettingsRepository _settings;
  final ReadingRepository _readings;
  final CalibrationRepository _calibration;
  final BackupRepository _backup;
  final StorageService _storage;
  final NotificationService _notifications;
  final HealthSyncService _health;
  final ExportService _export;
  final AppUpdateService _updates;

  final busy = false.obs;

  UserProfile? get profile => _users.profile.value;
  AppSettings get settings => _settings.settings.value;
  int get calibrationCount => _calibration.points.length;
  int get readingCount => _readings.readings.length;
  String get appVersion => _updates.version.value;
  String get buildNumber => _updates.buildNumber.value;
  bool get checkingUpdate => _updates.checking.value;

  void checkForUpdates() => _updates.checkManually();

  void editProfile() => Get.toNamed(AppRoutes.profileSetup, arguments: true);

  void openCalibration() => Get.toNamed(AppRoutes.calibration);

  // ---------------- Reminders ----------------

  Future<void> toggleReminder({required bool morning, required bool enabled}) async {
    final id = morning ? NotificationService.morningId : NotificationService.eveningId;
    final minutes = morning ? settings.morningReminderMinutes : settings.eveningReminderMinutes;
    if (enabled) {
      final granted = await _notifications.requestPermission();
      if (!granted) {
        AppMessenger.warning(AppStrings.notificationDenied, title: 'Notifications are off');
        return;
      }
      try {
        await _notifications.scheduleDaily(id: id, minutesOfDay: minutes);
      } catch (e, st) {
        AppLogger.error('Scheduling reminder failed', e, st);
        AppMessenger.error(AppStrings.somethingWrong);
        return;
      }
      AppMessenger.success(
        AppStrings.reminderOnMessage,
        title: morning ? 'Morning reminder on' : 'Evening reminder on',
      );
    } else {
      await _notifications.cancel(id);
      AppMessenger.info(AppStrings.reminderOffMessage, title: 'Reminder off');
    }
    await _settings.update(
      (s) => morning ? s.copyWith(morningReminderEnabled: enabled) : s.copyWith(eveningReminderEnabled: enabled),
    );
  }

  Future<void> pickReminderTime(BuildContext context, {required bool morning}) async {
    final current = morning ? settings.morningReminderMinutes : settings.eveningReminderMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: morning ? 'Morning reminder' : 'Evening reminder',
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    await _settings.update(
      (s) => morning ? s.copyWith(morningReminderMinutes: minutes) : s.copyWith(eveningReminderMinutes: minutes),
    );
    final enabled = morning ? settings.morningReminderEnabled : settings.eveningReminderEnabled;
    if (enabled) {
      await _notifications.scheduleDaily(
        id: morning ? NotificationService.morningId : NotificationService.eveningId,
        minutesOfDay: minutes,
      );
      AppMessenger.success('We\'ll remind you at ${picked.format(Get.context!)}.', title: 'Reminder updated');
    }
  }

  // ---------------- Data ----------------

  Future<void> toggleHealthSync(bool enabled) async {
    if (enabled) {
      busy.value = true;
      final ok = await _health.connect();
      busy.value = false;
      if (!ok) {
        AppMessenger.error(AppStrings.healthSyncFailed, title: 'Couldn\'t connect');
        return;
      }
      AppMessenger.success(AppStrings.healthSyncOn, title: 'Connected');
    }
    await _settings.update((s) => s.copyWith(healthSyncEnabled: enabled));
  }

  Future<void> toggleBackup(bool enabled) async {
    if (!enabled) {
      await _settings.update((s) => s.copyWith(cloudBackupEnabled: false));
      return;
    }
    if (!_backup.isAvailable) {
      AppMessenger.info(AppStrings.backupNotConfigured, title: 'Coming soon');
      return;
    }
    busy.value = true;
    try {
      await _backup.backupNow();
      await _settings.update((s) => s.copyWith(cloudBackupEnabled: true));
      AppMessenger.success('Your data is backed up securely.', title: 'Backup complete');
    } on ApiException catch (e) {
      AppMessenger.error(e.message, title: 'Backup failed');
    } finally {
      busy.value = false;
    }
  }

  Future<void> exportCsv() async {
    if (_readings.readings.isEmpty) {
      AppMessenger.info('There are no readings to export yet.', title: 'Nothing to export');
      return;
    }
    try {
      await _export.shareCsv(_readings.readings);
      AppMessenger.success(AppStrings.exportDone, title: 'Export ready');
    } catch (e, st) {
      AppLogger.error('Export failed', e, st);
      AppMessenger.error(AppStrings.somethingWrong);
    }
  }

  Future<void> deleteAllData() async {
    final ok = await AppMessenger.confirm(
      title: AppStrings.deleteTitle,
      message: AppStrings.deleteBody,
      confirmText: AppStrings.deleteConfirm,
      destructive: true,
      icon: Icons.delete_forever_rounded,
    );
    if (!ok) return;
    await _notifications.cancelAll();
    await _storage.clearAll();
    _users.clear();
    _readings.clear();
    _calibration.clear();
    await _settings.reset();
    Get.offAllNamed(AppRoutes.welcome);
    AppMessenger.success(AppStrings.deleteDone, title: 'Data deleted');
  }

  void showAbout() {
    AppMessenger.alert(
      title: '${AppConstants.appName} ${AppConstants.appVersion}',
      message:
          'VitaScan estimates heart rate, heart-rate variability, stress, breathing rate, oxygen and blood pressure '
          'from your fingertip using the phone camera.\n\n'
          'It is a wellness app, not a medical device. It does not diagnose or treat any condition. '
          'Always follow your doctor\'s advice and use a validated cuff for medical decisions.',
      buttonText: 'Close',
    );
  }
}
