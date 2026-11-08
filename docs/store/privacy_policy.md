# Privacy policy — Flash Light Pro

Effective date: 6 November 2026

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
The developer does not receive or store your personal data from AdMob. You can
review or change your consent choices at any time with **Privacy options** in
Settings.

## Remove ads purchase

Remove ads is a one-time, non-consumable purchase handled by Google Play or the
Apple App Store. The app never receives your payment details. The entitlement is
cached on your device and reconciled with the store; you can restore it at any
time from Settings. The purchase removes all ads and is not a subscription.

## No analytics or crash uploads

The app includes no analytics SDK and no remote crash reporting. If the app
closes unexpectedly, no report is uploaded. The flashlight, SOS, strobe, Morse,
and screen light keep working without a connection, even when ads cannot load,
consent cannot be obtained, or the store is unavailable.

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

The app collects no personal data itself and has no accounts or social
features. Ads are provided by Google AdMob and are configured through the
consent flow required for your region.

## Changes

If this policy changes, the effective date above will be updated and the new
text will ship with the app.

## Contact

TODO: add a support email and, if available, a website before publishing.
