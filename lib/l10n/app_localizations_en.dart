// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Flash Light Pro';

  @override
  String get appTagline => 'Premium lighting toolkit';

  @override
  String get offlineFooter =>
      'The flashlight works offline. Ads and purchases need a connection.';

  @override
  String get screenFallbackFooter =>
      'Screen flash fallback is active — the display is the light source.';

  @override
  String get modeTorch => 'Torch';

  @override
  String get modeScreen => 'Screen';

  @override
  String get modeSos => 'SOS';

  @override
  String get modeStrobe => 'Strobe';

  @override
  String get modeMorse => 'Morse';

  @override
  String get modeFlashlight => 'Flashlight';

  @override
  String get modeScreenLight => 'Screen light';

  @override
  String get modeSosSignal => 'SOS signal';

  @override
  String get modeMorsePlayback => 'Morse playback';

  @override
  String get statusTorchOn => 'Flash Light On';

  @override
  String get statusScreenOn => 'Screen Light On';

  @override
  String get statusSosActive => 'SOS Signal Active';

  @override
  String get statusStrobeOn => 'Strobe On';

  @override
  String get statusMorsePaused => 'Morse Paused';

  @override
  String get statusSendingMorse => 'Sending Morse';

  @override
  String get statusChecking => 'Checking flashlight...';

  @override
  String get statusTorchOff => 'Flash Light Off';

  @override
  String get statusTorchUnavailable => 'Flashlight not available';

  @override
  String get statusScreenOff => 'Screen Light Off';

  @override
  String get statusSosReady => 'SOS Ready';

  @override
  String get statusSosNeedsTorch => 'SOS needs a flashlight';

  @override
  String get statusStrobeReady => 'Strobe Ready';

  @override
  String get statusStrobeNeedsTorch => 'Strobe needs a flashlight';

  @override
  String get statusMorseReady => 'Morse Ready';

  @override
  String subtitleAutoOff(String countdown) {
    return 'Auto-off in $countdown. Tap the timer to change or cancel it.';
  }

  @override
  String get subtitleMorsePaused => 'Playback is paused. Resume or stop below.';

  @override
  String get subtitleTapStop => 'Tap the power button to stop.';

  @override
  String get subtitleCheckingHardware => 'Checking this device’s hardware.';

  @override
  String get subtitleTorchReady => 'Tap to turn the flashlight on or off.';

  @override
  String get subtitleTorchUnavailable =>
      'Use Screen Light instead — it needs no torch hardware.';

  @override
  String get subtitleScreenReady => 'Tap to open a full-screen light.';

  @override
  String get subtitleSosReady => 'Standard ... --- ... distress signal.';

  @override
  String get subtitleStrobeReady =>
      'Adjustable flash speed with a safety warning.';

  @override
  String get subtitleMorseReady => 'Tap Play to send your message as light.';

  @override
  String get hintStop => 'Double tap to stop the light';

  @override
  String get hintTorchOn => 'Double tap to turn the flashlight on';

  @override
  String get hintScreen => 'Double tap to open screen light';

  @override
  String get hintSos => 'Double tap to start the SOS signal';

  @override
  String get hintStrobe => 'Double tap to start the strobe';

  @override
  String get hintMorse => 'Double tap to play the Morse message';

  @override
  String announcementOn(String mode) {
    return '$mode on';
  }

  @override
  String announcementOff(String mode) {
    return '$mode off';
  }

  @override
  String timerCountdown(String countdown) {
    return 'Auto-off in $countdown';
  }

  @override
  String get timerOff => 'Auto-off off';

  @override
  String timerPreset(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Auto-off $minutesString min';
  }

  @override
  String get timerSheetTitle => 'Auto-off timer';

  @override
  String get timerSheetSubtitle => 'Turns off the active light automatically.';

  @override
  String timerTurningOff(String countdown) {
    return 'Turning off in $countdown';
  }

  @override
  String timerPresetChip(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString min';
  }

  @override
  String get timerCustomLabel => 'Custom minutes';

  @override
  String get timerSet => 'Set';

  @override
  String get timerCancel => 'Cancel timer';

  @override
  String get timerClose => 'Close';

  @override
  String timerCustomError(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Enter a whole number between 1 and $maxString.';
  }

  @override
  String get timerButton => 'Auto-off timer';

  @override
  String get flashlight => 'Flashlight';

  @override
  String get rearCameraTorch => 'Rear camera torch';

  @override
  String get noUsableTorch => 'No usable torch detected';

  @override
  String get torchStrength => 'Torch strength';

  @override
  String get torchStrengthUnsupported =>
      'Torch strength is not supported on this device.';

  @override
  String get screenLightWorksWithoutTorch =>
      'Screen Light works even without torch hardware.';

  @override
  String get screenLight => 'Screen Light';

  @override
  String get screenPanelSubtitle => 'Full-screen light with adjustable color';

  @override
  String get color => 'Color';

  @override
  String get brightness => 'Brightness';

  @override
  String get brightnessRestored =>
      'Your original screen brightness returns when you exit.';

  @override
  String get sosSignal => 'SOS signal';

  @override
  String get sosSubtitle => 'Standard international distress pattern';

  @override
  String get sosTransmitting =>
      'Transmitting continuously. Turn it off when help arrives.';

  @override
  String get sosPlaysOnTorch => 'Plays on the flashlight until you stop it.';

  @override
  String get sosNeedsTorch => 'SOS needs a working flashlight on this device.';

  @override
  String get strobe => 'Strobe';

  @override
  String get strobeSubtitle => 'Adjustable flash speed';

  @override
  String get flashSpeed => 'Flash speed';

  @override
  String speedHz(String value) {
    return '$value Hz';
  }

  @override
  String get photosensitivityWarning =>
      'Photosensitivity warning: flashing light can trigger seizures. Stop immediately if you feel unwell and keep the light away from your eyes.';

  @override
  String get morseTitle => 'Morse code';

  @override
  String get morseSubtitle => 'Send A-Z and 0-9 as light signals';

  @override
  String get message => 'Message';

  @override
  String get morseHint => 'SOS HELLO 123';

  @override
  String get clearMessage => 'Clear message';

  @override
  String get morsePreviewPlaceholder => 'Your Morse preview appears here.';

  @override
  String morseUnsupported(String characters) {
    return 'Unsupported: $characters — use A-Z and 0-9.';
  }

  @override
  String get morsePlaysOnTorch => 'Plays on the flashlight.';

  @override
  String get morseScreenFallback =>
      'No flashlight detected — the screen will flash instead.';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get stop => 'Stop';

  @override
  String get playMorse => 'Play Morse';

  @override
  String get typeMessage => 'Type a message to send in Morse code.';

  @override
  String unsupportedCharacters(String characters) {
    return 'Unsupported characters: $characters. Use A-Z and 0-9.';
  }

  @override
  String get strobeNeedsTorchMessage =>
      'Strobe needs a working flashlight on this device.';

  @override
  String get lightingError => 'Lighting Error';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get retry => 'Retry';

  @override
  String get errorUnavailable =>
      'The flashlight is not available on this device.';

  @override
  String get errorCameraInUse =>
      'The camera is in use by another app. Close it and try again.';

  @override
  String get errorEnable =>
      'Could not turn on the flashlight. Please try again.';

  @override
  String get errorDisable =>
      'Could not turn off the flashlight. Please try again.';

  @override
  String get errorCheck => 'Could not check the flashlight. Please try again.';

  @override
  String get errorPlatform =>
      'Flashlight control is not supported on this platform.';

  @override
  String get errorUnexpected =>
      'Something went wrong while controlling the light.';

  @override
  String get exitScreenLight => 'Exit screen light';

  @override
  String get hideCustomColor => 'Hide custom color';

  @override
  String get customColor => 'Custom color';

  @override
  String get turnOffLight => 'Turn off light';

  @override
  String get hue => 'Hue';

  @override
  String get saturation => 'Saturation';

  @override
  String get openSettings => 'Open settings';

  @override
  String get settings => 'Settings';

  @override
  String get settingsSubtitle => 'Language, feedback, and behavior';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBengali => 'বাংলা';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get motionSection => 'Motion';

  @override
  String get haptics => 'Haptic feedback';

  @override
  String get hapticsSubtitle => 'Vibrate when you use the power controls.';

  @override
  String get shakeToToggle => 'Shake to toggle';

  @override
  String get shakeSubtitleOn =>
      'Shake your phone to turn the flashlight on or off, even when the app is in the background.';

  @override
  String get shakeSubtitleOff =>
      'Off. Turn on to shake the flashlight on or off, even in the background.';

  @override
  String get shakeSensitivity => 'Shake sensitivity';

  @override
  String get sensitivityLow => 'Low';

  @override
  String get sensitivityMedium => 'Medium';

  @override
  String get sensitivityHigh => 'High';

  @override
  String get shakeMonitoringActive =>
      'Background monitoring is on. A persistent notification keeps shake working after you leave the app.';

  @override
  String get shakeMonitoringInactive =>
      'Background monitoring is not running. Shake works only while the app is open.';

  @override
  String get shakeNotificationsOff =>
      'Notifications are off, so the required monitoring notification is hidden. Monitoring still runs and appears in Android\'s active apps list.';

  @override
  String get shakeBackgroundUnsupported =>
      'This device does not support background shake monitoring. Shake works while the app is open.';

  @override
  String get keepScreenAwake => 'Keep screen awake';

  @override
  String get keepScreenAwakeSubtitle =>
      'Prevent the screen from sleeping while a light is active.';

  @override
  String get backgroundSection => 'Background';

  @override
  String get keepFlashlightOnBackground => 'Keep Flashlight On in Background';

  @override
  String get keepFlashlightOnBackgroundSubtitle =>
      'Leaves the steady flashlight on when you switch apps or lock the screen. Android shows a notification with a Stop action. Hardware, battery, or system limits can still turn it off.';

  @override
  String get keepFlashlightOnBackgroundUnsupported =>
      'Not available on iOS. The system turns the flashlight off when Flash Light Pro is suspended.';

  @override
  String get backgroundNotificationsOff =>
      'Notifications are off. The flashlight stays on, but the Stop button is only available in the app.';

  @override
  String get reduceAnimations => 'Reduce animations';

  @override
  String get reduceAnimationsSubtitle =>
      'Use shorter transitions and calmer motion.';

  @override
  String get defaultMode => 'Default mode';

  @override
  String get defaultModeSubtitle => 'The mode selected when the app opens.';

  @override
  String get aboutSection => 'About';

  @override
  String get appInfo => 'App information';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get openSourceLicenses => 'Open-source licenses';

  @override
  String get permissionsTitle => 'Permissions and device notes';

  @override
  String get permissionsBody =>
      'The app uses the camera torch, screen brightness, haptics, and — only when Shake to toggle is on — the motion sensor. On Android, background shake monitoring runs in a foreground service with a persistent notification. The app does not request internet, location, camera images, microphone, or contacts.';

  @override
  String get volumeButtonsTitle => 'Volume buttons';

  @override
  String get volumeButtonsBody =>
      'Android and iOS reserve the volume buttons for system audio and accessibility. Flash Light Pro does not intercept them, because that would require accessibility or root access, which this app does not request.';

  @override
  String get iosLimitationsTitle => 'iOS integration';

  @override
  String get iosLimitationsBody =>
      'On iOS, the Shake to toggle and Shortcuts actions work while the app or the system intent is running. iOS does not offer Android-style Quick Settings tiles or home screen widgets for unrestricted background flashlight control. iOS also suspends app execution and releases the torch when the app leaves the foreground, so there is no background flashlight mode.';

  @override
  String get madeOffline =>
      'The flashlight works offline. Ads need a connection.';

  @override
  String get privacyPolicyTitle => 'Privacy policy';

  @override
  String get privacyIntro =>
      'Flash Light Pro works on your device. The flashlight itself needs no account and no network. The free version shows ads from Google AdMob, and an optional one-time purchase removes them.';

  @override
  String get privacyLocalTitle => 'Data stored on your device';

  @override
  String get privacyLocalBody =>
      'Preferences such as language, default mode, brightness, and shake sensitivity are stored locally by the operating system. Ad frequency limits, your ad consent choice, and Remove ads purchase status are cached locally too. The Android Quick Settings tile and home screen widget also store the last torch state locally so they can show the correct state.';

  @override
  String get privacyHardwareTitle => 'Hardware access';

  @override
  String get privacyHardwareBody =>
      'The app uses the camera flash (torch) and screen brightness. It reads the accelerometer only while Shake to toggle is enabled: in the foreground, and on Android through a foreground service with a persistent notification when you leave the app. It does not capture camera images, microphone audio, location, contacts, or photos.';

  @override
  String get privacyAdsTitle => 'Advertising';

  @override
  String get privacyAdsBody =>
      'The free version may show banner, native, interstitial, and app-open ads from Google AdMob. Ads are requested only after the consent required in your region, and never while a light is active or an update is required. You can review your choices with Privacy options in Settings. The Remove ads purchase stops all ads on this account.';

  @override
  String get privacyBillingTitle => 'Remove ads purchase';

  @override
  String get privacyBillingBody =>
      'Remove ads is a one-time, non-consumable purchase handled by Google Play or the App Store. The app never receives your payment details. The entitlement is cached on your device and confirmed with the store, and you can restore it at any time from Settings.';

  @override
  String get privacyNoAnalyticsTitle => 'No analytics or crash uploads';

  @override
  String get privacyNoAnalyticsBody =>
      'The app includes no analytics SDK and no remote crash reporting. Google AdMob may collect device and ad-interaction data under Google\'s own privacy terms. The flashlight, SOS, strobe, Morse, and screen light keep working without a connection.';

  @override
  String get privacyPolicyFooter =>
      'This policy applies to Flash Light Pro version 0.1.0. On iOS the app requests motion access, and only when Shake to toggle is enabled. On Android 13 and later it asks for notification permission so the background flashlight and shake services can show their controls. Ads and purchases are provided by Google AdMob and the platform store under their own privacy terms.';

  @override
  String get close => 'Close';

  @override
  String get updateRequiredTitle => 'Update Required';

  @override
  String get updateRequiredBody =>
      'A newer version of Flash Light Pro is required to keep the app working safely. Please update to continue.';

  @override
  String get updateRecommendedTitle => 'Update Recommended';

  @override
  String get updateRecommendedBody =>
      'This update is recommended for the best experience. You can update now or keep using the current version.';

  @override
  String get updateAvailableTitle => 'New Update Available';

  @override
  String get updateAvailableBody =>
      'A newer version of Flash Light Pro is available with improvements and fixes.';

  @override
  String updateInstalledVersion(String version) {
    return 'Installed: $version';
  }

  @override
  String updateAvailableBuild(int build) {
    return 'Available build: $build';
  }

  @override
  String get updateVersionUnknown => 'Latest version on Google Play';

  @override
  String get updateNow => 'Update Now';

  @override
  String get updateLater => 'Later';

  @override
  String get updateOpenStore => 'Open Play Store';

  @override
  String get updateTryAgain => 'Try again';

  @override
  String get updateDownloadingTitle => 'Downloading update...';

  @override
  String get updateDownloadingBody =>
      'You can keep using the flashlight while the update downloads.';

  @override
  String get updateReadyTitle => 'Update ready';

  @override
  String get updateReadyBody =>
      'The update has been downloaded. Install it now to finish.';

  @override
  String get updateInstallNow => 'Install Update';

  @override
  String get updateInstallingTitle => 'Installing update...';

  @override
  String get updateInstallingBody =>
      'Google Play is installing the update. The app may restart.';

  @override
  String get updateInstalledBody =>
      'The update is installed. Restart the app if it does not reopen automatically.';

  @override
  String get updateErrorTitle => 'Update couldn\'t start';

  @override
  String get updateErrorBody =>
      'Google Play could not start the update. Check your connection and try again.';

  @override
  String get updateStoreError => 'Couldn\'t open the store. Try again later.';

  @override
  String get updateCanceled => 'The update was canceled.';

  @override
  String get updateReadySnack => 'Update ready to install.';

  @override
  String get updateHide => 'Hide';

  @override
  String get updateContinueAnyway => 'Continue without updating';

  @override
  String get updateCachedNotice =>
      'This update was verified earlier. Reconnect to confirm it.';

  @override
  String get settingsUpdates => 'App updates';

  @override
  String get settingsUpdateCheck => 'Check for updates';

  @override
  String get settingsUpdateChecking => 'Checking for updates...';

  @override
  String get settingsUpToDate => 'You\'re using the latest version';

  @override
  String settingsUpdateAvailable(int build) {
    return 'Update available (build $build)';
  }

  @override
  String get settingsUpdateDownloading => 'Downloading update...';

  @override
  String get settingsUpdateReady => 'Update ready to install';

  @override
  String get settingsUpdateInstalling => 'Installing update...';

  @override
  String get settingsUpdateInstalled => 'Update installed';

  @override
  String get settingsUpdateInstall => 'Install';

  @override
  String get settingsUpdateAction => 'Update';

  @override
  String get settingsUpdateCheckAction => 'Check';

  @override
  String get settingsUpdateFailed => 'Couldn\'t check for updates';

  @override
  String get settingsUpdateStoreManaged =>
      'Updates are handled by your app store';

  @override
  String get removeAdsTitle => 'Remove ads';

  @override
  String get removeAdsBody =>
      'One-time purchase. Removes banner, interstitial, and app-open ads. The flashlight stays free.';

  @override
  String removeAdsPrice(String price) {
    return 'Remove ads · $price';
  }

  @override
  String get removeAdsOwned => 'Ads are removed for this purchase. Thank you!';

  @override
  String get removeAdsLoading => 'Loading store price...';

  @override
  String get removeAdsPurchasing => 'Waiting for the store to confirm...';

  @override
  String get removeAdsPending => 'The store is still confirming this purchase.';

  @override
  String get removeAdsRestoring => 'Checking previous purchases...';

  @override
  String get removeAdsUnavailable =>
      'The store is unavailable right now. Every flashlight feature still works.';

  @override
  String get removeAdsPurchaseFailed =>
      'The purchase could not be completed. Nothing was charged.';

  @override
  String get removeAdsRestoreFailed =>
      'Couldn\'t check previous purchases. Try again later.';

  @override
  String get removeAdsNoPurchase =>
      'No previous purchase was found on this account.';

  @override
  String get removeAdsProductNotFound =>
      'The store does not list the Remove Ads product yet.';

  @override
  String get removeAdsRestore => 'Restore purchases';

  @override
  String get removeAdsRetry => 'Try again';

  @override
  String get adLabel => 'Ad';

  @override
  String get monetizationStatusTitle => 'Purchase and ad status';

  @override
  String get adsStatusLabel => 'Ads';

  @override
  String get adsStatusAvailable => 'Available';

  @override
  String get adsStatusDisabled => 'Disabled';

  @override
  String get adsStatusWaitingConsent => 'Waiting for consent';

  @override
  String get adsStatusConfigurationMissing => 'Configuration missing';

  @override
  String get adsStatusStarting => 'Starting';

  @override
  String get removeAdsStatusLabel => 'Remove ads';

  @override
  String get removeAdsStatusNotPurchased => 'Not purchased';

  @override
  String get removeAdsStatusOwned => 'Lifetime ad-free';

  @override
  String get removeAdsStatusStoreUnavailable => 'Store unavailable';

  @override
  String get purchaseStatusLabel => 'Purchase';

  @override
  String get purchaseStatusAvailable => 'Available';

  @override
  String get purchaseStatusPending => 'Pending';

  @override
  String get purchaseStatusFailed => 'Failed';

  @override
  String get purchaseStatusUnavailable => 'Unavailable';

  @override
  String get privacyOptions => 'Privacy options';

  @override
  String get privacyOptionsBody => 'Review your ad consent choices.';

  @override
  String get openPrivacyOptions => 'Open privacy options';

  @override
  String get batterySection => 'Background reliability';

  @override
  String get batteryOptimizationTitle => 'Battery optimization';

  @override
  String get batteryStatusOptimized => 'Optimized by Android';

  @override
  String get batteryStatusUnrestricted => 'Unrestricted';

  @override
  String get batteryOptimizationBody =>
      'Android may pause background apps to save power, which can stop the flashlight or shake toggle after the screen locks. Exempting Flash Light Pro helps, but Doze, force-stop, and device-maker restrictions can still stop background work.';

  @override
  String get batteryAllowButton => 'Allow background operation';

  @override
  String get batteryOpenSettings => 'Battery settings';

  @override
  String get batteryRequestDenied =>
      'Battery optimization was not changed. You can allow it in system settings.';

  @override
  String get batteryChecking => 'Checking battery status...';

  @override
  String get premiumBadgeUpgrade => 'SPECIAL UPGRADE';

  @override
  String get premiumTitle => 'Go Ad-Free';

  @override
  String get premiumDescription =>
      'Enjoy Flash Light Pro without interruptions. One payment, lifetime access.';

  @override
  String get premiumBenefitsTitle => 'Everything included';

  @override
  String get premiumBenefitNoBanners => 'No banner ads';

  @override
  String get premiumBenefitNoNative => 'No native ads';

  @override
  String get premiumBenefitNoInterstitials => 'No interstitial ads';

  @override
  String get premiumBenefitNoAppOpen => 'No app open ads';

  @override
  String get premiumBenefitUninterrupted =>
      'Uninterrupted flashlight experience';

  @override
  String get premiumBenefitLifetime => 'Lifetime access with one payment';

  @override
  String get premiumOneTimePayment => 'ONE-TIME PAYMENT';

  @override
  String get premiumLifetimeAccess => 'LIFETIME ACCESS';

  @override
  String get premiumCta => 'Remove Ads Forever';

  @override
  String get premiumOneTimeNote => 'One-time purchase. No recurring charges.';

  @override
  String get premiumOwnedBadge => 'LIFETIME UNLOCKED';

  @override
  String get premiumOwnedTitle => 'You\'re Ad-Free!';

  @override
  String get premiumOwnedDescription =>
      'Thank you for supporting Flash Light Pro. Enjoy your lifetime ad-free experience.';

  @override
  String get premiumStorePriceLabel => 'Store price';

  @override
  String get termsAndConditions => 'Terms and conditions';

  @override
  String get termsEffectiveDate => 'Effective 8 November 2026';

  @override
  String get termsIntro =>
      'These terms govern your use of Flash Light Pro. By installing or using the app, you agree to them. If you do not agree, please uninstall the app.';

  @override
  String get termsLicenceTitle => 'Licence to use the app';

  @override
  String get termsLicenceBody =>
      'ClaudySoft grants you a personal, non-exclusive, non-transferable and revocable licence to use Flash Light Pro on devices you own or control. You may not copy, resell, redistribute, modify, reverse engineer or attempt to extract the source code, except where the law expressly allows it.';

  @override
  String get termsAdsTitle => 'Ads and Remove ads';

  @override
  String get termsAdsBody =>
      'The free version is supported by Google AdMob ads, shown only after the consent required in your region. An optional one-time, non-consumable purchase removes all ads. Payments and refunds are handled by Google Play or the App Store; the app never receives your payment details. You can restore the purchase from Settings.';

  @override
  String get termsSafetyTitle => 'Safety';

  @override
  String get termsSafetyBody =>
      'Flash Light Pro is a convenience tool, not safety or emergency equipment. SOS, strobe and Morse only produce light; they do not call emergency services or share your location. Strobe can trigger seizures in people with photosensitivity. Do not use the light while driving or in any situation where distraction is dangerous, and do not shine it into eyes, at vehicles or at aircraft. Long use can drain the battery and heat the device, and background operation is not guaranteed by the operating system.';

  @override
  String get termsUseTitle => 'Acceptable use';

  @override
  String get termsUseBody =>
      'Use the app only for lawful purposes. Do not use it to impersonate emergency services, harass or endanger anyone, distract drivers, or break road, aviation or public-order rules.';

  @override
  String get termsPermissionsTitle => 'Permissions and privacy';

  @override
  String get termsPermissionsBody =>
      'The app uses the camera flash, screen brightness, optional haptics and, only when Shake to toggle is on, the motion sensor. It does not request camera, microphone, location, contacts or file access. See the Privacy policy in Settings for how data is handled.';

  @override
  String get termsUpdatesTitle => 'Availability and updates';

  @override
  String get termsUpdatesBody =>
      'The core light modes work offline. Features may change, be removed or be unavailable on some devices, and updates may be required. We do not guarantee uninterrupted or error-free operation.';

  @override
  String get termsIpTitle => 'Intellectual property';

  @override
  String get termsIpBody =>
      'The app, its name, logo, design and code are owned by ClaudySoft or its licensors and are protected by law. These terms grant you a limited licence only.';

  @override
  String get termsThirdPartyTitle => 'Third-party services';

  @override
  String get termsThirdPartyBody =>
      'The app uses services from Google AdMob, Google Play and, on iOS, the Apple App Store. Those services are governed by their own terms and privacy policies.';

  @override
  String get termsLiabilityTitle => 'Disclaimers and liability';

  @override
  String get termsLiabilityBody =>
      'The app is provided \"as is\" and \"as available\", to the maximum extent permitted by law. We are not liable for indirect or consequential loss, and our total liability is limited to the greater of the amount you paid for the app in the last twelve months or USD 5. Nothing here limits rights that the law does not allow to be excluded.';

  @override
  String get termsIndemnityTitle => 'Indemnity';

  @override
  String get termsIndemnityBody =>
      'To the extent permitted by law, you agree to indemnify ClaudySoft against claims, losses and reasonable legal costs arising from your misuse of the app or your breach of these terms.';

  @override
  String get termsLawTitle => 'Governing law and consumer rights';

  @override
  String get termsLawBody =>
      'These terms are governed by the laws applicable where ClaudySoft is established, without limiting any mandatory consumer protection you have where you live. Disputes may be brought before a competent court or consumer authority under applicable law.';

  @override
  String get termsChangesTitle => 'Changes and contact';

  @override
  String get termsChangesBody =>
      'We may update these terms; the effective date above will change and continued use means you accept the new version. Questions? Contact us using the support email on the app\'s store listing.';

  @override
  String get termsFooter =>
      'By continuing to use Flash Light Pro, you accept these terms and the Privacy policy.';
}
