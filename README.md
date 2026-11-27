# Wellumi: fingertip vitals app (Flutter + GetX)

Wellumi reads the pulse through the phone's **rear camera and flash** (photoplethysmography, PPG).
It needs no hardware and no paid APIs. Users can also enter readings from a BP cuff, which are stored
and used to **calibrate** the BP estimate for that person.

| Measure | How | Shown as |
|---|---|---|
| Heart rate | Peaks in the camera pulse signal | Reliable |
| HRV (RMSSD) & stress | Beat-to-beat timing | Good |
| Breathing rate | Respiratory modulation of beat spacing / amplitude | Approximate |
| Blood pressure | Pulse-shape model + profile + personal cuff calibration | **Estimate** label |
| SpO₂ | Red/blue ratio-of-ratios | **Beta** label |

> Wellumi is a **wellness** app, not a medical device. Keep the "Estimate"/"Beta" labels and the
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

---

## Releasing updates

The app checks for updates about 3 seconds after the home screen opens, and from
**Profile → Check for updates**.

| Platform | Optional update | Required update |
|---|---|---|
| Android | Downloads in the background inside the app, then asks the user to restart | Play's full-screen update screen |
| iOS | Dialog with release notes and an **Update now** button that opens the App Store | Same dialog with no "Later" button |

**How to trigger each one**
1. **Normal release:** raise `version:` in `pubspec.yaml` (for example `1.0.1+2`) and publish. Users
   see the optional prompt. Choosing "Later" hides it for 24 h.
2. **Required on Android:** set the release's *in-app update priority* to **4 or 5**. Priority can
   only be set with the Play Developer API (`inAppUpdatePriority`), not in the Play Console UI.
3. **Required on both platforms:** host a JSON file and set `AppConstants.updateConfigUrl` to it:
   ```json
   { "android": { "min_version": "1.2.0" }, "ios": { "min_version": "1.2.0" } }
   ```
   Any installed version below `min_version` must update before it can be used.

**Notes**
- In-app updates on Android only work when the app was installed **from Google Play**. To test,
  use Play's internal app sharing or an internal-testing track. Debug and side-loaded builds skip
  the automatic check, and the manual check says why.
- The App Store lookup can lag a few hours behind a new release.
- Phones with store auto-update turned on still update the app on their own, as usual.

---

## Branding

Artwork lives in `assets/branding/` (SVG sources in `assets/branding/src/`, rendered PNGs next to them,
`branding_preview.png` shows every variant). After changing the artwork, regenerate the platform files:

```bash
dart run flutter_launcher_icons        # app icons (iOS, Android adaptive + themed)
dart run flutter_native_splash:create  # launch splash (iOS, Android incl. Android 12+)
```

`flutter_native_splash` reformats `AndroidManifest.xml` and can drop
`android:screenOrientation="portrait"`; check that line is still there afterwards.

---

## Feature switches (`lib/core/constants/app_constants.dart`)

| Switch | v1 value | What it controls |
|---|---|---|
| `enableHealthSync` | `false` | Health Connect / Apple Health sync and its Profile toggle |
| `enableCloudBackup` | `false` | Cloud backup toggle (needs `backupBaseUrl` and a server) |
| `showSpo2Estimate` | `false` | Camera SpO₂ estimate in results, PDF and stored readings |

### Re-enabling Health Connect (Android)

1. Set `enableHealthSync = true`.
2. In `android/app/src/main/AndroidManifest.xml`, change each health permission that has
   `tools:node="remove"` into a normal declaration, keeping only the **WRITE**
   permissions (the app never reads from Health Connect):
   `WRITE_HEART_RATE`, `WRITE_RESPIRATORY_RATE`, `WRITE_BLOOD_PRESSURE`.
3. Add back, inside `<application>`, the activity-alias Health Connect uses to show
   your privacy policy, and add to `<queries>` the Health Connect package:
   ```xml
   <activity-alias
       android:name="ViewPermissionUsageActivity"
       android:exported="true"
       android:targetActivity=".MainActivity"
       android:permission="android.permission.START_VIEW_PERMISSION_USAGE">
       <intent-filter>
           <action android:name="android.intent.action.VIEW_PERMISSION_USAGE"/>
           <category android:name="android.intent.category.HEALTH_PERMISSIONS"/>
       </intent-filter>
   </activity-alias>
   ```
   ```xml
   <package android:name="com.google.android.apps.healthdata"/>
   ```
   Make the app show the privacy policy when opened this way.
4. Update the privacy policy, then complete the Health Connect questions in Play
   Console's Health apps declaration before releasing.

---

## Wellumi Premium (in-app purchases, no login)

- `PurchaseService` (`lib/core/services/purchase_service.dart`) uses Google Play Billing /
  StoreKit through `in_app_purchase`. Purchases belong to the user's store account, so no
  login is needed and they restore on reinstall or a new phone.
- Products: `wellumi_premium_monthly`, `wellumi_premium_yearly` (subscriptions) and
  `wellumi_premium_lifetime` (one-time). Free scans: `AppConstants.freeScanLimit` (3).
- `ScanGateMiddleware` guards the scan routes and opens `/premium` once free scans are used.
  Only successful scans count; the counter lives in secure storage.
- Android re-checks active purchases on each launch, so expired subscriptions end
  automatically. **Before an iOS launch** add receipt validation (server or RevenueCat):
  StoreKit restores also return expired subscriptions.
- Play Console setup and testing: `store/PLAY_STORE_LISTING.md` section 4b.

## Ratings prompt

Wellumi asks for a Play Store rating with Google's in-app review dialog
(`ReviewService`, rules in `core/utils/review_policy.dart`):

- only after a clear (signal quality 70%+), calm result: never after a high BP or unusual heart-rate warning
- first on the 2nd good scan, then at most once every 90 days, 3 times in total
- never on the scan that used the last free scan (the Premium notice shows instead)
- Google Play applies its own quota, so the dialog may not appear every time

Settings → **Rate Wellumi** always opens the store page. The dialog only appears in builds
installed from Google Play (internal testing works); it never shows with `flutter run`.

## Publishing

- Google Play: step-by-step guide, listing text and form answers in
  [`store/PLAY_STORE_LISTING.md`](store/PLAY_STORE_LISTING.md).
- Privacy Policy & Terms pages: [`docs/README.md`](docs/README.md).