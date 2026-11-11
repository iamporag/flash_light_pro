# AdMob and Remove Ads setup

This document covers the production configuration for Google AdMob and the
one-time `Remove ads` purchase. The code is complete; the items below require
your own AdMob, Play Console, and App Store Connect accounts.

Debug and profile builds use Google's official sample IDs. Android release
builds use the production unit IDs compiled into `AdMobIds`
(`lib/core/config/admob/admob_ids.dart`) and consumed by `AdConfig`
(`lib/core/config/admob/admob_config.dart`), so a release build requests real ads
without any extra build flag. Ad unit IDs are public identifiers, not secrets.
`--dart-define` values still override the compiled-in IDs per format. Per-format
switches and frequency limits live in `AdMobPolicy`
(`lib/core/config/admob/admob_policy.dart`). iOS unit IDs are not committed;
without them ads stay off on iOS and the app remains fully usable.

## 1. What is implemented

| Format | Placement | Behavior |
| --- | --- | --- |
| Banner | Bottom of the torch (home) screen | Adaptive anchored banner, hidden (not re-requested) while a light is active; never on the full-screen light page |
| Native | Bottom of Settings | Labeled `Ad`; loads only when eligible |
| Interstitial | After every 3 approved utility actions | 2-minute minimum, 5 per local day, pending trigger survives a blocked attempt |
| App open | First eligible moment of a cold start and real returns from the background | 4-hour cooldown; never during a torch session, purchase, update, or permission flow |
| Rewarded | Reusable service, no UI | The app has no suitable optional benefit, so it is intentionally unwired |

Every request and every presentation runs through `AdEligibilityManager`. Ads
are refused when any of these is true:

- the placement has no unit ID;
- UMP consent does not allow ad requests;
- the Remove ads entitlement is owned;
- the flashlight, SOS, strobe, Morse, or screen light is active;
- essential initialization is running;
- the app is not resumed or a fullscreen ad is visible;
- a purchase or restore is running;
- an update check is running, a mandatory update prompt is visible, or the Play
  update flow is active (download, install, or launch);
- frequency limits block the format, or no interstitial trigger is pending;
- the fullscreen ad is not loaded (navigation continues immediately).

AdMob errors are caught everywhere. They cannot block an update check, the
flashlight, or navigation.

## 2. AdMob account setup

