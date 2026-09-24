/// All user-facing copy. Written in a calm, reassuring tone for patients.
class AppStrings {
  AppStrings._();

  // Welcome
  static const welcomeTitle = 'Check your vitals with just your fingertip';
  static const welcomeSubtitle = 'Place your finger on the phone camera for 45 seconds. No extra device needed.';
  static const getStarted = 'Get started';

  // Profile
  static const profileTitle = 'Your profile';
  static const profileIntro = 'These details help the app estimate your readings more accurately.';
  static const profileSaved = 'Your profile has been updated.';

  // Consent
  static const consentTitle = 'How your data is used';
  static const consentWellnessTitle = 'For wellness, not diagnosis';
  static const consentWellnessBody =
      'VitaScan is not a medical device. Blood pressure and oxygen values are estimates. Always confirm with a doctor.';
  static const consentCameraTitle = 'Camera only during a scan';
  static const consentCameraBody =
      'The rear camera and flash are used only while you scan. No photos or video are saved.';
  static const consentDataTitle = 'Your data stays yours';
  static const consentDataBody =
      'Readings are stored encrypted on your phone. Cloud backup is optional and off by default.';
  static const consentEmergency =
      'If you feel chest pain, dizziness or shortness of breath, contact emergency services. Don\'t rely on this app.';
  static const consentCheckEstimate = 'I understand readings are estimates for wellness only';
  static const consentCheckTerms = 'I agree to the Terms and Privacy Policy';
  static const consentNeedBoth = 'Please tick both boxes to continue.';

  // Permissions
  static const cameraPermissionTitle = 'Camera access needed';
  static const cameraPermissionBody =
      'VitaScan reads your pulse through the camera and flash. Nothing is recorded or saved.';
  static const cameraPermissionDeniedBody =
      'Camera access is turned off. Open Settings and allow Camera to take a scan.';
  static const openSettings = 'Open Settings';
  static const notNow = 'Not now';

  // Scan guide
  static const scanGuideTitle = 'How to scan';

  // Scan
  static const scanPreparing = 'Getting the camera ready…';
  static const scanPlaceFinger = 'Gently cover the camera and flash with your fingertip';
  static const scanFingerFound = 'Finger detected. Hold still, you\'re doing great.';
  static const scanHoldStill = 'Hold still and keep your finger light on the camera';
  static const scanFingerLost = 'Finger lifted. Place it back on the camera.';
  static const scanAnalyzing = 'Analysing your pulse…';
  static const scanAlmostDone = 'Almost done. Keep breathing normally.';
  static const scanStopTitle = 'Stop this scan?';
  static const scanStopBody = 'Your progress will be lost and nothing will be saved.';
  static const scanStopConfirm = 'Stop scan';
  static const scanKeepGoing = 'Keep scanning';
  static const scanInterruptedBackground = 'The scan stopped because the app went into the background.';
  static const cameraUnavailable = 'We couldn\'t open the rear camera. Close other camera apps and try again.';
  static const noFlash = 'This phone\'s flash could not be turned on. Try scanning in a bright room.';

  // Results
  static const resultSaved = 'Reading saved to your history.';
  static const disclaimerShort =
      'Estimates for wellness tracking, not a diagnosis. BP accuracy improves after you add cuff readings to calibrate.';
  static const highBpWarningTitle = 'This reading is high';
  static const highBpWarningBody =
      'Camera readings are estimates, so please rest for 5 minutes and check again. If it stays high, or you feel unwell, contact a doctor.';
  static const crisisBpWarningBody =
      'This estimate is in a very high range. If you have chest pain, breathlessness, weakness or trouble speaking, call emergency services now. Otherwise, confirm with a BP cuff as soon as possible.';
  static const unusualHrTitle = 'Unusual heart rate';
  static const unusualHrBody =
      'Your resting heart rate looks unusual. Sit quietly for a few minutes and scan again. See a doctor if this keeps happening.';

  // Calibration
  static const calibrationIntro =
      'Had your BP checked at a clinic, pharmacy or on a family member\'s monitor? Enter it here. You can log it on its own, or use it to calibrate your camera estimates.';
  static const calibrationSaved = 'Cuff reading saved.';
  static const calibrationStepSaved = 'Calibration updated. Your BP estimates will now be more personal.';
  static const calibrationComplete = 'Calibration complete! Your future BP estimates are tuned to you.';
  static const calibrationNoRecentScan =
      'To calibrate, take a scan first and enter your cuff reading within 10 minutes.';

  // History / reports
  static const historyEmptyTitle = 'No readings yet';
  static const historyEmptyBody = 'Take your first scan and your results will appear here.';
  static const reportReady = 'Your report is ready.';
  static const reportNoData = 'There are no readings in this period yet.';
  static const reportFailed = 'We couldn\'t create the report. Please try again.';

  // Settings
  static const reminderOnMessage = 'Reminder set. We\'ll nudge you at the right time.';
  static const reminderOffMessage = 'Reminder turned off.';
  static const notificationDenied =
      'Notifications are turned off for VitaScan. Enable them in Settings to get reminders.';
  static const healthSyncOn = 'Health sync is on. New readings will be shared.';
  static const healthSyncFailed =
      'We couldn\'t connect to Health. Make sure Health Connect / Apple Health is installed and allowed.';
  static const backupNotConfigured = 'Cloud backup isn\'t available yet. Your data is safe on this phone.';
  static const exportDone = 'Your data export is ready to share.';
  static const deleteTitle = 'Delete all your data?';
  static const deleteBody =
      'This permanently removes your profile, readings and calibration from this phone. This can\'t be undone.';
  static const deleteConfirm = 'Delete everything';
  static const deleteDone = 'All your data has been deleted.';

  // Reminder notification
  static const reminderNotificationTitle = 'Time for your scan';
  static const reminderNotificationBody = 'Sit, relax for a minute, then take a 45-second fingertip scan.';

  // Generic
  static const somethingWrong = 'Something went wrong. Please try again.';
  static const noInternet = 'No internet connection. Please check your network.';
  static const cancel = 'Cancel';
  static const ok = 'OK';
  static const tryAgain = 'Try again';
  static const backToHome = 'Back to home';
}
