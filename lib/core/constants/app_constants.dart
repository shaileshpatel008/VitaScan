/// App-wide tunable values. Everything that affects measurement lives here so
/// it can be tuned after real-device testing without touching the algorithms.
class AppConstants {
  AppConstants._();

  static const String appName = 'Wellumi';
  static const String appVersion = '1.0.1';
  static const String androidPackageName = 'com.shaileshpatel008.wellumiapp';

  // ---------------- Feature switches ----------------
  /// Health Connect / Apple Health sync. Hidden in v1: turning it on also needs
  /// the Android health permissions restored (see AndroidManifest.xml) and the
  /// Play Console Health Connect declaration.
  static const bool enableHealthSync = false;

  /// Cloud backup needs a server ([backupBaseUrl]); hidden until one exists.
  static const bool enableCloudBackup = false;

  /// Camera SpO2 is the least reliable estimate; hidden for the first release.
  static const bool showSpo2Estimate = false;

  // ---------------- Premium (in-app purchases) ----------------
  /// Successful scans allowed before Premium is required.
  static const int freeScanLimit = 3;

  /// Product IDs: create these exact IDs in Play Console → Monetize.
  static const String premiumMonthlyId = 'wellumi_premium_monthly';
  static const String premiumYearlyId = 'wellumi_premium_yearly';
  static const String premiumLifetimeId = 'wellumi_premium_lifetime';
  static const Set<String> premiumProductIds = {premiumMonthlyId, premiumYearlyId, premiumLifetimeId};

  // ---------------- Legal ----------------
  /// Public pages hosted on GitHub Pages (docs/ folder; see docs/README.md).
  static const String privacyPolicyUrl = 'https://shaileshpatel008.github.io/VitaScan/docs/privacy-policy.html';
  static const String termsUrl = 'https://shaileshpatel008.github.io/VitaScan/docs/terms.html';

  // ---------------- Scan ----------------
  /// Seconds of good finger contact needed for one measurement.
  static const int scanDurationSeconds = 45;

  /// First seconds after contact are discarded while auto-exposure settles.
  static const double warmupSeconds = 3.0;

  /// Finger must be detected continuously this long before the timer starts.
  static const double fingerHoldToStartSeconds = 1.0;

  /// The scan fails if the finger is lifted for longer than this.
  static const double maxFingerLostSeconds = 4.0;

  /// Frame-level finger detection: with the torch on, a covered lens sees a
  /// bright, strongly red image.
  static const double fingerMinRed = 60;
  static const double fingerRedDominance = 1.6;

  /// Requested camera frame rate. Analysis resamples to [analysisFs].
  static const int cameraFps = 30;
  static const double analysisFs = 30.0;

  /// Live heart rate starts updating after this many seconds of data.
  static const double liveHrMinSeconds = 8.0;
  static const double liveHrWindowSeconds = 10.0;

  // ---------------- Analysis quality gates ----------------
  static const int minValidBeats = 8;
  static const double minValidBeatRatio = 0.6;
  static const int minSignalQuality = 45;
  static const double minPerfusionIndex = 0.03;
  static const double minEffectiveFps = 10.0;

  // ---------------- Calibration ----------------
  static const int calibrationTargetReadings = 3;
  static const int calibrationMaxGapMinutes = 10;

  // ---------------- SpO2 (ratio-of-ratios, red / blue channel) ----------------
  static const double spo2CoefA = 100.0;
  static const double spo2CoefB = 5.0;

  // ---------------- Reminders ----------------
  static const int defaultMorningReminderMinutes = 8 * 60;
  static const int defaultEveningReminderMinutes = 20 * 60;

  // ---------------- Cloud backup (optional) ----------------
  /// Leave empty to keep the app 100% offline. Set to your API to enable backup.
  static const String backupBaseUrl = '';

  // ---------------- App updates ----------------
  /// Optional JSON file you host (your website, GitHub Pages, etc.) to force an
  /// update: {"android": {"min_version": "1.2.0"}, "ios": {"min_version": "1.2.0"},
  /// "message": "..."}. Leave empty to rely on the stores only.
  static const String updateConfigUrl = '';

  /// After "Later", don't ask about the same version again for this long.
  static const int updateRemindAfterHours = 24;
}
