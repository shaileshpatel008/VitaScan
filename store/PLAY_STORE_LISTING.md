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

**Short description** (76/80)
```
Check heart rate, HRV, stress & breathing in 45 seconds with your fingertip.
```

**Full description** (3527/4000)
```
Wellumi turns your phone into a calm, private daily check-in for your well-being. Rest your fingertip on the rear camera and flash for 45 seconds, and Wellumi reads the tiny changes in light caused by each heartbeat. No wearable, no extra device, no sign-up.

WHAT YOU CAN CHECK
• Heart rate: your resting pulse in beats per minute
• Heart-rate variability (HRV): an insight into recovery and balance
• Stress level: a simple Low / Moderate / High score based on your HRV and heart rate
• Breathing rate: breaths per minute, estimated from your pulse rhythm
• Blood pressure estimate: a personal trend estimate that becomes more tailored to you as you add readings from a home BP cuff

A GUIDED, STRESS-FREE SCAN
• Step-by-step animated guide showing exactly where to place your finger
• The scan starts by itself once your fingertip is detected
• Watch your live pulse wave and heart rate while you scan
• Real-time signal check, with gentle prompts if your finger moves
• If a reading isn't clear, Wellumi explains why and how to fix it, instead of showing a wrong number

CLEAR, EASY-TO-READ RESULTS
• Large, simple numbers with plain-language explanations
• Colour-coded blood pressure scale from normal to high
• Helpful guidance if a reading looks unusual, including when to talk to a doctor

TRACK YOUR TRENDS
• History charts for the last week, month or three months
• Every reading saved with its date, time and source (scan or cuff)
• Weekly trend at a glance on your home screen
• Daily wellness tips to help you get more consistent readings

ADD CUFF READINGS AND CALIBRATE
• Log blood pressure and pulse from any home or pharmacy BP cuff
• Enter a cuff reading within 10 minutes of a scan to calibrate your camera estimate
• After three calibrations, your blood pressure estimates are tuned to you

REPORTS AND REMINDERS
• Create a clean PDF health summary for the last 7 days, 30 days or any dates you choose
• Share it with your doctor or family, or save and print it
• Morning and evening reminders at times you choose, to build a daily habit
• Export all your readings as a CSV file at any time

FREE TO TRY, PREMIUM TO GO FURTHER
• Your first 3 scans are free
• Wellumi Premium unlocks unlimited scans and an ad-free experience
• Choose a monthly or yearly subscription, or a one-time lifetime purchase
• Your history, cuff readings, reports and data export always stay available
• Purchases are restored with your Google account; no sign-up needed

PRIVATE BY DESIGN
• No account or sign-up needed
• Your readings stay on your phone, encrypted
• No ads, no tracking and no data selling
• Camera images are never saved: only the light level is used, during the scan
• Works offline
• Delete all your data at any time from Profile

DEVICE COMPATIBILITY
Wellumi needs Android 8.0 or later and a phone with a rear camera and flash (LED torch). Results depend on your phone's camera and on following the scan steps; most modern phones work well. For the best readings, sit still, rest for a minute first, and touch the camera lightly.

IMPORTANT
Wellumi is a wellness app, not a medical device. It does not diagnose, treat, cure or prevent any disease. All readings, including the blood pressure estimate, are estimates for personal tracking and may differ from medical devices. Always consult a doctor about your health and before making any medical decision. If you feel unwell, or have chest pain or shortness of breath, contact emergency services immediately.

Wellumi is designed for adults aged 18 and over.
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

## 4b. In-app purchases: Wellumi Premium (set up before uploading the release)

The app sells three products. The IDs must match **exactly** (they're in
`lib/core/constants/app_constants.dart`).

| Product | Type in Play Console | ID | Suggested setup |
|---|---|---|---|
| Premium Monthly | Subscription | `wellumi_premium_monthly` | Base plan: auto-renewing, billing period **1 month** |
| Premium Yearly | Subscription | `wellumi_premium_yearly` | Base plan: auto-renewing, **1 year**. Optional offer: free trial (e.g. 1 week) |
| Premium Lifetime | One-time product (in-app product) | `wellumi_premium_lifetime` | One-time purchase |

Steps:
1. **Set up a payments profile:** Play Console → Settings → Payments profile (needed to sell
   anything; personal accounts can sell). Google's fee is 15% of your first US$1M per year.
2. **Upload a build first:** Play Console only allows creating products after an `.aab` that
   includes billing has been uploaded (internal testing is enough).
3. **Create the subscriptions:** Monetize → Products → Subscriptions → Create subscription, with
   the IDs above. Add a base plan to each, set prices (Play converts them to other currencies),
   and **activate** the base plans.
4. **Create the lifetime product:** Monetize → Products → One-time products / In-app products →
   Create, ID `wellumi_premium_lifetime`, set the price, **Activate**.
5. **Test without being charged:** Settings → License testing → add your Gmail address (and
   testers'). Install the app **from the internal-testing link** (purchases don't work in a
   `flutter run` build). Test buying, cancelling, *Restore purchases*, and reinstalling.
6. The app shows plans in this order: Yearly (with "Best value" and an automatic "Save X%"
   badge), Monthly, Lifetime. A free trial offer is detected automatically and the button
   changes to "Start free trial".

How it behaves:
- 3 **successful** scans are free (failed scans don't count). After that, any scan button leads
  to the Premium screen. History, cuff readings, reports, export and delete always stay free.
- Premium is re-checked with Google Play on each app launch, so cancelled or expired
  subscriptions end automatically, and purchases come back after a reinstall or on a new phone
  with the same Google account.
- Profile → Premium has *Go Premium*, *Restore purchases* and *Manage subscription*.
- `PurchaseService.adsRemoved` is ready for when ads are added: show ads only when it's false.

Data safety: purchase status is checked on the phone and isn't sent to any server of yours, so
the "No data collected" answer stays the same. Re-check Google's Data safety guidance for
billing when you submit, and update the form if you add a server or analytics.

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
- [ ] Payments profile set up; the 3 Premium products created and activated with the exact IDs
- [ ] Purchases tested with a license tester (buy, cancel, restore, reinstall)
- [ ] All App content forms completed (Play Console shows green ticks)
