# Physical device checklist

Automated tests cannot verify torch hardware, Quick Settings, widgets, App
Intents, sensors, or system brightness. Run this checklist on real devices
before publishing. Record device model, OS version, and pass/fail notes.

## Shared

- [ ] Fresh install opens without a crash and shows the torch availability state
      for this device (available or unavailable).
- [ ] Torch turns on and off from the power button, with haptics when enabled.
- [ ] Torch strength changes the light only where the device supports it; the
      unsupported message appears elsewhere.
- [ ] Screen Light opens full screen, changes color and brightness, and restores
      the original screen brightness on exit.
- [ ] SOS, strobe, and Morse start and stop; Stop always returns to idle.
- [ ] Auto-off timer counts down and switches the light off at zero.
- [ ] Keep-screen-awake prevents sleep while a light is on and releases after.
- [ ] Language switches between English and Bengali instantly and survives an
      app restart.
- [ ] English is used on first launch even if the device is set to Bengali.
- [ ] 320 dp width, large text, and Bengali do not overflow or clip controls.
- [ ] Screen reader labels and controls are reachable in both languages.
- [ ] Rotate the device while a light is active; the layout stays usable and the
      light state does not change unexpectedly.
- [ ] Background the app while the torch is on with Background mode disabled: the
      app-owned torch turns off. With Background mode enabled, the single
      foreground service keeps it on and the notification shows the ON state.
- [ ] Swipe the notification open: Flashlight, Shake, SOS, Strobe, Open App, and
      Stop are all reachable in one notification, and Flashlight/Shake are the
      first two rows.
- [ ] Change every switch in the notification and confirm the Flutter UI, tile,
      and widget agree after reopening the app.
- [ ] Tap Stop in the notification: the torch and any SOS/strobe mode stop, the
      notification disappears, and the Quick Settings tile is still present.
- [ ] Start SOS from the notification, then tap the Quick Settings tile once: the
      pattern stops instead of toggling into a steady torch.
- [ ] Turn the flashlight on from the notification, then start SOS: the steady
      torch ends before the pattern begins.
- [ ] Confirm only one foreground-service notification exists at any time, even
      with Shake, SOS, and background torch active together.
- [ ] Settings shows a Battery optimization section with the current system
      status. "Allow background operation" opens the system dialog; denying it
      leaves the status unchanged and shows the explanation.
- [ ] After returning from the system battery screen, the Settings status
      refreshes without reopening the app. Record whether Doze or the device
      vendor still stopped background work (this is not guaranteed).

## Android

- [ ] Quick Settings tile can be added and pinned; it shows active, inactive,
      and unavailable states correctly.
- [ ] Tapping the tile toggles the torch without opening the app.
- [ ] Rapidly tap the tile 10 times; the final tile state matches the hardware
      and the app when reopened.
- [ ] Open the camera app, then tap the tile: a "camera in use" message appears
      and the tile does not claim the torch is on.
- [ ] The home screen widget toggles the torch and updates its ON/OFF visuals.
- [ ] Resize the widget; the layout does not clip.
- [ ] Reboot the device: the tile and widget show the correct state, and both
      still toggle without first opening the app.
- [ ] Force-stop the app, then toggle from the tile and widget: both still work.
- [ ] Open the app after an external toggle: Flutter shows the same torch state.
- [ ] Toggle from the tile while the app is foregrounded: no duplicate torch
      controller or flicker.
- [ ] Enable Shake to toggle while the app is open: the existing single
      background notification shows the Shake switch as ON, the settings status
      line says background monitoring is on, and no second notification appears.
- [ ] Shake once while the app is open: the torch toggles once, the app UI, tile,
      widget, and notification all agree.
- [ ] Leave the phone on a table and walk nearby: the torch does not toggle.
- [ ] Enable Shake to toggle, shake once: the torch toggles once, not repeatedly.
- [ ] Press Home, then shake: the torch toggles without reopening the app.
- [ ] Open another app, then shake: the torch toggles and the notification offers
      Turn OFF when the torch is on.
