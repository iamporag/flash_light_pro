# Privacy policy — Flash Light Pro

Effective date: 8 November 2026
Published at: https://iamporag.github.io/flash_light_pro/privacy.html

Flash Light Pro is published by ClaudySoft ("we", "us"). This policy applies
to the Flash Light Pro app for Android and iOS (Android package
`com.claudysoft.flashlightpro`) and explains what information the app handles
and with whom it is shared.

Flash Light Pro works on your device. The flashlight, SOS, strobe, Morse, and
screen light need no account and no network. The free version shows ads from
Google AdMob after the consent required in your region, and an optional one-time
purchase removes them.

## Data stored on your device

Preferences such as language, default mode, torch brightness, screen
brightness, timer preset, shake sensitivity, haptic feedback, keep-screen-awake,
and reduced-animation settings are stored locally by the operating system. They
are never transmitted by the app.

The app also stores ad-frequency limits, your ad consent choice, and Remove ads
purchase status locally so ads stay within limits and an owned entitlement is
recognized immediately at startup.

On Android, the Quick Settings tile and home screen widget also store the last
torch state locally so they can show the correct state after a process restart.

## Hardware access

The app uses:

- the camera flash (torch) through the platform torch API;
- screen brightness while Screen Light is active;
- haptics for optional feedback;
- the accelerometer only while Shake to toggle is enabled: in the foreground,
  and on Android through a `specialUse` foreground service with a persistent
  notification when the app is in the background.

The app does not capture camera images, microphone audio, location, contacts,
photos, or files. It does not request camera permission, microphone permission,
or location permission. On Android 13 and later it asks for notification
permission so the background flashlight and shake services can show their
controls; denying it does not stop the services.

## Advertising

The free version may show banner, native, interstitial, and app-open ads from
Google AdMob on informational screens and in Settings. Ads are requested only
after the consent required in your region, and never while a light is active,
while an update is required, or during a permission or initialization flow.

Google AdMob may collect device identifiers, approximate location derived from
the device, app interaction and advertising data, and diagnostics under
[Google's own privacy terms](https://policies.google.com/technologies/partner-sites).
That information is shared with Google and its advertising partners as
described in those terms. The developer does not receive or store your personal
data from AdMob. You can review or change your consent choices at any time with
**Privacy options** in Settings.

## Remove ads purchase

Remove ads is a one-time, non-consumable purchase handled by Google Play or the
Apple App Store. The app never receives your payment details. Purchase
information is processed by the store under its own privacy policy. The
entitlement is cached on your device and reconciled with the store; you can
restore it at any time from Settings. The purchase removes all ads and is not a
subscription.

## No analytics or crash uploads

The app includes no analytics SDK and no remote crash reporting. If the app
closes unexpectedly, no report is uploaded. The flashlight, SOS, strobe, Morse,
and screen light keep working without a connection, even when ads cannot load,
consent cannot be obtained, or the store is unavailable.

## Retention and deletion

Settings, ad-frequency limits, consent choices, and entitlement status stay on
your device until you clear the app's storage or uninstall the app. You can
delete this local data at any time:

- Android: Settings → Apps → Flash Light Pro → Storage → Clear data.
- iOS: delete the app; this removes its local data.

Reinstalling lets the store restore an owned Remove ads purchase. You can change
ad consent at any time with **Privacy options** in Settings. For data held by
Google as an advertising provider, use the controls described in Google's
privacy terms linked above.

## System integrations

- Android Quick Settings tile and home screen widget: toggle the torch and show
  state without opening the app.
- iOS Shortcuts: on, off, and toggle actions run through the system intent
  while the system allows app intents to execute.
- iOS does not provide Android-style Quick Settings tiles or home screen
  widgets for unrestricted background flashlight control.
- Volume buttons are not intercepted because that would require accessibility
  or root access, which this app does not request.

## Children

The app is not directed to children under 13 (or the equivalent minimum age in
your country). It has no accounts, no user-generated content, and no social
features, and the developer collects no personal data. Ads are provided by
Google AdMob and are requested only after the consent required in your region.

## Changes

If this policy changes, the effective date above will be updated and the new
text will ship with the app and on the published page.

## Contact

Questions about this policy or the app's privacy practices:

ClaudySoft
sakibporag24@gmail.com
