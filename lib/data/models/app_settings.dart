import '../../core/constants/app_constants.dart';

class AppSettings {
  const AppSettings({
    this.onboardingComplete = false,
    this.consentAcceptedAt,
    this.morningReminderEnabled = false,
    this.morningReminderMinutes = AppConstants.defaultMorningReminderMinutes,
    this.eveningReminderEnabled = false,
    this.eveningReminderMinutes = AppConstants.defaultEveningReminderMinutes,
    this.healthSyncEnabled = false,
    this.cloudBackupEnabled = false,
  });

  final bool onboardingComplete;
  final DateTime? consentAcceptedAt;
  final bool morningReminderEnabled;

  /// Minutes after midnight.
  final int morningReminderMinutes;
  final bool eveningReminderEnabled;
  final int eveningReminderMinutes;
  final bool healthSyncEnabled;
  final bool cloudBackupEnabled;

  bool get consentAccepted => consentAcceptedAt != null;

  AppSettings copyWith({
    bool? onboardingComplete,
    DateTime? consentAcceptedAt,
    bool? morningReminderEnabled,
    int? morningReminderMinutes,
    bool? eveningReminderEnabled,
    int? eveningReminderMinutes,
    bool? healthSyncEnabled,
    bool? cloudBackupEnabled,
  }) => AppSettings(
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    consentAcceptedAt: consentAcceptedAt ?? this.consentAcceptedAt,
    morningReminderEnabled: morningReminderEnabled ?? this.morningReminderEnabled,
    morningReminderMinutes: morningReminderMinutes ?? this.morningReminderMinutes,
    eveningReminderEnabled: eveningReminderEnabled ?? this.eveningReminderEnabled,
    eveningReminderMinutes: eveningReminderMinutes ?? this.eveningReminderMinutes,
    healthSyncEnabled: healthSyncEnabled ?? this.healthSyncEnabled,
    cloudBackupEnabled: cloudBackupEnabled ?? this.cloudBackupEnabled,
  );

  Map<String, dynamic> toMap() => {
    'onboardingComplete': onboardingComplete,
    'consentAcceptedAt': consentAcceptedAt?.toIso8601String(),
    'morningReminderEnabled': morningReminderEnabled,
    'morningReminderMinutes': morningReminderMinutes,
    'eveningReminderEnabled': eveningReminderEnabled,
    'eveningReminderMinutes': eveningReminderMinutes,
    'healthSyncEnabled': healthSyncEnabled,
    'cloudBackupEnabled': cloudBackupEnabled,
  };

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) => AppSettings(
    onboardingComplete: map['onboardingComplete'] as bool? ?? false,
    consentAcceptedAt: DateTime.tryParse(map['consentAcceptedAt'] as String? ?? ''),
    morningReminderEnabled: map['morningReminderEnabled'] as bool? ?? false,
    morningReminderMinutes:
        (map['morningReminderMinutes'] as num?)?.toInt() ?? AppConstants.defaultMorningReminderMinutes,
    eveningReminderEnabled: map['eveningReminderEnabled'] as bool? ?? false,
    eveningReminderMinutes:
        (map['eveningReminderMinutes'] as num?)?.toInt() ?? AppConstants.defaultEveningReminderMinutes,
    healthSyncEnabled: map['healthSyncEnabled'] as bool? ?? false,
    cloudBackupEnabled: map['cloudBackupEnabled'] as bool? ?? false,
  );
}
