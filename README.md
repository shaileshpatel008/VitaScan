# VitaScan: fingertip vitals app (Flutter + GetX)

VitaScan reads the pulse through the phone's **rear camera and flash** (photoplethysmography, PPG).
It needs no hardware and no paid APIs. Users can also enter readings from a BP cuff, which are stored
and used to **calibrate** the BP estimate for that person.

| Measure | How | Shown as |
|---|---|---|
| Heart rate | Peaks in the camera pulse signal | Reliable |
| HRV (RMSSD) & stress | Beat-to-beat timing | Good |
| Breathing rate | Respiratory modulation of beat spacing / amplitude | Approximate |
| Blood pressure | Pulse-shape model + profile + personal cuff calibration | **Estimate** label |
| SpO₂ | Red/blue ratio-of-ratios | **Beta** label |

> VitaScan is a **wellness** app, not a medical device. Keep the "Estimate"/"Beta" labels and the
> disclaimers, and avoid medical claims in store listings.

---

## Run it

```bash
flutter pub get
flutter test          # 20 unit tests for the signal-processing engine
flutter run           # on a REAL phone (emulators have no camera torch)
```

Requirements: Flutter 3.47+ / Dart 3.13+, Android 8.0+ (API 26), iOS 14+.

### iOS one-time setup
1. After the first `flutter build ios` creates `ios/Podfile`, add the permission macros inside
   `post_install` (required by `permission_handler`):
   ```ruby
   post_install do |installer|
     installer.pods_project.targets.each do |target|
       flutter_additional_ios_build_settings(target)
       target.build_configurations.each do |config|
         config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
           '$(inherited)',
           'PERMISSION_CAMERA=1',
           'PERMISSION_NOTIFICATIONS=1',
         ]
       end
     end
   end
   ```
2. In Xcode → Runner → *Signing & Capabilities*, add **HealthKit** (only needed for Apple Health sync).

Camera/Health usage texts are already in `ios/Runner/Info.plist`. Android permissions, Health Connect
declarations, reminder receivers, `minSdk 26`, core-library desugaring and `FlutterFragmentActivity`
are already configured.

---

## Project structure

```
lib/
├── core/
│   ├── constants/     app_constants (all tunables), app_strings (all patient-facing copy), storage_keys
│   ├── utils/         app_messenger (snackbars/dialogs), validators, health_classifier, logger
│   │   └── ppg/       signal engine: filters, peak detector, analyzer, vitals estimator, frame colour extractor
│   ├── extensions/    DateTime, BuildContext, num, String helpers
│   ├── network/       GetConnect ApiClient, endpoints, ApiException, NetworkInfo (optional cloud backup)
│   └── services/      camera PPG, encrypted storage, permissions, reminders, Health sync, PDF, CSV, DI
├── data/
│   ├── models/        UserProfile, VitalReading, CalibrationPoint, AppSettings
│   ├── datasources/   LocalDataSource (encrypted Hive), RemoteBackupDataSource
│   └── repositories/  reactive GetxService repositories (readings, user, settings, calibration, backup)
├── modules/           each with bindings / controllers / models / views / widgets as needed
│   ├── splash/  welcome/  profile_setup/  consent/
│   ├── main_shell/    bottom navigation + centre scan button
│   ├── home/  history/  reports/  settings/
│   ├── scan_guide/    animated "how to place your finger"
│   ├── scan/          live scan (camera, progress ring, waveform) + poor-signal screen
│   ├── result/        results with animated counters and BP range bar
│   └── calibration/   cuff reading entry + calibration
├── routes/            AppRoutes + AppPages (GetX routing with bindings)
├── widgets/           shared animated UI (buttons, cards, counters, heartbeat, segmented control…)
├── theme/             colours, typography (Fraunces + DM Sans), spacing, ThemeData
└── main.dart
```

---

## How a scan works

1. **Capture**: `CameraPpgService` opens the rear camera (low resolution, 30 fps), turns the torch on,
   and reduces each frame to the average R/G/B of its centre (`FrameColorExtractor`, handles
   Android YUV420/NV21 and iOS BGRA).
2. **Finger detection**: a covered lens is bright and strongly red (`fingerMinRed`,
   `fingerRedDominance`). The 45 s timer runs only while the finger is on. Lifting it for more than
   4 s stops the scan with a friendly message.
3. **Live feedback**: every 100 ms the waveform updates, and every second a live heart rate and
   signal quality are computed from the last 10 s.
4. **Analysis** (in a background isolate, `PpgAnalyzer.analyze`):
   - resample to a uniform 30 Hz, zero-phase band-pass (0.6–3.3 Hz), invert
   - peak detection with sub-frame (parabolic) timing, then outlier rejection of beat intervals
   - HR = median interval, HRV = RMSSD/SDNN, breathing = dominant 0.1–0.5 Hz rhythm in beat
     spacing/amplitude, SpO₂ = ratio-of-ratios
   - **quality gate**: beat consistency, regularity, spectral clarity, perfusion. Weak or noisy
     signals are **rejected** rather than producing made-up numbers (covered by tests).
5. **BP estimate** (`VitalsEstimator`): a transparent linear baseline (age, BMI, sex, known
   hypertension, HR, pulse rise time, reflected-wave index), then shifted by the mean offset of the
   user's last three cuff calibrations.

### Accuracy and tuning (important)
- The BP coefficients are a **starting baseline**. Collect paired scan + cuff readings from test
  users, then re-fit the coefficients in `vitals_estimator.dart`. Personal calibration already
  removes most of the per-user bias.
- Test on 5–8 real Android and iOS phones. Camera and torch behaviour differs by model. Tune
  `AppConstants` (finger thresholds, quality gates, SpO₂ coefficients).
- Irregular heart rhythms (e.g. atrial fibrillation) intentionally fail the regularity check and
  ask the user to retry.

---

## Patient-friendly UX
- All copy lives in `AppStrings`. Snackbars and dialogs go through `AppMessenger` (success, info,
  warning, error, confirm, health alert) with haptics.
- Health alerts after a scan: very high BP (urgent guidance), stage-2 BP, unusual resting HR, and a
  calibration tip for new users.
- Animations: heartbeat-synced icons, pulse halos, finger-placement illustration, animated progress
  ring and waveform, count-up values, sliding BP marker, staggered entrances, animated nav and
  segmented controls. Animations respect the system "reduce motion" setting.
- Text scaling is supported up to 130%, touch targets are at least 44 px, and screen-reader labels
  are on icons and charts.

## Privacy
- Data is stored in AES-encrypted Hive boxes. The key is kept in the Android Keystore / iOS Keychain.
- No network use unless `AppConstants.backupBaseUrl` is set (cloud backup is optional).
- Camera BP estimates are **not** written to Health Connect / Apple Health; only HR, breathing
  rate and cuff BP are.
- Users can export everything (CSV) or delete everything from Profile.
