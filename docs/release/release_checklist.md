# Release checklist

## Identity and build settings

- Android application ID: `com.claudysoft.flashlightpro`
- iOS bundle ID: `com.claudysoft.flashlightpro`
- Version: `0.1.0+1` in `pubspec.yaml`
- Android: `compileSdk 36`, `targetSdk 36`, `minSdk 24`
- iOS deployment target: 15.0 (App Intents are gated to iOS 16+)
- Release manifest must not contain `android.permission.INTERNET`,
  `android.permission.CAMERA`, analytics, or ads.

## Android signing

Release signing is loaded only when `android/key.properties` exists. No
credentials or keystores are committed.

1. Generate an upload keystore once, outside version control:

   ```sh
   keytool -genkeypair -v -keystore android/keystore/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Copy `android/key.properties.example` to `android/key.properties` and fill in
   the passwords. Keep both the file and the keystore out of Git.
3. Build:

   ```sh
   export JAVA_HOME=/opt/homebrew/opt/openjdk@24
   flutter build appbundle --release
   flutter build apk --release
   ```

4. If `android/key.properties` is missing, the release build is unsigned and is
   not publishable. Do not configure debug signing for release.

## iOS signing

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the Runner target, choose the distribution team, and keep automatic
   signing or a matching provisioning profile.
3. Confirm the bundle ID and version.
4. Archive with Product > Archive, then validate and upload in Xcode Organizer.
5. Verify `NSMotionUsageDescription` and `CFBundleLocalizations` are present.
   The app uses the camera torch API and does not request camera capture
   permission at runtime.

## Validation commands

```sh
dart format .
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
flutter build ios --no-codesign

cd android
JAVA_HOME=/opt/homebrew/opt/openjdk@24 ./gradlew testDebugUnitTest
```

- `flutter test` covers localization, settings, shake logic, Bloc state sync,
  and static manifest/Swift registration checks.
- Gradle unit tests cover the shared Kotlin torch controller.
- Neither replaces `docs/testing/physical_device_checklist.md`.

## Store console

1. Host `docs/store/privacy_policy.md` and paste the URL in both consoles.
2. Fill in `docs/store/listing.md`, replacing every `TODO`.
3. Upload the icons and feature graphic listed in
   `docs/store/asset_checklist.md`.
4. Capture screenshots from the release build only.
5. Complete the Play Data safety form (no data collected or shared) and the
   content rating questionnaire.
6. Complete the App Store privacy questionnaire (data not collected) and age
   rating.
7. Do not claim Play Store or App Store approval before both consoles confirm
   it.
