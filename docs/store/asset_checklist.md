# Store asset checklist

Verify the current size and format requirements in App Store Connect and Play
Console before uploading; both stores change them over time.

## Icons

- [x] iOS 1024×1024 opaque icon in
      `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`
- [x] Android legacy and adaptive icons in `android/app/src/main/res/mipmap-*`
- [x] Play icon 512×512: `docs/store/assets/play_icon_512.png`
- [x] Vector source: `assets/branding/app_icon.svg`
- [ ] Confirm the icon has no transparency and no pre-rounded corners in the
      store upload.

## Google Play graphics

- [x] Feature graphic 1024×500:
      `docs/store/assets/play_feature_graphic_1024x500.png`
- [ ] Phone screenshots: at least 2, captured from the release build on a real
      Android device or emulator. Use portrait 1080×1920 or larger, no device
      frames, no invented UI.
- [ ] Tablet screenshots (optional but recommended for large-screen
      eligibility).
- [ ] Short video (optional).

## Apple graphics

- [ ] 6.9-inch iPhone screenshots, portrait, captured from the release build
      (current App Store Connect may require 6.9-inch; confirm before upload).
- [ ] 6.5-inch and 5.5-inch screenshots if App Store Connect still requests
      them for the chosen device family.
- [ ] iPad screenshots if the app is offered on iPad. The app already supports
      iPad orientations, so only upload iPad screenshots that match the actual
      iPad layout.
- [ ] Optional app preview video, if recorded from the real app.

## Screenshot capture plan

Capture each screen at default text size first, then repeat one layout in
Bengali to show localization. Keep the system status bar clean (full battery,
strong signal, no notifications).

1. Home, torch off, English.
2. Home, torch on with strength slider visible on a supported device.
3. Screen Light active with color and brightness controls.
4. Mode panel for SOS or Morse (the panel itself, not a marketing mockup).
5. Auto-off timer sheet.
6. Settings, showing language, shake, and keep-awake controls.
7. Bengali home screen.
8. Android only: Quick Settings tile active.
9. Android only: home screen widget in its ON state.

Do not show:
- iOS widgets or iOS Quick Settings tiles (they do not exist).
- Background or lock-screen flashlight control on iOS.
- Volume-button control.
- Permissions dialogs the app does not actually show.
- Screenshots from a different app or a design mockup.

## Store metadata files

- `docs/store/listing.md` — names, descriptions, keywords, data-safety answers.
- `docs/store/privacy_policy.md` — host this text and paste the URL in both
  consoles.
- `docs/testing/physical_device_checklist.md` — run before capturing assets.
- `docs/release/release_checklist.md` — signing, build, and submission steps.
