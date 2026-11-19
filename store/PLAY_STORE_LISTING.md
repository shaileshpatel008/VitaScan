# Google Play launch guide: Wellumi

Everything needed to publish Wellumi on Google Play, in order. Files referenced here
are in this `store/` folder.

---

## 1. Create your upload key (once, on your Mac)

The upload key signs every release. **Back it up somewhere safe** (password manager +
offline copy). Never commit it to Git (`*.jks` and `key.properties` are already ignored).

```bash
keytool -genkey -v -keystore ~/wellumi-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then copy `android/key.properties.example` to `android/key.properties` and fill in your passwords (this file stays on your Mac only):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/Users/Shailesh/wellumi-upload-keystore.jks
```

Use the absolute path to the `.jks` file. Play Console will offer **Play App Signing**:
accept it. Google then keeps the final app-signing key, and your upload key can be reset
if it's ever lost.

## 2. Build the release bundle

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab`.

Before each new release, raise `version:` in `pubspec.yaml` (e.g. `1.0.0+1` → `1.0.1+2`).
The number after `+` must always increase.

## 3. Store listing (Grow → Store presence → Main store listing)

**App name** (28/30)
```
Wellumi: Heart Rate & Stress
```

**Short description** (73/80)
```
Check heart rate, HRV, stress & breathing with your fingertip and camera.
```

**Full description** (2068/4000)
```
Wellumi turns your phone into a calm daily check-in for your well-being. Place your fingertip over the rear camera and flash for 45 seconds, and Wellumi reads the tiny changes in light caused by your pulse.

WHAT YOU CAN TRACK
• Heart rate: your resting pulse in beats per minute
• Heart-rate variability (HRV): a window into recovery and balance
• Stress level: a simple score based on your HRV and heart rate
• Breathing rate: breaths per minute, estimated from your pulse rhythm
• Blood pressure estimate: a personal trend estimate that improves when you add readings from a home BP cuff

HOW IT WORKS
1. Sit and rest for a minute.
2. Cover the rear camera and flash lightly with your fingertip.
3. Hold still for 45 seconds while Wellumi shows your live pulse wave.
4. See your results, with clear explanations and colour-coded ranges.

DESIGNED TO HELP YOU BUILD A HABIT
• History charts for the last week, month or three months
• Add readings from a blood pressure cuff and calibrate your estimates
• PDF reports to share with your doctor or family
• Gentle morning and evening scan reminders
• Friendly guidance if a scan doesn't go to plan

PRIVATE BY DESIGN
• No account or sign-up needed
• Your readings stay on your phone, encrypted
• No ads, no tracking, no data selling
• Camera images are never saved: only the light level is used
• Export or delete all your data at any time

DEVICE COMPATIBILITY
Wellumi needs Android 8.0 or later and a phone with a rear camera and flash (LED torch). Results depend on your phone's camera and on following the scan steps; most modern phones work well.

IMPORTANT
Wellumi is a wellness app, not a medical device. It does not diagnose, treat, cure or prevent any disease. All readings, including the blood pressure estimate, are estimates for personal tracking and may differ from medical devices. Always consult a doctor about your health and before making any medical decision. If you feel unwell, have chest pain or shortness of breath, contact emergency services immediately.

Wellumi is for adults aged 18 and over.
```

**Graphics**

| Asset | File | Notes |
|---|---|---|
| App icon 512×512 | `store/app_icon_512.png` | Play applies its own rounded mask |
| Feature graphic 1024×500 | `store/feature_graphic_1024x500.png` | |
| Phone screenshots | take on a real phone | 2–8 images, portrait. Suggested: Home, Scan in progress, Results, History, Reports |

Screenshot tips: use sample readings in the normal range, and don't add text that
claims medical accuracy.

**Category:** Health & Fitness. **Contact email:** the same support email as the privacy
policy. **Website:** your GitHub Pages index (optional).

## 4. App content (Policy → App content)

| Form | Answer |
|---|---|
| **Privacy policy** | `https://shaileshpatel008.github.io/VitaScan/docs/privacy-policy.html` (published from this repo's `docs/` folder; see `docs/README.md`) |
| **Ads** | No, the app does not contain ads |
| **App access** | All functionality is available without special access (no login) |
| **Content rating** | Fill in the IARC questionnaire honestly; Wellumi has no violence, sexual content, gambling, user chat or purchases. Expect "Everyone"/"3+" |
| **Target audience** | 18 and over only |
| **News app** | No |
| **Government app** | No |
| **Financial features** | None |
| **Health apps declaration** | Required. Select the options that describe health/wellness tracking of vital signs (heart rate, stress, breathing, blood pressure estimates). State that the app is **not** a regulated medical device and that it does **not** use Health Connect in this version |
| **Data safety** | See section 5 |

## 5. Data safety form

Google counts data as "collected" only when it's **sent off the device**. Wellumi keeps
everything on the phone, has no server, no analytics and no ads, and fonts are bundled.
Exports and shares happen only when the user chooses them through the share sheet.

- **Does your app collect or share any of the required user data types?** → **No**
- Answer this again if you ever add analytics, crash reporting, cloud backup,
  Health Connect sync or any SDK that sends data.

## 6. Release

Your account was created before November 2023, so the 12-tester / 14-day closed test does
**not** apply. Recommended path:

1. **Testing → Internal testing:** upload the `.aab`, add yourself and a few testers by
   email, install from the Play link, and check: scan on 2–3 different phones, reminders,
   PDF report, and **Profile → Check for updates**.
2. **Production → Create new release:** promote the same build. Release notes example:
   ```
   Welcome to Wellumi! Check your heart rate, HRV, stress and breathing in 45 seconds
   with your fingertip and phone camera.
   ```
3. Choose countries, then **Send for review**. Reviews of health apps can take several
   days; reply promptly to any policy email from Google.

## 7. Before submitting: checklist

- [ ] Legal pages live (`docs/README.md`); contact email added
- [ ] Upload key created and backed up; `android/key.properties` in place
- [ ] Version number raised if a build was uploaded before
- [ ] Tested an internal-testing install on real phones
- [ ] Screenshots taken
- [ ] All App content forms completed (Play Console shows green ticks)
