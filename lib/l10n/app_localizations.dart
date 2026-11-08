import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Flash Light Pro'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Premium lighting toolkit'**
  String get appTagline;

  /// No description provided for @offlineFooter.
  ///
  /// In en, this message translates to:
  /// **'The flashlight works offline. Ads and purchases need a connection.'**
  String get offlineFooter;

  /// No description provided for @screenFallbackFooter.
  ///
  /// In en, this message translates to:
  /// **'Screen flash fallback is active — the display is the light source.'**
  String get screenFallbackFooter;

  /// No description provided for @modeTorch.
  ///
  /// In en, this message translates to:
  /// **'Torch'**
  String get modeTorch;

  /// No description provided for @modeScreen.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get modeScreen;

  /// No description provided for @modeSos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get modeSos;

  /// No description provided for @modeStrobe.
  ///
  /// In en, this message translates to:
  /// **'Strobe'**
  String get modeStrobe;

  /// No description provided for @modeMorse.
  ///
  /// In en, this message translates to:
  /// **'Morse'**
  String get modeMorse;

  /// No description provided for @modeFlashlight.
  ///
  /// In en, this message translates to:
  /// **'Flashlight'**
  String get modeFlashlight;

  /// No description provided for @modeScreenLight.
  ///
  /// In en, this message translates to:
  /// **'Screen light'**
  String get modeScreenLight;

  /// No description provided for @modeSosSignal.
  ///
  /// In en, this message translates to:
  /// **'SOS signal'**
  String get modeSosSignal;

  /// No description provided for @modeMorsePlayback.
  ///
  /// In en, this message translates to:
  /// **'Morse playback'**
  String get modeMorsePlayback;

  /// No description provided for @statusTorchOn.
  ///
  /// In en, this message translates to:
  /// **'Flash Light On'**
  String get statusTorchOn;

  /// No description provided for @statusScreenOn.
  ///
  /// In en, this message translates to:
  /// **'Screen Light On'**
  String get statusScreenOn;

  /// No description provided for @statusSosActive.
  ///
  /// In en, this message translates to:
  /// **'SOS Signal Active'**
  String get statusSosActive;

  /// No description provided for @statusStrobeOn.
  ///
  /// In en, this message translates to:
  /// **'Strobe On'**
  String get statusStrobeOn;

  /// No description provided for @statusMorsePaused.
  ///
  /// In en, this message translates to:
  /// **'Morse Paused'**
  String get statusMorsePaused;

  /// No description provided for @statusSendingMorse.
  ///
  /// In en, this message translates to:
  /// **'Sending Morse'**
  String get statusSendingMorse;

  /// No description provided for @statusChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking flashlight...'**
  String get statusChecking;

  /// No description provided for @statusTorchOff.
  ///
  /// In en, this message translates to:
  /// **'Flash Light Off'**
  String get statusTorchOff;

  /// No description provided for @statusTorchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Flashlight not available'**
  String get statusTorchUnavailable;

  /// No description provided for @statusScreenOff.
  ///
  /// In en, this message translates to:
  /// **'Screen Light Off'**
  String get statusScreenOff;

  /// No description provided for @statusSosReady.
  ///
  /// In en, this message translates to:
  /// **'SOS Ready'**
  String get statusSosReady;

  /// No description provided for @statusSosNeedsTorch.
  ///
  /// In en, this message translates to:
  /// **'SOS needs a flashlight'**
  String get statusSosNeedsTorch;

  /// No description provided for @statusStrobeReady.
  ///
  /// In en, this message translates to:
  /// **'Strobe Ready'**
  String get statusStrobeReady;

  /// No description provided for @statusStrobeNeedsTorch.
  ///
  /// In en, this message translates to:
  /// **'Strobe needs a flashlight'**
  String get statusStrobeNeedsTorch;

  /// No description provided for @statusMorseReady.
  ///
  /// In en, this message translates to:
  /// **'Morse Ready'**
  String get statusMorseReady;

  /// No description provided for @subtitleAutoOff.
  ///
  /// In en, this message translates to:
  /// **'Auto-off in {countdown}. Tap the timer to change or cancel it.'**
  String subtitleAutoOff(String countdown);

  /// No description provided for @subtitleMorsePaused.
  ///
  /// In en, this message translates to:
  /// **'Playback is paused. Resume or stop below.'**
  String get subtitleMorsePaused;

  /// No description provided for @subtitleTapStop.
  ///
  /// In en, this message translates to:
  /// **'Tap the power button to stop.'**
  String get subtitleTapStop;

  /// No description provided for @subtitleCheckingHardware.
  ///
  /// In en, this message translates to:
  /// **'Checking this device’s hardware.'**
  String get subtitleCheckingHardware;

  /// No description provided for @subtitleTorchReady.
  ///
  /// In en, this message translates to:
  /// **'Tap to turn the flashlight on or off.'**
  String get subtitleTorchReady;

  /// No description provided for @subtitleTorchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Use Screen Light instead — it needs no torch hardware.'**
  String get subtitleTorchUnavailable;

  /// No description provided for @subtitleScreenReady.
  ///
  /// In en, this message translates to:
  /// **'Tap to open a full-screen light.'**
  String get subtitleScreenReady;

  /// No description provided for @subtitleSosReady.
  ///
  /// In en, this message translates to:
  /// **'Standard ... --- ... distress signal.'**
  String get subtitleSosReady;

  /// No description provided for @subtitleStrobeReady.
  ///
  /// In en, this message translates to:
  /// **'Adjustable flash speed with a safety warning.'**
  String get subtitleStrobeReady;

  /// No description provided for @subtitleMorseReady.
  ///
  /// In en, this message translates to:
  /// **'Tap Play to send your message as light.'**
  String get subtitleMorseReady;

  /// No description provided for @hintStop.
  ///
  /// In en, this message translates to:
  /// **'Double tap to stop the light'**
  String get hintStop;

  /// No description provided for @hintTorchOn.
  ///
  /// In en, this message translates to:
  /// **'Double tap to turn the flashlight on'**
  String get hintTorchOn;

  /// No description provided for @hintScreen.
  ///
  /// In en, this message translates to:
  /// **'Double tap to open screen light'**
  String get hintScreen;

  /// No description provided for @hintSos.
  ///
  /// In en, this message translates to:
  /// **'Double tap to start the SOS signal'**
  String get hintSos;

  /// No description provided for @hintStrobe.
  ///
  /// In en, this message translates to:
  /// **'Double tap to start the strobe'**
  String get hintStrobe;

  /// No description provided for @hintMorse.
  ///
  /// In en, this message translates to:
  /// **'Double tap to play the Morse message'**
  String get hintMorse;

  /// No description provided for @announcementOn.
  ///
  /// In en, this message translates to:
  /// **'{mode} on'**
  String announcementOn(String mode);

  /// No description provided for @announcementOff.
  ///
  /// In en, this message translates to:
  /// **'{mode} off'**
  String announcementOff(String mode);

  /// No description provided for @timerCountdown.
  ///
  /// In en, this message translates to:
  /// **'Auto-off in {countdown}'**
  String timerCountdown(String countdown);

  /// No description provided for @timerOff.
  ///
  /// In en, this message translates to:
  /// **'Auto-off off'**
  String get timerOff;

  /// No description provided for @timerPreset.
  ///
  /// In en, this message translates to:
  /// **'Auto-off {minutes} min'**
  String timerPreset(int minutes);

  /// No description provided for @timerSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-off timer'**
  String get timerSheetTitle;

  /// No description provided for @timerSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turns off the active light automatically.'**
  String get timerSheetSubtitle;

  /// No description provided for @timerTurningOff.
  ///
  /// In en, this message translates to:
  /// **'Turning off in {countdown}'**
  String timerTurningOff(String countdown);

  /// No description provided for @timerPresetChip.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String timerPresetChip(int minutes);

  /// No description provided for @timerCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom minutes'**
  String get timerCustomLabel;

  /// No description provided for @timerSet.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get timerSet;

  /// No description provided for @timerCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel timer'**
  String get timerCancel;

  /// No description provided for @timerClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get timerClose;

  /// No description provided for @timerCustomError.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number between 1 and {max}.'**
  String timerCustomError(int max);

  /// No description provided for @timerButton.
  ///
  /// In en, this message translates to:
  /// **'Auto-off timer'**
  String get timerButton;

  /// No description provided for @flashlight.
  ///
  /// In en, this message translates to:
  /// **'Flashlight'**
  String get flashlight;

  /// No description provided for @rearCameraTorch.
  ///
  /// In en, this message translates to:
  /// **'Rear camera torch'**
  String get rearCameraTorch;

  /// No description provided for @noUsableTorch.
  ///
  /// In en, this message translates to:
  /// **'No usable torch detected'**
  String get noUsableTorch;

  /// No description provided for @torchStrength.
  ///
  /// In en, this message translates to:
  /// **'Torch strength'**
  String get torchStrength;

  /// No description provided for @torchStrengthUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Torch strength is not supported on this device.'**
  String get torchStrengthUnsupported;

  /// No description provided for @screenLightWorksWithoutTorch.
  ///
  /// In en, this message translates to:
  /// **'Screen Light works even without torch hardware.'**
  String get screenLightWorksWithoutTorch;

  /// No description provided for @screenLight.
  ///
  /// In en, this message translates to:
  /// **'Screen Light'**
  String get screenLight;

  /// No description provided for @screenPanelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full-screen light with adjustable color'**
  String get screenPanelSubtitle;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @brightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get brightness;

  /// No description provided for @brightnessRestored.
  ///
  /// In en, this message translates to:
  /// **'Your original screen brightness returns when you exit.'**
  String get brightnessRestored;

  /// No description provided for @sosSignal.
  ///
  /// In en, this message translates to:
  /// **'SOS signal'**
  String get sosSignal;

  /// No description provided for @sosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Standard international distress pattern'**
  String get sosSubtitle;

  /// No description provided for @sosTransmitting.
  ///
  /// In en, this message translates to:
  /// **'Transmitting continuously. Turn it off when help arrives.'**
  String get sosTransmitting;

  /// No description provided for @sosPlaysOnTorch.
  ///
  /// In en, this message translates to:
  /// **'Plays on the flashlight until you stop it.'**
  String get sosPlaysOnTorch;

  /// No description provided for @sosNeedsTorch.
  ///
  /// In en, this message translates to:
  /// **'SOS needs a working flashlight on this device.'**
  String get sosNeedsTorch;

  /// No description provided for @strobe.
  ///
  /// In en, this message translates to:
  /// **'Strobe'**
  String get strobe;

  /// No description provided for @strobeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjustable flash speed'**
  String get strobeSubtitle;

  /// No description provided for @flashSpeed.
  ///
  /// In en, this message translates to:
  /// **'Flash speed'**
  String get flashSpeed;

  /// No description provided for @speedHz.
  ///
  /// In en, this message translates to:
  /// **'{value} Hz'**
  String speedHz(String value);

  /// No description provided for @photosensitivityWarning.
  ///
  /// In en, this message translates to:
  /// **'Photosensitivity warning: flashing light can trigger seizures. Stop immediately if you feel unwell and keep the light away from your eyes.'**
  String get photosensitivityWarning;

  /// No description provided for @morseTitle.
  ///
  /// In en, this message translates to:
  /// **'Morse code'**
  String get morseTitle;

  /// No description provided for @morseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send A-Z and 0-9 as light signals'**
  String get morseSubtitle;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @morseHint.
  ///
  /// In en, this message translates to:
  /// **'SOS HELLO 123'**
  String get morseHint;

  /// No description provided for @clearMessage.
  ///
  /// In en, this message translates to:
  /// **'Clear message'**
  String get clearMessage;

  /// No description provided for @morsePreviewPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your Morse preview appears here.'**
  String get morsePreviewPlaceholder;

  /// No description provided for @morseUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported: {characters} — use A-Z and 0-9.'**
  String morseUnsupported(String characters);

  /// No description provided for @morsePlaysOnTorch.
  ///
  /// In en, this message translates to:
  /// **'Plays on the flashlight.'**
  String get morsePlaysOnTorch;

  /// No description provided for @morseScreenFallback.
  ///
  /// In en, this message translates to:
  /// **'No flashlight detected — the screen will flash instead.'**
  String get morseScreenFallback;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @playMorse.
  ///
  /// In en, this message translates to:
  /// **'Play Morse'**
  String get playMorse;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message to send in Morse code.'**
  String get typeMessage;

  /// No description provided for @unsupportedCharacters.
  ///
  /// In en, this message translates to:
  /// **'Unsupported characters: {characters}. Use A-Z and 0-9.'**
  String unsupportedCharacters(String characters);

  /// No description provided for @strobeNeedsTorchMessage.
  ///
  /// In en, this message translates to:
  /// **'Strobe needs a working flashlight on this device.'**
  String get strobeNeedsTorchMessage;

  /// No description provided for @lightingError.
  ///
  /// In en, this message translates to:
  /// **'Lighting Error'**
  String get lightingError;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @errorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The flashlight is not available on this device.'**
  String get errorUnavailable;

  /// No description provided for @errorCameraInUse.
  ///
  /// In en, this message translates to:
  /// **'The camera is in use by another app. Close it and try again.'**
  String get errorCameraInUse;

  /// No description provided for @errorEnable.
  ///
  /// In en, this message translates to:
  /// **'Could not turn on the flashlight. Please try again.'**
  String get errorEnable;

  /// No description provided for @errorDisable.
  ///
  /// In en, this message translates to:
  /// **'Could not turn off the flashlight. Please try again.'**
  String get errorDisable;

  /// No description provided for @errorCheck.
  ///
  /// In en, this message translates to:
  /// **'Could not check the flashlight. Please try again.'**
  String get errorCheck;

  /// No description provided for @errorPlatform.
  ///
  /// In en, this message translates to:
  /// **'Flashlight control is not supported on this platform.'**
  String get errorPlatform;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while controlling the light.'**
  String get errorUnexpected;

  /// No description provided for @exitScreenLight.
  ///
  /// In en, this message translates to:
  /// **'Exit screen light'**
  String get exitScreenLight;

  /// No description provided for @hideCustomColor.
  ///
  /// In en, this message translates to:
  /// **'Hide custom color'**
  String get hideCustomColor;

  /// No description provided for @customColor.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get customColor;

  /// No description provided for @turnOffLight.
  ///
  /// In en, this message translates to:
  /// **'Turn off light'**
  String get turnOffLight;

  /// No description provided for @hue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get hue;

  /// No description provided for @saturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get saturation;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Language, feedback, and behavior'**
  String get settingsSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageBengali.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get languageBengali;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @motionSection.
  ///
  /// In en, this message translates to:
  /// **'Motion'**
  String get motionSection;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get haptics;

  /// No description provided for @hapticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vibrate when you use the power controls.'**
  String get hapticsSubtitle;

  /// No description provided for @shakeToToggle.
  ///
  /// In en, this message translates to:
  /// **'Shake to toggle'**
  String get shakeToToggle;

  /// No description provided for @shakeSubtitleOn.
  ///
  /// In en, this message translates to:
  /// **'Shake your phone to turn the flashlight on or off, even when the app is in the background.'**
  String get shakeSubtitleOn;

  /// No description provided for @shakeSubtitleOff.
  ///
  /// In en, this message translates to:
  /// **'Off. Turn on to shake the flashlight on or off, even in the background.'**
  String get shakeSubtitleOff;

  /// No description provided for @shakeSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Shake sensitivity'**
  String get shakeSensitivity;

  /// No description provided for @sensitivityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get sensitivityLow;

  /// No description provided for @sensitivityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get sensitivityMedium;

  /// No description provided for @sensitivityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get sensitivityHigh;

  /// No description provided for @shakeMonitoringActive.
  ///
  /// In en, this message translates to:
  /// **'Background monitoring is on. A persistent notification keeps shake working after you leave the app.'**
  String get shakeMonitoringActive;

  /// No description provided for @shakeMonitoringInactive.
  ///
  /// In en, this message translates to:
  /// **'Background monitoring is not running. Shake works only while the app is open.'**
  String get shakeMonitoringInactive;

  /// No description provided for @shakeNotificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off, so the required monitoring notification is hidden. Monitoring still runs and appears in Android\'s active apps list.'**
  String get shakeNotificationsOff;

  /// No description provided for @shakeBackgroundUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This device does not support background shake monitoring. Shake works while the app is open.'**
  String get shakeBackgroundUnsupported;

  /// No description provided for @keepScreenAwake.
  ///
  /// In en, this message translates to:
  /// **'Keep screen awake'**
  String get keepScreenAwake;

  /// No description provided for @keepScreenAwakeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prevent the screen from sleeping while a light is active.'**
  String get keepScreenAwakeSubtitle;

  /// No description provided for @backgroundSection.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get backgroundSection;

  /// No description provided for @keepFlashlightOnBackground.
  ///
  /// In en, this message translates to:
  /// **'Keep Flashlight On in Background'**
  String get keepFlashlightOnBackground;

  /// No description provided for @keepFlashlightOnBackgroundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Leaves the steady flashlight on when you switch apps or lock the screen. Android shows a notification with a Stop action. Hardware, battery, or system limits can still turn it off.'**
  String get keepFlashlightOnBackgroundSubtitle;

  /// No description provided for @keepFlashlightOnBackgroundUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Not available on iOS. The system turns the flashlight off when Flash Light Pro is suspended.'**
  String get keepFlashlightOnBackgroundUnsupported;

  /// No description provided for @backgroundNotificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. The flashlight stays on, but the Stop button is only available in the app.'**
  String get backgroundNotificationsOff;

  /// No description provided for @reduceAnimations.
  ///
  /// In en, this message translates to:
  /// **'Reduce animations'**
  String get reduceAnimations;

  /// No description provided for @reduceAnimationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use shorter transitions and calmer motion.'**
  String get reduceAnimationsSubtitle;

  /// No description provided for @defaultMode.
  ///
  /// In en, this message translates to:
  /// **'Default mode'**
  String get defaultMode;

  /// No description provided for @defaultModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The mode selected when the app opens.'**
  String get defaultModeSubtitle;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @appInfo.
  ///
  /// In en, this message translates to:
  /// **'App information'**
  String get appInfo;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get openSourceLicenses;

  /// No description provided for @permissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions and device notes'**
  String get permissionsTitle;

  /// No description provided for @permissionsBody.
  ///
  /// In en, this message translates to:
  /// **'The app uses the camera torch, screen brightness, haptics, and — only when Shake to toggle is on — the motion sensor. On Android, background shake monitoring runs in a foreground service with a persistent notification. The app does not request internet, location, camera images, microphone, or contacts.'**
  String get permissionsBody;

  /// No description provided for @volumeButtonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Volume buttons'**
  String get volumeButtonsTitle;

  /// No description provided for @volumeButtonsBody.
  ///
  /// In en, this message translates to:
  /// **'Android and iOS reserve the volume buttons for system audio and accessibility. Flash Light Pro does not intercept them, because that would require accessibility or root access, which this app does not request.'**
  String get volumeButtonsBody;

  /// No description provided for @iosLimitationsTitle.
  ///
  /// In en, this message translates to:
  /// **'iOS integration'**
  String get iosLimitationsTitle;

  /// No description provided for @iosLimitationsBody.
  ///
  /// In en, this message translates to:
  /// **'On iOS, the Shake to toggle and Shortcuts actions work while the app or the system intent is running. iOS does not offer Android-style Quick Settings tiles or home screen widgets for unrestricted background flashlight control. iOS also suspends app execution and releases the torch when the app leaves the foreground, so there is no background flashlight mode.'**
  String get iosLimitationsBody;

  /// No description provided for @madeOffline.
  ///
  /// In en, this message translates to:
  /// **'The flashlight works offline. Ads need a connection.'**
  String get madeOffline;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'Flash Light Pro works on your device. The flashlight itself needs no account and no network. The free version shows ads from Google AdMob, and an optional one-time purchase removes them.'**
  String get privacyIntro;

  /// No description provided for @privacyLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Data stored on your device'**
  String get privacyLocalTitle;

  /// No description provided for @privacyLocalBody.
  ///
  /// In en, this message translates to:
  /// **'Preferences such as language, default mode, brightness, and shake sensitivity are stored locally by the operating system. Ad frequency limits, your ad consent choice, and Remove ads purchase status are cached locally too. The Android Quick Settings tile and home screen widget also store the last torch state locally so they can show the correct state.'**
  String get privacyLocalBody;

  /// No description provided for @privacyHardwareTitle.
  ///
  /// In en, this message translates to:
  /// **'Hardware access'**
  String get privacyHardwareTitle;

  /// No description provided for @privacyHardwareBody.
  ///
  /// In en, this message translates to:
  /// **'The app uses the camera flash (torch) and screen brightness. It reads the accelerometer only while Shake to toggle is enabled: in the foreground, and on Android through a foreground service with a persistent notification when you leave the app. It does not capture camera images, microphone audio, location, contacts, or photos.'**
  String get privacyHardwareBody;

  /// No description provided for @privacyAdsTitle.
  ///
  /// In en, this message translates to:
  /// **'Advertising'**
  String get privacyAdsTitle;

  /// No description provided for @privacyAdsBody.
  ///
  /// In en, this message translates to:
  /// **'The free version may show banner, native, interstitial, and app-open ads from Google AdMob. Ads are requested only after the consent required in your region, and never while a light is active or an update is required. You can review your choices with Privacy options in Settings. The Remove ads purchase stops all ads on this account.'**
  String get privacyAdsBody;

  /// No description provided for @privacyBillingTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove ads purchase'**
  String get privacyBillingTitle;

  /// No description provided for @privacyBillingBody.
  ///
  /// In en, this message translates to:
  /// **'Remove ads is a one-time, non-consumable purchase handled by Google Play or the App Store. The app never receives your payment details. The entitlement is cached on your device and confirmed with the store, and you can restore it at any time from Settings.'**
  String get privacyBillingBody;

  /// No description provided for @privacyNoAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'No analytics or crash uploads'**
  String get privacyNoAnalyticsTitle;

  /// No description provided for @privacyNoAnalyticsBody.
  ///
  /// In en, this message translates to:
  /// **'The app includes no analytics SDK and no remote crash reporting. Google AdMob may collect device and ad-interaction data under Google\'s own privacy terms. The flashlight, SOS, strobe, Morse, and screen light keep working without a connection.'**
  String get privacyNoAnalyticsBody;

  /// No description provided for @privacyPolicyFooter.
  ///
  /// In en, this message translates to:
  /// **'This policy applies to Flash Light Pro version 0.1.0. On iOS the app requests motion access, and only when Shake to toggle is enabled. On Android 13 and later it asks for notification permission so the background flashlight and shake services can show their controls. Ads and purchases are provided by Google AdMob and the platform store under their own privacy terms.'**
  String get privacyPolicyFooter;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @updateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get updateRequiredTitle;

  /// No description provided for @updateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'A newer version of Flash Light Pro is required to keep the app working safely. Please update to continue.'**
  String get updateRequiredBody;

  /// No description provided for @updateRecommendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Recommended'**
  String get updateRecommendedTitle;

  /// No description provided for @updateRecommendedBody.
  ///
  /// In en, this message translates to:
  /// **'This update is recommended for the best experience. You can update now or keep using the current version.'**
  String get updateRecommendedBody;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'New Update Available'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'A newer version of Flash Light Pro is available with improvements and fixes.'**
  String get updateAvailableBody;

  /// No description provided for @updateInstalledVersion.
  ///
  /// In en, this message translates to:
  /// **'Installed: {version}'**
  String updateInstalledVersion(String version);

  /// No description provided for @updateAvailableBuild.
  ///
  /// In en, this message translates to:
  /// **'Available build: {build}'**
  String updateAvailableBuild(int build);

  /// No description provided for @updateVersionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Latest version on Google Play'**
  String get updateVersionUnknown;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateOpenStore.
  ///
  /// In en, this message translates to:
  /// **'Open Play Store'**
  String get updateOpenStore;

  /// No description provided for @updateTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get updateTryAgain;

  /// No description provided for @updateDownloadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloading update...'**
  String get updateDownloadingTitle;

  /// No description provided for @updateDownloadingBody.
  ///
  /// In en, this message translates to:
  /// **'You can keep using the flashlight while the update downloads.'**
  String get updateDownloadingBody;

  /// No description provided for @updateReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Update ready'**
  String get updateReadyTitle;

  /// No description provided for @updateReadyBody.
  ///
  /// In en, this message translates to:
  /// **'The update has been downloaded. Install it now to finish.'**
  String get updateReadyBody;

  /// No description provided for @updateInstallNow.
  ///
  /// In en, this message translates to:
  /// **'Install Update'**
  String get updateInstallNow;

  /// No description provided for @updateInstallingTitle.
  ///
  /// In en, this message translates to:
  /// **'Installing update...'**
  String get updateInstallingTitle;

  /// No description provided for @updateInstallingBody.
  ///
  /// In en, this message translates to:
  /// **'Google Play is installing the update. The app may restart.'**
  String get updateInstallingBody;

  /// No description provided for @updateInstalledBody.
  ///
  /// In en, this message translates to:
  /// **'The update is installed. Restart the app if it does not reopen automatically.'**
  String get updateInstalledBody;

  /// No description provided for @updateErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Update couldn\'t start'**
  String get updateErrorTitle;

  /// No description provided for @updateErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Google Play could not start the update. Check your connection and try again.'**
  String get updateErrorBody;

  /// No description provided for @updateStoreError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the store. Try again later.'**
  String get updateStoreError;

  /// No description provided for @updateCanceled.
  ///
  /// In en, this message translates to:
  /// **'The update was canceled.'**
  String get updateCanceled;

  /// No description provided for @updateReadySnack.
  ///
  /// In en, this message translates to:
  /// **'Update ready to install.'**
  String get updateReadySnack;

  /// No description provided for @updateHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get updateHide;

  /// No description provided for @updateContinueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Continue without updating'**
  String get updateContinueAnyway;

  /// No description provided for @updateCachedNotice.
  ///
  /// In en, this message translates to:
  /// **'This update was verified earlier. Reconnect to confirm it.'**
  String get updateCachedNotice;

  /// No description provided for @settingsUpdates.
  ///
  /// In en, this message translates to:
  /// **'App updates'**
  String get settingsUpdates;

  /// No description provided for @settingsUpdateCheck.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsUpdateCheck;

  /// No description provided for @settingsUpdateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get settingsUpdateChecking;

  /// No description provided for @settingsUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re using the latest version'**
  String get settingsUpToDate;

  /// No description provided for @settingsUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available (build {build})'**
  String settingsUpdateAvailable(int build);

  /// No description provided for @settingsUpdateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading update...'**
  String get settingsUpdateDownloading;

  /// No description provided for @settingsUpdateReady.
  ///
  /// In en, this message translates to:
  /// **'Update ready to install'**
  String get settingsUpdateReady;

  /// No description provided for @settingsUpdateInstalling.
  ///
  /// In en, this message translates to:
  /// **'Installing update...'**
  String get settingsUpdateInstalling;

  /// No description provided for @settingsUpdateInstalled.
  ///
  /// In en, this message translates to:
  /// **'Update installed'**
  String get settingsUpdateInstalled;

  /// No description provided for @settingsUpdateInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get settingsUpdateInstall;

  /// No description provided for @settingsUpdateAction.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get settingsUpdateAction;

  /// No description provided for @settingsUpdateCheckAction.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get settingsUpdateCheckAction;

  /// No description provided for @settingsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates'**
  String get settingsUpdateFailed;

  /// No description provided for @settingsUpdateStoreManaged.
  ///
  /// In en, this message translates to:
  /// **'Updates are handled by your app store'**
  String get settingsUpdateStoreManaged;

  /// No description provided for @removeAdsTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove ads'**
  String get removeAdsTitle;

  /// No description provided for @removeAdsBody.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase. Removes banner, interstitial, and app-open ads. The flashlight stays free.'**
  String get removeAdsBody;

  /// No description provided for @removeAdsPrice.
  ///
  /// In en, this message translates to:
  /// **'Remove ads · {price}'**
  String removeAdsPrice(String price);

  /// No description provided for @removeAdsOwned.
  ///
  /// In en, this message translates to:
  /// **'Ads are removed for this purchase. Thank you!'**
  String get removeAdsOwned;

  /// No description provided for @removeAdsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading store price...'**
  String get removeAdsLoading;

  /// No description provided for @removeAdsPurchasing.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the store to confirm...'**
  String get removeAdsPurchasing;

  /// No description provided for @removeAdsPending.
  ///
  /// In en, this message translates to:
  /// **'The store is still confirming this purchase.'**
  String get removeAdsPending;

  /// No description provided for @removeAdsRestoring.
  ///
  /// In en, this message translates to:
  /// **'Checking previous purchases...'**
  String get removeAdsRestoring;

  /// No description provided for @removeAdsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The store is unavailable right now. Every flashlight feature still works.'**
  String get removeAdsUnavailable;

  /// No description provided for @removeAdsPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase could not be completed. Nothing was charged.'**
  String get removeAdsPurchaseFailed;

  /// No description provided for @removeAdsRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check previous purchases. Try again later.'**
  String get removeAdsRestoreFailed;

  /// No description provided for @removeAdsNoPurchase.
  ///
  /// In en, this message translates to:
  /// **'No previous purchase was found on this account.'**
  String get removeAdsNoPurchase;

  /// No description provided for @removeAdsProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'The store does not list the Remove Ads product yet.'**
  String get removeAdsProductNotFound;

  /// No description provided for @removeAdsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get removeAdsRestore;

  /// No description provided for @removeAdsRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get removeAdsRetry;

  /// No description provided for @adLabel.
  ///
  /// In en, this message translates to:
  /// **'Ad'**
  String get adLabel;

  /// No description provided for @monetizationStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase and ad status'**
  String get monetizationStatusTitle;

  /// No description provided for @adsStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get adsStatusLabel;

  /// No description provided for @adsStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get adsStatusAvailable;

  /// No description provided for @adsStatusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get adsStatusDisabled;

  /// No description provided for @adsStatusWaitingConsent.
  ///
  /// In en, this message translates to:
  /// **'Waiting for consent'**
  String get adsStatusWaitingConsent;

  /// No description provided for @adsStatusConfigurationMissing.
  ///
  /// In en, this message translates to:
  /// **'Configuration missing'**
  String get adsStatusConfigurationMissing;

  /// No description provided for @adsStatusStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get adsStatusStarting;

  /// No description provided for @removeAdsStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove ads'**
  String get removeAdsStatusLabel;

  /// No description provided for @removeAdsStatusNotPurchased.
  ///
  /// In en, this message translates to:
  /// **'Not purchased'**
  String get removeAdsStatusNotPurchased;

  /// No description provided for @removeAdsStatusOwned.
  ///
  /// In en, this message translates to:
  /// **'Lifetime ad-free'**
  String get removeAdsStatusOwned;

  /// No description provided for @removeAdsStatusStoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Store unavailable'**
  String get removeAdsStatusStoreUnavailable;

  /// No description provided for @purchaseStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchaseStatusLabel;

  /// No description provided for @purchaseStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get purchaseStatusAvailable;

  /// No description provided for @purchaseStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get purchaseStatusPending;

  /// No description provided for @purchaseStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get purchaseStatusFailed;

  /// No description provided for @purchaseStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get purchaseStatusUnavailable;

  /// No description provided for @privacyOptions.
  ///
  /// In en, this message translates to:
  /// **'Privacy options'**
  String get privacyOptions;

  /// No description provided for @privacyOptionsBody.
  ///
  /// In en, this message translates to:
  /// **'Review your ad consent choices.'**
  String get privacyOptionsBody;

  /// No description provided for @openPrivacyOptions.
  ///
  /// In en, this message translates to:
  /// **'Open privacy options'**
  String get openPrivacyOptions;

  /// No description provided for @batterySection.
  ///
  /// In en, this message translates to:
  /// **'Background reliability'**
  String get batterySection;

  /// No description provided for @batteryOptimizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization'**
  String get batteryOptimizationTitle;

  /// No description provided for @batteryStatusOptimized.
  ///
  /// In en, this message translates to:
  /// **'Optimized by Android'**
  String get batteryStatusOptimized;

  /// No description provided for @batteryStatusUnrestricted.
  ///
  /// In en, this message translates to:
  /// **'Unrestricted'**
  String get batteryStatusUnrestricted;

  /// No description provided for @batteryOptimizationBody.
  ///
  /// In en, this message translates to:
  /// **'Android may pause background apps to save power, which can stop the flashlight or shake toggle after the screen locks. Exempting Flash Light Pro helps, but Doze, force-stop, and device-maker restrictions can still stop background work.'**
  String get batteryOptimizationBody;

  /// No description provided for @batteryAllowButton.
  ///
  /// In en, this message translates to:
  /// **'Allow background operation'**
  String get batteryAllowButton;

  /// No description provided for @batteryOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Battery settings'**
  String get batteryOpenSettings;

  /// No description provided for @batteryRequestDenied.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization was not changed. You can allow it in system settings.'**
  String get batteryRequestDenied;

  /// No description provided for @batteryChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking battery status...'**
  String get batteryChecking;

  /// No description provided for @premiumBadgeUpgrade.
  ///
  /// In en, this message translates to:
  /// **'SPECIAL UPGRADE'**
  String get premiumBadgeUpgrade;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Go Ad-Free'**
  String get premiumTitle;

  /// No description provided for @premiumDescription.
  ///
  /// In en, this message translates to:
  /// **'Enjoy Flash Light Pro without interruptions. One payment, lifetime access.'**
  String get premiumDescription;

  /// No description provided for @premiumBenefitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Everything included'**
  String get premiumBenefitsTitle;

  /// No description provided for @premiumBenefitNoBanners.
  ///
  /// In en, this message translates to:
  /// **'No banner ads'**
  String get premiumBenefitNoBanners;

  /// No description provided for @premiumBenefitNoNative.
  ///
  /// In en, this message translates to:
  /// **'No native ads'**
  String get premiumBenefitNoNative;

  /// No description provided for @premiumBenefitNoInterstitials.
  ///
  /// In en, this message translates to:
  /// **'No interstitial ads'**
  String get premiumBenefitNoInterstitials;

  /// No description provided for @premiumBenefitNoAppOpen.
  ///
  /// In en, this message translates to:
  /// **'No app open ads'**
  String get premiumBenefitNoAppOpen;

  /// No description provided for @premiumBenefitUninterrupted.
  ///
  /// In en, this message translates to:
  /// **'Uninterrupted flashlight experience'**
  String get premiumBenefitUninterrupted;

  /// No description provided for @premiumBenefitLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime access with one payment'**
  String get premiumBenefitLifetime;

  /// No description provided for @premiumOneTimePayment.
  ///
  /// In en, this message translates to:
  /// **'ONE-TIME PAYMENT'**
  String get premiumOneTimePayment;

  /// No description provided for @premiumLifetimeAccess.
  ///
  /// In en, this message translates to:
  /// **'LIFETIME ACCESS'**
  String get premiumLifetimeAccess;

  /// No description provided for @premiumCta.
  ///
  /// In en, this message translates to:
  /// **'Remove Ads Forever'**
  String get premiumCta;

  /// No description provided for @premiumOneTimeNote.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase. No recurring charges.'**
  String get premiumOneTimeNote;

  /// No description provided for @premiumOwnedBadge.
  ///
  /// In en, this message translates to:
  /// **'LIFETIME UNLOCKED'**
  String get premiumOwnedBadge;

  /// No description provided for @premiumOwnedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re Ad-Free!'**
  String get premiumOwnedTitle;

  /// No description provided for @premiumOwnedDescription.
  ///
  /// In en, this message translates to:
  /// **'Thank you for supporting Flash Light Pro. Enjoy your lifetime ad-free experience.'**
  String get premiumOwnedDescription;

  /// No description provided for @premiumStorePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Store price'**
  String get premiumStorePriceLabel;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and conditions'**
  String get termsAndConditions;

  /// No description provided for @termsEffectiveDate.
  ///
  /// In en, this message translates to:
  /// **'Effective 8 November 2026'**
  String get termsEffectiveDate;

  /// No description provided for @termsIntro.
  ///
  /// In en, this message translates to:
  /// **'These terms govern your use of Flash Light Pro. By installing or using the app, you agree to them. If you do not agree, please uninstall the app.'**
  String get termsIntro;

  /// No description provided for @termsLicenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Licence to use the app'**
  String get termsLicenceTitle;

  /// No description provided for @termsLicenceBody.
  ///
  /// In en, this message translates to:
  /// **'ClaudySoft grants you a personal, non-exclusive, non-transferable and revocable licence to use Flash Light Pro on devices you own or control. You may not copy, resell, redistribute, modify, reverse engineer or attempt to extract the source code, except where the law expressly allows it.'**
  String get termsLicenceBody;

  /// No description provided for @termsAdsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ads and Remove ads'**
  String get termsAdsTitle;

  /// No description provided for @termsAdsBody.
  ///
  /// In en, this message translates to:
  /// **'The free version is supported by Google AdMob ads, shown only after the consent required in your region. An optional one-time, non-consumable purchase removes all ads. Payments and refunds are handled by Google Play or the App Store; the app never receives your payment details. You can restore the purchase from Settings.'**
  String get termsAdsBody;

  /// No description provided for @termsSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get termsSafetyTitle;

  /// No description provided for @termsSafetyBody.
  ///
  /// In en, this message translates to:
  /// **'Flash Light Pro is a convenience tool, not safety or emergency equipment. SOS, strobe and Morse only produce light; they do not call emergency services or share your location. Strobe can trigger seizures in people with photosensitivity. Do not use the light while driving or in any situation where distraction is dangerous, and do not shine it into eyes, at vehicles or at aircraft. Long use can drain the battery and heat the device, and background operation is not guaranteed by the operating system.'**
  String get termsSafetyBody;

  /// No description provided for @termsUseTitle.
  ///
  /// In en, this message translates to:
  /// **'Acceptable use'**
  String get termsUseTitle;

  /// No description provided for @termsUseBody.
  ///
  /// In en, this message translates to:
  /// **'Use the app only for lawful purposes. Do not use it to impersonate emergency services, harass or endanger anyone, distract drivers, or break road, aviation or public-order rules.'**
  String get termsUseBody;

  /// No description provided for @termsPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions and privacy'**
  String get termsPermissionsTitle;

  /// No description provided for @termsPermissionsBody.
  ///
  /// In en, this message translates to:
  /// **'The app uses the camera flash, screen brightness, optional haptics and, only when Shake to toggle is on, the motion sensor. It does not request camera, microphone, location, contacts or file access. See the Privacy policy in Settings for how data is handled.'**
  String get termsPermissionsBody;

  /// No description provided for @termsUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Availability and updates'**
  String get termsUpdatesTitle;

  /// No description provided for @termsUpdatesBody.
  ///
  /// In en, this message translates to:
  /// **'The core light modes work offline. Features may change, be removed or be unavailable on some devices, and updates may be required. We do not guarantee uninterrupted or error-free operation.'**
  String get termsUpdatesBody;

  /// No description provided for @termsIpTitle.
  ///
  /// In en, this message translates to:
  /// **'Intellectual property'**
  String get termsIpTitle;

  /// No description provided for @termsIpBody.
  ///
  /// In en, this message translates to:
  /// **'The app, its name, logo, design and code are owned by ClaudySoft or its licensors and are protected by law. These terms grant you a limited licence only.'**
  String get termsIpBody;

  /// No description provided for @termsThirdPartyTitle.
  ///
  /// In en, this message translates to:
  /// **'Third-party services'**
  String get termsThirdPartyTitle;

  /// No description provided for @termsThirdPartyBody.
  ///
  /// In en, this message translates to:
  /// **'The app uses services from Google AdMob, Google Play and, on iOS, the Apple App Store. Those services are governed by their own terms and privacy policies.'**
  String get termsThirdPartyBody;

  /// No description provided for @termsLiabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Disclaimers and liability'**
  String get termsLiabilityTitle;

  /// No description provided for @termsLiabilityBody.
  ///
  /// In en, this message translates to:
  /// **'The app is provided \"as is\" and \"as available\", to the maximum extent permitted by law. We are not liable for indirect or consequential loss, and our total liability is limited to the greater of the amount you paid for the app in the last twelve months or USD 5. Nothing here limits rights that the law does not allow to be excluded.'**
  String get termsLiabilityBody;

  /// No description provided for @termsIndemnityTitle.
  ///
  /// In en, this message translates to:
  /// **'Indemnity'**
  String get termsIndemnityTitle;

  /// No description provided for @termsIndemnityBody.
  ///
  /// In en, this message translates to:
  /// **'To the extent permitted by law, you agree to indemnify ClaudySoft against claims, losses and reasonable legal costs arising from your misuse of the app or your breach of these terms.'**
  String get termsIndemnityBody;

  /// No description provided for @termsLawTitle.
  ///
  /// In en, this message translates to:
  /// **'Governing law and consumer rights'**
  String get termsLawTitle;

  /// No description provided for @termsLawBody.
  ///
  /// In en, this message translates to:
  /// **'These terms are governed by the laws applicable where ClaudySoft is established, without limiting any mandatory consumer protection you have where you live. Disputes may be brought before a competent court or consumer authority under applicable law.'**
  String get termsLawBody;

  /// No description provided for @termsChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes and contact'**
  String get termsChangesTitle;

  /// No description provided for @termsChangesBody.
  ///
  /// In en, this message translates to:
  /// **'We may update these terms; the effective date above will change and continued use means you accept the new version. Questions? Contact us using the support email on the app\'s store listing.'**
  String get termsChangesBody;

  /// No description provided for @termsFooter.
  ///
  /// In en, this message translates to:
  /// **'By continuing to use Flash Light Pro, you accept these terms and the Privacy policy.'**
  String get termsFooter;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