- [ ] Lock the screen, then shake: record actual behavior. Android may defer
      non-wake-up sensor events while the screen is off.
- [ ] Remove the app from recents, then shake: the service keeps running and the
      torch toggles.
- [ ] Shake the torch ON while backgrounded, reopen the app: the UI shows the
      torch on without toggling it again.
- [ ] Shake the torch OFF while backgrounded, reopen the app: the UI shows it off.
- [ ] Toggle from the tile, then shake: exactly one toggle per gesture.
- [ ] Disable Shake to toggle: the monitoring notification disappears, the sensor
      stops, and an active torch stays on.
- [ ] Deny notification permission on Android 13+ and enable Shake: monitoring
      starts, the status line explains the hidden notification, and shakes still
      toggle the torch.
- [ ] Rapidly shake 10 times: cooldown limits it to one toggle per deliberate
      shake and the final state is coherent.
- [ ] Run SOS/strobe/Morse or Screen Light while shake is enabled: a shake does
      not interrupt the active mode.
- [ ] Low/Medium/High sensitivity behave differently with the same shake.
- [ ] Force-stop the app: monitoring stops and does not restart until the app is
      opened again. Note that the app does not claim force-stop survival.
- [ ] Reboot the device: monitoring does not auto-start (no boot receiver), and
      the app does not turn the torch on by itself.
- [ ] On a device without a camera flash, Screen Light works and the UI does not
      show a blocking dialog.
- [ ] TalkBack can reach the power button, mode selector, sliders, timer, and
      settings.

## iOS

- [ ] In Shortcuts, all three actions appear: Flashlight On, Flashlight Off,
      Toggle Flashlight.
- [ ] Run each action from the Shortcuts app; the torch matches the dialog text.
- [ ] Run each action from Siri if the phrase is available; confirm no app
      launch is required.
- [ ] Toggle from Shortcuts while the app is open: the app reflects the state
      without a duplicate toggle.
- [ ] Toggle from Shortcuts, background the app, and reopen: the app does not
      switch the torch off just because it resumed.
- [ ] On a device with no usable torch, Shortcuts reports an error and does not
      silently claim success.
- [ ] Enable Shake to toggle and accept the motion prompt only if iOS shows one;
      shake toggles once while the app is open.
- [ ] Disable shake and background the app: no sensor activity, no toggles.
- [ ] Screen Light changes and restores brightness.
- [ ] VoiceOver can reach the same controls as TalkBack.
- [ ] Bengali layout and large Dynamic Type do not clip.
- [ ] Verify the simulator limitation: simulator builds cannot exercise the real
      torch, so the torch-specific checks above require a physical iPhone.

## Remove Ads purchase (Play Billing, real account)

- [ ] Settings shows the premium card with SPECIAL UPGRADE, Go Ad-Free, the six
      benefits, ONE-TIME PAYMENT, LIFETIME ACCESS, and the store-provided price.
- [ ] No price is shown before the store responds; there is no hardcoded amount
      and no "Free" label.
- [ ] Buy with a license tester account: the Play sheet shows the one-time
      product, and the app shows "Waiting for the store to confirm..." until the
      purchase callback arrives.
- [ ] After confirmation the card shows "You're Ad-Free!" and LIFETIME UNLOCKED,
      the purchase CTA disappears, and banners, native, interstitial, and
      app-open ads stop loading.
- [ ] Relaunch the app: the lifetime entitlement is still active.
- [ ] Cancel the Play sheet: the card returns to the ready state without
      claiming success or charging anything.
- [ ] Clear app data, reinstall, then use Restore purchases: the entitlement is
      restored from the store account.
- [ ] Remove the product from the test track: the card shows the unavailable
      message with Retry and never invents a price.
- [ ] Use a slow or offline network: loading and unavailable states are honest
      and the rest of the app still works.

## Known platform limits to verify in the build

- [ ] iOS has no Quick Settings tile or home screen widget; the app must never
      present one.
- [ ] Volume buttons are not intercepted on either platform.
- [ ] The app never requests internet, camera, microphone, location, or contacts
      permission during the checklist.
