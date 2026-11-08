# Flash Light Pro

Offline-first flashlight utility for Android and iOS, built with Flutter.

## Features

- Camera torch with strength control where the hardware supports it
- Full-screen Screen Light with adjustable color and brightness
- SOS, strobe, and Morse code playback
- Auto-off timer, keep-screen-awake, and persisted preferences
- Shake to toggle (opt-in; background monitoring on Android 8+)
- English and Bengali UI with a manual language switch
- Android Quick Settings tile and home screen widget
- Optional "Keep Flashlight On in Background" mode on Android
- One notification control panel for Flashlight, Shake, SOS, Strobe, Open App,
  and Stop
- Battery optimization status with a system-dialog exemption request
- One-time lifetime Remove Ads purchase with store-provided pricing
- iOS Shortcuts actions (on, off, toggle)

## Background flashlight

Android 8+ can keep the steady torch on after the app goes to the background,
the screen locks, or the display turns off. The mode is on by default and can be
turned off in Settings. The app runs a single `specialUse`-typed foreground
service with one ongoing notification. That notification is the control panel:
Flashlight, Shake, SOS, and Strobe switches plus Open App and Stop actions, all
rendered with RemoteViews and PendingIntents. The Quick Settings tile and home
screen widget share the same native `TorchManager` controller and can start or
stop the service without the Flutter activity running.

All controls mutate the same native state. The tile and widget stop an active
SOS/strobe pattern instead of toggling a blink, stopping a mode never removes
the tile, and the app never registers a second tile service or foreground
service. Flutter receives native changes over an event channel and reconciles
its UI without duplicating a hardware command.

The app still obeys OS restrictions: Android 12+ only allows a background
service start from a visible activity or a user action such as the tile, widget,
or notification; Android 13+ needs notification permission to show the panel;
and the OS may stop the service under memory, thermal, or battery pressure. The
`specialUse` type is used because `CameraManager.setTorchMode` needs no CAMERA
runtime permission and captures no images, so the `camera` type would be
inaccurate. SOS and strobe also run natively inside the service so they survive
the UI leaving the foreground; Morse and Screen Light remain foreground-only,
and Screen Light always requires a visible screen.

Settings includes a Background reliability section that shows whether Android
exempts the app from battery optimization. "Allow background operation" opens
the system request dialog and the section offers the system battery list as a
fallback. The app never changes the setting silently, and the status refreshes
when the user returns. Android may still defer background work in Doze or after
a force-stop; the app does not claim guaranteed background execution.

iOS has no supported background torch mode. The system suspends the app and
releases the torch, so the setting stays disabled there.

## Background shake monitoring

"Shake to toggle" is opt-in and off by default. On Android 8+, enabling it starts
the same single foreground service used by the flashlight, with one
accelerometer listener. The service owns no camera handle of its own: shakes call
the same `TorchManager` used by the app, Quick Settings tile, widget, and
notification panel, so all surfaces stay consistent. The panel's Shake switch
mirrors the saved preference and keeps its state in sync with the Flutter UI.

Android requires this monitoring to be visible: the persistent notification is
part of the user's consent, and Android 13+ notification permission controls
whether it can be displayed. Denying the permission does not disable monitoring,
but the notification is hidden from the shade and the service is only visible in
Android's active-apps list.

The app does not start monitoring until the user turns the setting on. While no
Flutter engine is alive, enabling and disabling the setting, SOS/strobe
blocking, sensitivity, and the torch state are read from a native preference
mirror; Flutter remains the source of the user's choices and re-syncs on resume
without toggling the torch.

Limits the app does not work around:

- Android may stop the service under memory, thermal, or battery pressure.
- A force-stop kills the process and monitoring until the app is opened again;
  the app does not register a boot receiver, so monitoring does not auto-start
  after a reboot.
- During deep doze or with the screen off, Android may defer or drop
  non-wake-up accelerometer events, so a shake may not be detected reliably.
- Devices without an accelerometer, and Android versions before 8.0, fall back
  to the in-app listener, which only works while the app is open. iOS has no
  equivalent background sensor mode at all.

Monitoring uses `SENSOR_DELAY_UI` (about 15 Hz) and no wake locks, so battery
impact is modest but not zero: the service keeps the app process alive and the
accelerometer active until the user turns Shake to toggle off.

## Remove Ads purchase

Settings offers a single lifetime, non-consumable purchase with the product ID
`flash_light_pro_remove_ads`. The card always shows the localized price returned
by the store; it never hardcodes an amount and shows an honest loading or
unavailable state when product details are missing. There is no subscription
language and no recurring charge.

The entitlement is applied only after the store confirms a purchased or restored
transaction. Pending transactions stay pending, every delivered purchase is
acknowledged exactly once, and a local cache makes the app ad-free immediately on
the next launch while the store reconciles in the background. The owned state
shows a lifetime-unlocked confirmation and keeps Restore purchases available in
Settings. Ads in every format are suppressed as soon as the entitlement is
active.

## Privacy

There are no accounts, no analytics SDK, and no remote crash reporting. The
flashlight, SOS, strobe, Morse, and screen light work fully offline. The free
version shows Google AdMob ads after the consent required in your region, and a
one-time `Remove ads` purchase removes them. Preferences, ad-frequency limits,
consent choices, and the purchase entitlement are stored on the device. See
`docs/store/privacy_policy.md` and `docs/ADMOB_SETUP.md`.

## Development

```sh
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter run
```

Release builds require a local `android/key.properties` and upload keystore for
Android signing; none are committed to this repository. See
`docs/release/release_checklist.md` for the full checklist.