1. Create or open an [AdMob](https://admob.google.com/) account.
2. Add two apps with your existing store identities:
   - Android: `com.claudysoft.flashlightpro`
   - iOS: `com.claudysoft.flashlightpro`
3. Copy each **AdMob App ID** (format `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`).
4. Create five ad units per platform:
   - Banner
   - Native (advanced)
   - Interstitial
   - Rewarded
   - App open
5. Copy each **ad unit ID** (format `ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`).

Do not reuse a test ID in production. Google's sample IDs in
`lib/core/config/admob/admob_ids.dart` (`AdMobIds.testAndroid` and
`AdMobIds.testIos`) and the fallbacks in `android/app/build.gradle` and
`ios/Runner/Info.plist` are only for development and review.

## 3. Android App ID

`android/app/build.gradle` resolves the App ID in this order:

1. Gradle property `admobAppId`
2. Environment variable `ADMOB_APP_ID`
3. Google's test App ID, used only by debug and profile builds. Release builds
   fail with a `GradleException` instead, because the Google Mobile Ads SDK
   throws on startup when the manifest holds a missing or invalid App ID.

Preferred for local release builds, in `android/gradle.properties`:

```properties
admobAppId=ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
```

The App ID is public, not a secret. For CI you can instead export:

```sh
export ADMOB_APP_ID=ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
```

The manifest reads `${admobAppId}`; do not hardcode the ID in
`AndroidManifest.xml`.

## 4. iOS App ID

Replace the test value in `ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

The committed value is Google's iOS sample App ID so simulator and debug runs
keep working. Replace it before archiving for the App Store.

## 5. Production ad unit IDs

Android unit IDs live in `AdMobIds` in
`lib/core/config/admob/admob_ids.dart`; that file is the only Dart source of
truth for them. They are compiled into every release build, so
`flutter build appbundle --release` is enough. Ad unit IDs are public
identifiers; they are not secrets and committing them is safe.

To replace them, edit that map or pass a `--dart-define` override. Overrides win
per format, so a partial set is allowed:

| Platform | Define |
| --- | --- |
| Android | `ADMOB_ANDROID_BANNER_ID` |
| Android | `ADMOB_ANDROID_NATIVE_ID` |
| Android | `ADMOB_ANDROID_INTERSTITIAL_ID` |
| Android | `ADMOB_ANDROID_REWARDED_ID` |
| Android | `ADMOB_ANDROID_APP_OPEN_ID` |
| iOS | `ADMOB_IOS_BANNER_ID` |
| iOS | `ADMOB_IOS_NATIVE_ID` |
| iOS | `ADMOB_IOS_INTERSTITIAL_ID` |
| iOS | `ADMOB_IOS_REWARDED_ID` |
| iOS | `ADMOB_IOS_APP_OPEN_ID` |

Optional override with a filled-in file (the templates stay in the repository):

```sh
cp admob.android.example.json admob.android.json   # Android
cp admob.ios.example.json admob.ios.json           # iOS
flutter build appbundle --release --dart-define-from-file=admob.android.json
flutter build ipa --release --dart-define-from-file=admob.ios.json
```

`admob.android.json` and `admob.ios.json` are git-ignored. Set
`ADMOB_TEST_DEVICE_IDS` inside them while testing on registered devices, and
leave it empty for the production build.

Equivalent explicit Android app bundle:

```sh
flutter build appbundle \
  --dart-define=ADMOB_ANDROID_BANNER_ID=ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX \
  --dart-define=ADMOB_ANDROID_NATIVE_ID=ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX \
  --dart-define=ADMOB_ANDROID_INTERSTITIAL_ID=ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX \
  --dart-define=ADMOB_ANDROID_REWARDED_ID=ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX \
  --dart-define=ADMOB_ANDROID_APP_OPEN_ID=ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
```

Equivalent explicit iOS archive:

```sh
flutter build ipa \
  --dart-define=ADMOB_IOS_BANNER_ID=ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX \
  --dart-define=ADMOB_IOS_NATIVE_ID=ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX \
  --dart-define=ADMOB_IOS_INTERSTITIAL_ID=ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX \
  --dart-define=ADMOB_IOS_REWARDED_ID=ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX \
  --dart-define=ADMOB_IOS_APP_OPEN_ID=ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
```

`ADMOB_TEST_MODE=true` is ignored in release builds by design, so a release
artifact can never serve sample ads accidentally. Debug and profile builds always
use the sample IDs.

### Why a Play test build can still show no ads

A compiled-in ID is necessary but not sufficient. Before ads serve, Google must
approve the AdMob app:

1. In AdMob, open the app and use **App store details → Add** to link the Play
   listing. The AdMob package name must be exactly
   `com.claudysoft.flashlightpro`.
2. Wait for **Approval status** to change from *Requires review* to *Ready*.
   New apps and newly linked store listings are reviewed, which can take from a
   few hours to a few days. Until then the ad units report 0 requests or serve
   limited ads even when the app requests them correctly.
3. Verify that the AdMob App ID (`ca-app-pub-...~...`) in
   `android/gradle.properties` belongs to the same AdMob app as the unit IDs.

A brand-new AdMob account can also be limited until its own review and payment
setup complete.

## 6. Test devices and UMP

Add your device as an AdMob test device while developing:

```sh
flutter run --dart-define=ADMOB_TEST_DEVICE_IDS=YOUR_TEST_DEVICE_ID
```

- `ADMOB_TEST_DEVICE_IDS` accepts a comma-separated list.
- When the list is non-empty, the UMP request uses EEA debug geography, so the
  consent form can be exercised without a production EEA device.
- Test device IDs are passed to `MobileAds.updateRequestConfiguration` before
  SDK initialization.

Do not pass production IDs together with test mode. Debug builds already use
test IDs; adding real unit IDs to a debug run does not change that.

## 7. Consent (UMP)

The app checks consent before initializing Google Mobile Ads and before loading
or showing any ad:

1. The startup update check settles first.
2. `ConsentInformation.requestConsentInfoUpdate` runs.
3. If a form is available, `ConsentForm.loadAndShowConsentFormIfRequired` is
   shown.
4. Consent is re-read. Ads start only when `canRequestAds()` is true.
5. `Privacy options` in Settings reopens the form and re-checks the decision.

Configure the message in AdMob under **Privacy & messaging → GDPR** (and the
state-specific US messages where applicable). Without a published message, UMP
has nothing to show and `canRequestAds` may remain false.

Consent failures fail closed: no ads are requested. The flashlight and update
flow are unaffected.

### iOS App Tracking Transparency limitation

This build does not include `NSUserTrackingUsageDescription` and does not call
the ATT prompt. On iOS, ads therefore remain non-personalized unless you add ATT
support yourself. If you add it, place the usage description in
`ios/Runner/Info.plist`, add `SKAdNetworkItems` for Google's current list
([Google's SKAdNetwork list](https://developers.google.com/admob/ios/ios14)), and
re-test the consent flow. Neither step is required for the app to compile or
serve non-personalized ads.

## 8. Remove ads product

The product ID is fixed in code and must match both stores exactly:

```
flash_light_pro_remove_ads
```

Type: **non-consumable / one-time**. It is not a subscription.

### Google Play

1. Play Console → Monetize → Products → **In-app products**.
2. Create `flash_light_pro_remove_ads`, one-time product.
3. Set a base price equivalent to **US$0.99** where the store supports it, then
   activate it. The app always renders the localized price returned by the
   store; it never hardcodes an amount and never invents one when the product is
   unavailable.
4. Upload a build that contains the `com.android.vending.BILLING` permission
   (already in `AndroidManifest.xml`).
5. Add license testers under **Setup → License testing** for purchase testing.

Android performs a silent `restorePurchases()` on startup. The local cache makes
the purchase apply immediately, and the purchase stream confirms and completes
the transaction.

### App Store Connect

1. App Store Connect → your app → **Features → In-App Purchases**.
2. Create a **Non-Consumable** product with the same ID.
3. Add a localized display name, description, and price.
4. Submit it with a build for review.

Every purchase event is acknowledged with `completePurchase` when the store
requires it, including duplicate deliveries. The UI only shows `Remove ads`
success after the store stream reports `purchased` or `restored`.

## 9. Verification limitations

There is no backend and no custom server. This is intentional: the app has no
accounts and no developer-operated infrastructure.

Consequences you should understand before publishing:

- The entitlement is confirmed by the platform store, but receipts are **not**
  verified on a server you control. A rooted or jailbroken device could tamper
  with the local cache; the store stream remains the authority for new
  transactions.
- Cross-device restoration relies entirely on Play Billing or StoreKit. The
  user may need to tap **Restore purchases** on iOS.
- AdMob invalid-traffic detection and policy enforcement are Google's
  responsibility. This app records impressions only after the SDK confirms
  presentation, keeps a local 5/day limit, and never auto-shows fullscreen ads
  during an active light session.
- No analytics or crash reporting is added. AdMob reporting is available in your
  AdMob account only.

If you later add server-side verification, keep the local cache as an optimistic
cache and treat the server response as the source of truth.

## 10. Store declarations

Update both stores before submitting:

- **Google Play:** Ads declaration = yes; one in-app product; data safety
  disclosures for Google AdMob (device/other IDs, app interactions, diagnostics,
  approximate location) and purchase history.
- **App Store Connect:** App privacy answers for purchases and AdMob's
  identifiers/usage data; be truthful about tracking based on your consent
  configuration.
- **Privacy policy:** `docs/store/privacy_policy.md` already describes AdMob,
  the purchase, local storage, and the absence of analytics. Host it and paste
  the URL into both stores.

## 11. Release checklist

- [ ] Real Android and iOS AdMob App IDs are configured natively.
- [ ] Android release builds pass `-PadmobAppId` or `ADMOB_APP_ID`; the build
      fails on purpose when neither is set.
- [ ] The `android/app/proguard-rules.pro` Room keep rule is present; removing
      it makes release builds crash at startup inside WorkManager.
- [ ] All ten production unit IDs are configured: Android in
      `AdMobIds`, iOS in the iOS build defines.
- [ ] A UMP message is published in AdMob for every required region.
- [ ] `flash_light_pro_remove_ads` exists and is active in both stores.
- [ ] Debug build shows sample ads only; release build shows production ads.
- [ ] A banner appears at the bottom of the torch screen and is hidden during
      SOS, strobe, Morse, and screen-light use without re-requesting per toggle.
- [ ] Interstitial shows after the third approved utility action, never on
      launch or torch toggles; the 2-minute and 5-per-day limits hold after
      restart, and a blocked trigger is retried at the next safe action.
- [ ] App Open appears on a fresh install's first eligible session and never
      after a brief Quick Settings or system-settings round trip.
- [ ] No two fullscreen formats appear back to back.
- [ ] Purchase, pending, cancel, failure, restore, and already-owned paths were
      each exercised with a store test account.
- [ ] An owned entitlement suppresses every format immediately, including after
      a cold start.
- [ ] Airplane mode, AdMob failure, and store outage leave the flashlight and
      update flow fully usable.

## 12. Troubleshooting

| Symptom | Likely cause |
| --- | --- |
| No ads in a release build | The AdMob app is still **Requires review** or not linked to the Play listing, consent does not allow requests, the app owns Remove ads, or the IDs do not match the AdMob app |
| Test ads in a release build | Release build received test unit IDs; check the defines, not `AdConfig.test` |
| Android build fails on AdMob App ID | Expected: release builds require `admobAppId` or `ADMOB_APP_ID`; pass the real App ID |
| UMP form never appears | No message published in AdMob, or the device is outside the configured region and not a test device |
| `canRequestAds` stays false | Consent was denied or UMP failed; ads stay off by design |
| Product not found | Product ID mismatch, product inactive, or the store account is not a license tester |
| Restore finds nothing | No purchase on that store account, or the store has not synced yet |
| Ads show while a light is on | Should be impossible: check that `AdRequestContextProvider` is reading live bloc state |
