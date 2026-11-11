// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'ফ্ল্যাশ লাইট প্রো';

  @override
  String get appTagline => 'প্রিমিয়াম লাইটিং টুলকিট';

  @override
  String get offlineFooter =>
      'ফ্ল্যাশলাইট অফলাইনে কাজ করে। বিজ্ঞাপন ও ক্রয়ের জন্য ইন্টারনেট প্রয়োজন।';

  @override
  String get screenFallbackFooter =>
      'স্ক্রিন ফ্ল্যাশ ব্যাকআপ সক্রিয় — ডিসপ্লেই আলোর উৎস।';

  @override
  String get modeTorch => 'টর্চ';

  @override
  String get modeScreen => 'স্ক্রিন';

  @override
  String get modeSos => 'SOS';

  @override
  String get modeStrobe => 'স্ট্রোব';

  @override
  String get modeMorse => 'মোর্স';

  @override
  String get modeFlashlight => 'ফ্ল্যাশলাইট';

  @override
  String get modeScreenLight => 'স্ক্রিন লাইট';

  @override
  String get modeSosSignal => 'SOS সংকেত';

  @override
  String get modeMorsePlayback => 'মোর্স প্লেব্যাক';

  @override
  String get statusTorchOn => 'ফ্ল্যাশলাইট চালু';

  @override
  String get statusScreenOn => 'স্ক্রিন লাইট চালু';

  @override
  String get statusSosActive => 'SOS সংকেত সক্রিয়';

  @override
  String get statusStrobeOn => 'স্ট্রোব চালু';

  @override
  String get statusMorsePaused => 'মোর্স বিরত';

  @override
  String get statusSendingMorse => 'মোর্স পাঠানো হচ্ছে';

  @override
  String get statusChecking => 'ফ্ল্যাশলাইট পরীক্ষা করা হচ্ছে...';

  @override
  String get statusTorchOff => 'ফ্ল্যাশলাইট বন্ধ';

  @override
  String get statusTorchUnavailable => 'ফ্ল্যাশলাইট পাওয়া যাচ্ছে না';

  @override
  String get statusScreenOff => 'স্ক্রিন লাইট বন্ধ';

  @override
  String get statusSosReady => 'SOS প্রস্তুত';

  @override
  String get statusSosNeedsTorch => 'SOS-এর জন্য ফ্ল্যাশলাইট দরকার';

  @override
  String get statusStrobeReady => 'স্ট্রোব প্রস্তুত';

  @override
  String get statusStrobeNeedsTorch => 'স্ট্রোবের জন্য ফ্ল্যাশলাইট দরকার';

  @override
  String get statusMorseReady => 'মোর্স প্রস্তুত';

  @override
  String subtitleAutoOff(String countdown) {
    return '$countdown-এ স্বয়ংক্রিয় বন্ধ। সময় বদলাতে বা বাতিল করতে টাইমারে ট্যাপ করুন।';
  }

  @override
  String get subtitleMorsePaused =>
      'প্লেব্যাক বিরত আছে। নিচে থেকে আবার চালু বা বন্ধ করুন।';

  @override
  String get subtitleTapStop => 'বন্ধ করতে পাওয়ার বোতামে ট্যাপ করুন।';

  @override
  String get subtitleCheckingHardware =>
      'এই ডিভাইসের হার্ডওয়্যার পরীক্ষা করা হচ্ছে।';

  @override
  String get subtitleTorchReady => 'ফ্ল্যাশলাইট চালু বা বন্ধ করতে ট্যাপ করুন।';

  @override
  String get subtitleTorchUnavailable =>
      'স্ক্রিন লাইট ব্যবহার করুন — এতে টর্চ হার্ডওয়্যার লাগে না।';

  @override
  String get subtitleScreenReady => 'ফুল-স্ক্রিন আলো খুলতে ট্যাপ করুন।';

  @override
  String get subtitleSosReady => 'প্রমিত ... --- ... বিপদ সংকেত।';

  @override
  String get subtitleStrobeReady =>
      'নিরাপত্তা সতর্কতা সহ সামঞ্জস্যযোগ্য ফ্ল্যাশ গতি।';

  @override
  String get subtitleMorseReady =>
      'আপনার বার্তা আলো হিসেবে পাঠাতে Play ট্যাপ করুন।';

  @override
  String get hintStop => 'আলো বন্ধ করতে ডাবল ট্যাপ করুন';

  @override
  String get hintTorchOn => 'ফ্ল্যাশলাইট চালু করতে ডাবল ট্যাপ করুন';

  @override
  String get hintScreen => 'স্ক্রিন লাইট খুলতে ডাবল ট্যাপ করুন';

  @override
  String get hintSos => 'SOS সংকেত শুরু করতে ডাবল ট্যাপ করুন';

  @override
  String get hintStrobe => 'স্ট্রোব শুরু করতে ডাবল ট্যাপ করুন';

  @override
  String get hintMorse => 'মোর্স বার্তা চালাতে ডাবল ট্যাপ করুন';

  @override
  String announcementOn(String mode) {
    return '$mode চালু';
  }

  @override
  String announcementOff(String mode) {
    return '$mode বন্ধ';
  }

  @override
  String timerCountdown(String countdown) {
    return '$countdown-এ স্বয়ংক্রিয় বন্ধ';
  }

  @override
  String get timerOff => 'স্বয়ংক্রিয় বন্ধ: নিষ্ক্রিয়';

  @override
  String timerPreset(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'স্বয়ংক্রিয় বন্ধ $minutesString মিনিট';
  }

  @override
  String get timerSheetTitle => 'স্বয়ংক্রিয় বন্ধের টাইমার';

  @override
  String get timerSheetSubtitle => 'সক্রিয় আলো স্বয়ংক্রিয়ভাবে বন্ধ করে।';

  @override
  String timerTurningOff(String countdown) {
    return '$countdown-এ বন্ধ হবে';
  }

  @override
  String timerPresetChip(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString মিনিট';
  }

  @override
  String get timerCustomLabel => 'কাস্টম মিনিট';

  @override
  String get timerSet => 'সেট';

  @override
  String get timerCancel => 'টাইমার বাতিল';

  @override
  String get timerClose => 'বন্ধ করুন';

  @override
  String timerCustomError(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return '১ থেকে $maxString-এর মধ্যে একটি পূর্ণসংখ্যা লিখুন।';
  }

  @override
  String get timerButton => 'স্বয়ংক্রিয় বন্ধের টাইমার';

  @override
  String get flashlight => 'ফ্ল্যাশলাইট';

  @override
  String get rearCameraTorch => 'পেছনের ক্যামেরার টর্চ';

  @override
  String get noUsableTorch => 'ব্যবহারযোগ্য টর্চ পাওয়া যায়নি';

  @override
  String get torchStrength => 'টর্চের শক্তি';

  @override
  String get torchStrengthUnsupported => 'এই ডিভাইসে টর্চের শক্তি সমর্থিত নয়।';

  @override
  String get screenLightWorksWithoutTorch =>
      'টর্চ হার্ডওয়্যার ছাড়াও স্ক্রিন লাইট কাজ করে।';

  @override
  String get screenLight => 'স্ক্রিন লাইট';

  @override
  String get screenPanelSubtitle => 'সামঞ্জস্যযোগ্য রঙের ফুল-স্ক্রিন আলো';

  @override
  String get color => 'রং';

  @override
  String get brightness => 'উজ্জ্বলতা';

  @override
  String get brightnessRestored =>
      'বের হলে আপনার আগের স্ক্রিন উজ্জ্বলতা ফিরে আসবে।';

  @override
  String get sosSignal => 'SOS সংকেত';

  @override
  String get sosSubtitle => 'প্রমিত আন্তর্জাতিক বিপদ সংকেত';

  @override
  String get sosTransmitting =>
      'একটানা পাঠানো হচ্ছে। উদ্ধারকারী এলে বন্ধ করুন।';

  @override
  String get sosPlaysOnTorch => 'আপনি থামানো পর্যন্ত ফ্ল্যাশলাইটে চলবে।';

  @override
  String get sosNeedsTorch =>
      'এই ডিভাইসে SOS-এর জন্য কাজ করা ফ্ল্যাশলাইট দরকার।';

  @override
  String get strobe => 'স্ট্রোব';

  @override
  String get strobeSubtitle => 'সামঞ্জস্যযোগ্য ফ্ল্যাশ গতি';

  @override
  String get flashSpeed => 'ফ্ল্যাশের গতি';

  @override
  String speedHz(String value) {
    return '$value Hz';
  }

  @override
  String get photosensitivityWarning =>
      'ফটোসেনসিটিভিটি সতর্কতা: জ্বলজ্বলে আলো খিঁচুনি ঘটাতে পারে। অসুস্থ লাগলে সঙ্গে সঙ্গে থামুন এবং আলো চোখ থেকে দূরে রাখুন।';

  @override
  String get morseTitle => 'মোর্স কোড';

  @override
  String get morseSubtitle => 'A-Z ও 0-9 আলো সংকেত হিসেবে পাঠান';

  @override
  String get message => 'বার্তা';

  @override
  String get morseHint => 'SOS HELLO 123';

  @override
  String get clearMessage => 'বার্তা মুছুন';

  @override
  String get morsePreviewPlaceholder => 'আপনার মোর্স প্রিভিউ এখানে দেখা যাবে।';

  @override
  String morseUnsupported(String characters) {
    return 'অসমর্থিত: $characters — A-Z ও 0-9 ব্যবহার করুন।';
  }

  @override
  String get morsePlaysOnTorch => 'ফ্ল্যাশলাইটে চলে।';

  @override
  String get morseScreenFallback =>
      'ফ্ল্যাশলাইট পাওয়া যায়নি — এর বদলে স্ক্রিন জ্বলবে।';

  @override
  String get pause => 'বিরতি';

  @override
  String get resume => 'চালু করুন';

  @override
  String get stop => 'থামুন';

  @override
  String get playMorse => 'মোর্স চালান';

  @override
  String get typeMessage => 'মোর্স কোডে পাঠাতে একটি বার্তা লিখুন।';

  @override
  String unsupportedCharacters(String characters) {
    return 'অসমর্থিত অক্ষর: $characters। A-Z ও 0-9 ব্যবহার করুন।';
  }

  @override
  String get strobeNeedsTorchMessage =>
      'এই ডিভাইসে স্ট্রোবের জন্য কাজ করা ফ্ল্যাশলাইট দরকার।';

  @override
  String get lightingError => 'আলোর ত্রুটি';

  @override
  String get dismiss => 'বাতিল';

  @override
  String get retry => 'আবার চেষ্টা';

  @override
  String get errorUnavailable => 'এই ডিভাইসে ফ্ল্যাশলাইট পাওয়া যাচ্ছে না।';

  @override
  String get errorCameraInUse =>
      'অন্য অ্যাপ ক্যামেরা ব্যবহার করছে। এটি বন্ধ করে আবার চেষ্টা করুন।';

  @override
  String get errorEnable => 'ফ্ল্যাশলাইট চালু করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get errorDisable => 'ফ্ল্যাশলাইট বন্ধ করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get errorCheck => 'ফ্ল্যাশলাইট পরীক্ষা করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get errorPlatform =>
      'এই প্ল্যাটফর্মে ফ্ল্যাশলাইট নিয়ন্ত্রণ সমর্থিত নয়।';

  @override
  String get errorUnexpected => 'আলো নিয়ন্ত্রণ করার সময় কিছু সমস্যা হয়েছে।';

  @override
  String get exitScreenLight => 'স্ক্রিন লাইট থেকে বের হন';

  @override
  String get hideCustomColor => 'কাস্টম রং লুকান';

  @override
  String get customColor => 'কাস্টম রং';

  @override
  String get screenColorWarm => 'উষ্ণ';

  @override
  String get screenColorNeutral => 'নিরপেক্ষ';

  @override
  String get screenColorCool => 'শীতল';

  @override
  String screenColorSemantics(String color) {
    return '$color স্ক্রিন রঙ';
  }

  @override
  String get turnOffLight => 'আলো বন্ধ করুন';

  @override
  String get hue => 'হিউ';

  @override
  String get saturation => 'স্যাচুরেশন';

  @override
  String get openSettings => 'সেটিংস খুলুন';

  @override
  String get settings => 'সেটিংস';

  @override
  String get settingsSubtitle => 'ভাষা, ফিডব্যাক ও আচরণ';

  @override
  String get language => 'ভাষা';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageBengali => 'বাংলা';

  @override
  String get appearanceSection => 'চেহারা';

  @override
  String get motionSection => 'মোশন';

  @override
  String get haptics => 'হ্যাপটিক ফিডব্যাক';

  @override
  String get hapticsSubtitle => 'পাওয়ার নিয়ন্ত্রণ ব্যবহার করলে কম্পন হবে।';

  @override
  String get shakeToToggle => 'ঝাঁকিয়ে চালু/বন্ধ';

  @override
  String get shakeSubtitleOn =>
      'অ্যাপ ব্যাকগ্রাউন্ডে থাকলেও ফোন ঝাঁকিয়ে ফ্ল্যাশলাইট চালু বা বন্ধ করুন।';

  @override
  String get shakeSubtitleOff =>
      'বন্ধ। ব্যাকগ্রাউন্ডেও ঝাঁকিয়ে ফ্ল্যাশলাইট চালু বা বন্ধ করতে এটি চালু করুন।';

  @override
  String get shakeSensitivity => 'ঝাঁকুনির সংবেদনশীলতা';

  @override
  String get sensitivityLow => 'কম';

  @override
  String get sensitivityMedium => 'মাঝারি';

  @override
  String get sensitivityHigh => 'বেশি';

  @override
  String get shakeMonitoringActive =>
      'ব্যাকগ্রাউন্ড মনিটরিং চালু আছে। অ্যাপ ছেড়ে গেলেও ঝাঁকুনি কাজ করবে বলে একটি স্থায়ী নোটিফিকেশন দেখানো হয়।';

  @override
  String get shakeMonitoringInactive =>
      'ব্যাকগ্রাউন্ড মনিটরিং চলছে না। ঝাঁকুনি শুধু অ্যাপ খোলা থাকলে কাজ করবে।';

  @override
  String get shakeNotificationsOff =>
      'নোটিফিকেশন বন্ধ, তাই প্রয়োজনীয় মনিটরিং নোটিফিকেশন দেখা যাচ্ছে না। মনিটরিং চালু থাকবে এবং Android-এর সক্রিয় অ্যাপ তালিকায় দেখা যাবে।';

  @override
  String get shakeBackgroundUnsupported =>
      'এই ডিভাইসে ব্যাকগ্রাউন্ড ঝাঁকুনি মনিটরিং উপলব্ধ নয়। ঝাঁকুনি শুধু অ্যাপ খোলা থাকলে কাজ করবে।';

  @override
  String get keepScreenAwake => 'স্ক্রিন জাগিয়ে রাখুন';

  @override
  String get keepScreenAwakeSubtitle => 'আলো সক্রিয় থাকলে স্ক্রিন ঘুমাবে না।';

  @override
  String get backgroundSection => 'ব্যাকগ্রাউন্ড';

  @override
  String get keepFlashlightOnBackground =>
      'ব্যাকগ্রাউন্ডে ফ্ল্যাশলাইট চালু রাখুন';

  @override
  String get keepFlashlightOnBackgroundSubtitle =>
      'অ্যাপ থেকে বেরিয়ে গেলেও ফ্ল্যাশলাইট চালু থাকবে। Android একটি নোটিফিকেশন দেখায় যেখান থেকে আপনি এটি বন্ধ করতে পারবেন। ফোন, ব্যাটারি বা সিস্টেমের সীমাবদ্ধতায় এটি বন্ধ হতে পারে।';

  @override
  String get keepFlashlightOnBackgroundUnsupported =>
      'iOS-এ উপলব্ধ নয়। অ্যাপ সাসপেন্ড হলে সিস্টেম ফ্ল্যাশলাইট বন্ধ করে দেয়।';

  @override
  String get backgroundNotificationsOff =>
      'নোটিফিকেশন বন্ধ আছে। ফ্ল্যাশলাইট চালু থাকবে, তবে বন্ধ করার বোতাম শুধু অ্যাপে পাওয়া যাবে।';

  @override
  String get reduceAnimations => 'অ্যানিমেশন কমান';

  @override
  String get reduceAnimationsSubtitle =>
      'ছোট ট্রানজিশন ও শান্ত গতি ব্যবহার করুন।';

  @override
  String get defaultMode => 'ডিফল্ট মোড';

  @override
  String get defaultModeSubtitle => 'অ্যাপ খুললে যে মোড নির্বাচিত থাকবে।';

  @override
  String get aboutSection => 'অ্যাপ সম্পর্কে';

  @override
  String get appInfo => 'অ্যাপের তথ্য';

  @override
  String versionLabel(String version) {
    return 'সংস্করণ $version';
  }

  @override
  String get privacyPolicy => 'গোপনীয়তা নীতি';

  @override
  String get openSourceLicenses => 'ওপেন-সোর্স লাইসেন্স';

  @override
  String get permissionsTitle => 'অনুমতি ও ডিভাইস নোট';

  @override
  String get permissionsBody =>
      'অ্যাপটি ক্যামেরার টর্চ, স্ক্রিনের উজ্জ্বলতা, হ্যাপটিকস এবং — শুধু ঝাঁকিয়ে চালু/বন্ধ সক্রিয় থাকলে — মোশন সেন্সর ব্যবহার করে। Android-এ ব্যাকগ্রাউন্ড ঝাঁকুনি মনিটরিং একটি স্থায়ী নোটিফিকেশনসহ ফোরগ্রাউন্ড সার্ভিসে চলে। অ্যাপটি ইন্টারনেট, লোকেশন, ক্যামেরার ছবি, মাইক্রোফোন বা পরিচিতি চায় না।';

  @override
  String get volumeButtonsTitle => 'ভলিউম বোতাম';

  @override
  String get volumeButtonsBody =>
      'Android ও iOS ভলিউম বোতাম সিস্টেম অডিও ও অ্যাক্সেসিবিলিটির জন্য রাখে। Flash Light Pro এগুলো ধর না, কারণ তার জন্য অ্যাক্সেসিবিলিটি বা রুট অ্যাক্সেস লাগত, যা এই অ্যাপ চায় না।';

  @override
  String get iosLimitationsTitle => 'iOS ইন্টিগ্রেশন';

  @override
  String get iosLimitationsBody =>
      'iOS-এ ঝাঁকিয়ে চালু/বন্ধ এবং Shortcuts অ্যাকশন অ্যাপ বা সিস্টেম ইনটেন্ট চলাকালে কাজ করে। iOS-এ সীমাহীন ব্যাকগ্রাউন্ড ফ্ল্যাশলাইট নিয়ন্ত্রণের জন্য Android-ধাঁচের Quick Settings টাইল বা হোম স্ক্রিন উইজেট নেই। iOS অ্যাপের এক্সিকিউশন সাসপেন্ড করে এবং অ্যাপ ফোরগ্রাউন্ড ছাড়লে টর্চ ছেড়ে দেয়, তাই iOS-এ ব্যাকগ্রাউন্ড ফ্ল্যাশলাইট মোড নেই।';

  @override
  String get madeOffline =>
      'ফ্ল্যাশলাইট অফলাইনে কাজ করে। বিজ্ঞাপনের জন্য ইন্টারনেট প্রয়োজন।';

  @override
  String get privacyPolicyTitle => 'গোপনীয়তা নীতি';

  @override
  String get privacyIntro =>
      'Flash Light Pro আপনার ডিভাইসে কাজ করে। ফ্ল্যাশলাইটের জন্য কোনো অ্যাকাউন্ট বা নেটওয়ার্ক লাগে না। বিনামূল্যের সংস্করণে Google AdMob-এর বিজ্ঞাপন দেখা যায় এবং একবারের ঐচ্ছিক ক্রয়ে সেগুলো সরানো যায়।';

  @override
  String get privacyViewOnline => 'সম্পূর্ণ নীতি অনলাইনে দেখুন';

  @override
  String get privacyLocalTitle => 'আপনার ডিভাইসে সংরক্ষিত তথ্য';

  @override
  String get privacyLocalBody =>
      'ভাষা, ডিফল্ট মোড, উজ্জ্বলতা ও ঝাঁকুনির সংবেদনশীলতার মতো পছন্দ অপারেটিং সিস্টেম আপনার ডিভাইসে সংরক্ষণ করে। বিজ্ঞাপনের ফ্রিকোয়েন্সি সীমা, বিজ্ঞাপন সম্মতি ও Remove ads ক্রয়ের অবস্থাও স্থানীয়ভাবে সংরক্ষিত হয়। Android Quick Settings টাইল ও হোম স্ক্রিন উইজেটও সঠিক অবস্থা দেখাতে সর্বশেষ টর্চ অবস্থা স্থানীয়ভাবে সংরক্ষণ করে।';

  @override
  String get privacyHardwareTitle => 'হার্ডওয়্যার অ্যাক্সেস';

  @override
  String get privacyHardwareBody =>
      'অ্যাপটি ক্যামেরার ফ্ল্যাশ (টর্চ) ও স্ক্রিনের উজ্জ্বলতা ব্যবহার করে। ঝাঁকিয়ে চালু/বন্ধ সক্রিয় থাকলে এটি অ্যাক্সিলেরোমিটার পড়ে: অ্যাপ খোলা থাকলে সরাসরি, আর Android-এ অ্যাপ ছেড়ে গেলে একটি স্থায়ী নোটিফিকেশনসহ ফোরগ্রাউন্ড সার্ভিসের মাধ্যমে। এটি ক্যামেরার ছবি, মাইক্রোফোনের অডিও, লোকেশন, পরিচিতি বা ফটো সংগ্রহ করে না।';

  @override
  String get privacyAdsTitle => 'বিজ্ঞাপন';

  @override
  String get privacyAdsBody =>
      'বিনামূল্যের সংস্করণে Google AdMob-এর ব্যানার, নেটিভ, ইন্টারস্টিশিয়াল ও অ্যাপ-ওপেন বিজ্ঞাপন দেখা যেতে পারে। আপনার অঞ্চলে প্রয়োজনীয় সম্মতি নেওয়ার পরেই বিজ্ঞাপন অনুরোধ করা হয়, এবং লাইট চালু থাকা বা আপডেট আবশ্যক হলে কখনোই নয়। সেটিংসের গোপনীয়তা বিকল্প থেকে পছন্দ পর্যালোচনা করা যায়। Remove ads ক্রয় এই অ্যাকাউন্টে সব বিজ্ঞাপন বন্ধ করে।';

  @override
  String get privacyBillingTitle => 'Remove ads ক্রয়';

  @override
  String get privacyBillingBody =>
      'Remove ads হলো Google Play বা App Store-এ সম্পন্ন একবারের অ-খরচযোগ্য ক্রয়। অ্যাপ আপনার পেমেন্ট তথ্য পায় না। ক্রয়ের অধিকার ডিভাইসে ক্যাশ করা হয় ও স্টোরের সাথে যাচাই করা হয়, এবং সেটিংস থেকে যেকোনো সময় পুনরুদ্ধার করা যায়।';

  @override
  String get privacyNoAnalyticsTitle =>
      'কোনো অ্যানালিটিক্স বা ক্র্যাশ আপলোড নেই';

  @override
  String get privacyNoAnalyticsBody =>
      'অ্যাপে কোনো অ্যানালিটিক্স SDK বা রিমোট ক্র্যাশ রিপোর্টিং নেই। Google AdMob তাদের নিজস্ব গোপনীয়তা শর্ত অনুযায়ী ডিভাইস ও বিজ্ঞাপন-মিথস্ক্রিয়া তথ্য সংগ্রহ করতে পারে। ইন্টারনেট ছাড়াই ফ্ল্যাশলাইট, SOS, স্ট্রোব, মোর্স ও স্ক্রিন লাইট কাজ করে।';

  @override
  String privacyPolicyFooter(String version) {
    return 'এই নীতি Flash Light Pro সংস্করণ $version-এর জন্য প্রযোজ্য। iOS-এ অ্যাপ মোশন অ্যাক্সেস চায়, এবং তা কেবল ঝাঁকিয়ে চালু/বন্ধ সক্রিয় থাকলে। Android 13 ও পরের সংস্করণে এটি নোটিফিকেশন অনুমতি চায়, যাতে ব্যাকগ্রাউন্ড ফ্ল্যাশলাইট ও ঝাঁকুনি সার্ভিস তাদের নিয়ন্ত্রণ দেখাতে পারে। বিজ্ঞাপন ও ক্রয় Google AdMob ও প্ল্যাটফর্ম স্টোর তাদের নিজস্ব গোপনীয়তা শর্তে প্রদান করে।';
  }

  @override
  String get close => 'বন্ধ করুন';

  @override
  String get updateRequiredTitle => 'আপডেট প্রয়োজন';

  @override
  String get updateRequiredBody =>
      'নিরাপদে অ্যাপটি চালু রাখতে Flash Light Pro-এর একটি নতুন সংস্করণ প্রয়োজন। চালিয়ে যেতে অনুগ্রহ করে আপডেট করুন।';

  @override
  String get updateRecommendedTitle => 'আপডেট সুপারিশ করা হচ্ছে';

  @override
  String get updateRecommendedBody =>
      'সেরা অভিজ্ঞতার জন্য এই আপডেটটি সুপারিশ করা হচ্ছে। এখনই আপডেট করতে পারেন অথবা বর্তমান সংস্করণ ব্যবহার চালিয়ে যেতে পারেন।';

  @override
  String get updateAvailableTitle => 'নতুন আপডেট পাওয়া গেছে';

  @override
  String get updateAvailableBody =>
      'উন্নতি ও সংশোধনসহ Flash Light Pro-এর একটি নতুন সংস্করণ পাওয়া গেছে।';

  @override
  String updateInstalledVersion(String version) {
    return 'ইনস্টল করা: $version';
  }

  @override
  String updateAvailableBuild(int build) {
    return 'পাওয়া যাচ্ছে: বিল্ড $build';
  }

  @override
  String get updateVersionUnknown => 'Google Play-এ সর্বশেষ সংস্করণ';

  @override
  String get updateNow => 'এখনই আপডেট করুন';

  @override
  String get updateLater => 'পরে';

  @override
  String get updateOpenStore => 'Play Store খুলুন';

  @override
  String get updateTryAgain => 'আবার চেষ্টা করুন';

  @override
  String get updateDownloadingTitle => 'আপডেট ডাউনলোড হচ্ছে...';

  @override
  String get updateDownloadingBody =>
      'আপডেট ডাউনলোড হওয়ার সময় আপনি ফ্ল্যাশলাইট ব্যবহার চালিয়ে যেতে পারেন।';

  @override
  String get updateReadyTitle => 'আপডেট প্রস্তুত';

  @override
  String get updateReadyBody =>
      'আপডেটটি ডাউনলোড হয়েছে। সম্পন্ন করতে এখনই ইনস্টল করুন।';

  @override
  String get updateInstallNow => 'আপডেট ইনস্টল করুন';

  @override
  String get updateInstallingTitle => 'আপডেট ইনস্টল হচ্ছে...';

  @override
  String get updateInstallingBody =>
      'Google Play আপডেটটি ইনস্টল করছে। অ্যাপটি পুনরায় চালু হতে পারে।';

  @override
  String get updateInstalledBody =>
      'আপডেটটি ইনস্টল হয়েছে। অ্যাপটি স্বয়ংক্রিয়ভাবে না খুললে এটি পুনরায় চালু করুন।';

  @override
  String get updateErrorTitle => 'আপডেট শুরু করা যায়নি';

  @override
  String get updateErrorBody =>
      'Google Play আপডেট শুরু করতে পারেনি। সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।';

  @override
  String get updateStoreError => 'স্টোর খোলা যায়নি। পরে আবার চেষ্টা করুন।';

  @override
  String get updateCanceled => 'আপডেটটি বাতিল করা হয়েছে।';

  @override
  String get updateReadySnack => 'আপডেট ইনস্টল করার জন্য প্রস্তুত।';

  @override
  String get updateHide => 'লুকান';

  @override
  String get updateContinueAnyway => 'আপডেট ছাড়া চালিয়ে যান';

  @override
  String get updateCachedNotice =>
      'এই আপডেটটি আগে যাচাই করা হয়েছিল। নিশ্চিত করতে আবার সংযোগ করুন।';

  @override
  String get settingsUpdates => 'অ্যাপ আপডেট';

  @override
  String get settingsUpdateCheck => 'আপডেট খুঁজুন';

  @override
  String get settingsUpdateChecking => 'আপডেট পরীক্ষা করা হচ্ছে...';

  @override
  String get settingsUpToDate => 'আপনি সর্বশেষ সংস্করণ ব্যবহার করছেন';

  @override
  String settingsUpdateAvailable(int build) {
    return 'আপডেট পাওয়া গেছে (বিল্ড $build)';
  }

  @override
  String get settingsUpdateDownloading => 'আপডেট ডাউনলোড হচ্ছে...';

  @override
  String get settingsUpdateReady => 'আপডেট ইনস্টল করার জন্য প্রস্তুত';

  @override
  String get settingsUpdateInstalling => 'আপডেট ইনস্টল হচ্ছে...';

  @override
  String get settingsUpdateInstalled => 'আপডেট ইনস্টল হয়েছে';

  @override
  String get settingsUpdateInstall => 'ইনস্টল';

  @override
  String get settingsUpdateAction => 'আপডেট';

  @override
  String get settingsUpdateCheckAction => 'পরীক্ষা করুন';

  @override
  String get settingsUpdateFailed => 'আপডেট পরীক্ষা করা যায়নি';

  @override
  String get settingsUpdateStoreManaged =>
      'আপনার অ্যাপ স্টোর আপডেট পরিচালনা করে';

  @override
  String get removeAdsTitle => 'বিজ্ঞাপন সরান';

  @override
  String get removeAdsBody =>
      'একবারের ক্রয়। ব্যানার, ইন্টারস্টিশিয়াল ও অ্যাপ-ওপেন বিজ্ঞাপন সরিয়ে দেয়। ফ্ল্যাশলাইট সবসময় বিনামূল্যে থাকবে।';

  @override
  String removeAdsPrice(String price) {
    return 'বিজ্ঞাপন সরান · $price';
  }

  @override
  String get removeAdsOwned =>
      'এই ক্রয়ের জন্য বিজ্ঞাপন সরানো হয়েছে। ধন্যবাদ!';

  @override
  String get removeAdsLoading => 'স্টোরের মূল্য লোড হচ্ছে...';

  @override
  String get removeAdsPurchasing => 'স্টোরের নিশ্চিতকরণের অপেক্ষা...';

  @override
  String get removeAdsPending => 'স্টোর এখনও এই ক্রয় নিশ্চিত করছে।';

  @override
  String get removeAdsRestoring => 'আগের ক্রয় যাচাই করা হচ্ছে...';

  @override
  String get removeAdsUnavailable =>
      'এই মুহূর্তে স্টোর পাওয়া যাচ্ছে না। ফ্ল্যাশলাইটের সব ফিচার আগের মতোই কাজ করবে।';

  @override
  String get removeAdsPurchaseFailed =>
      'ক্রয়টি সম্পন্ন হয়নি। কোনো টাকা কাটা হয়নি।';

  @override
  String get removeAdsPurchaseCanceled =>
      'পেমেন্ট বাতিল হয়েছে। আপনার কোনো টাকা কাটা হয়নি। আপনি আবার চেষ্টা করতে পারেন।';

  @override
  String get removeAdsRestoreFailed =>
      'আগের ক্রয় যাচাই করা যায়নি। পরে আবার চেষ্টা করুন।';

  @override
  String get removeAdsNoPurchase =>
      'এই অ্যাকাউন্টে আগের কোনো ক্রয় পাওয়া যায়নি।';

  @override
  String get removeAdsProductNotFound =>
      'স্টোরে এখনও বিজ্ঞাপন সরান পণ্যটি তালিকাভুক্ত হয়নি।';

  @override
  String get removeAdsRestore => 'ক্রয় পুনরুদ্ধার করুন';

  @override
  String get removeAdsRetry => 'আবার চেষ্টা করুন';

  @override
  String get adLabel => 'বিজ্ঞাপন';

  @override
  String get privacyOptions => 'গোপনীয়তা বিকল্প';

  @override
  String get privacyOptionsBody => 'বিজ্ঞাপন সম্মতি পছন্দগুলো পর্যালোচনা করুন।';

  @override
  String get batterySection => 'ব্যাকগ্রাউন্ড নির্ভরযোগ্যতা';

  @override
  String get batteryOptimizationTitle => 'ব্যাটারি অপ্টিমাইজেশন';

  @override
  String get batteryStatusOptimized => 'Android অপ্টিমাইজ করেছে';

  @override
  String get batteryStatusUnrestricted => 'সীমাহীন';

  @override
  String get batteryOptimizationBody =>
      'ব্যাটারি বাঁচাতে Android ব্যাকগ্রাউন্ড অ্যাপ থামাতে পারে, ফলে স্ক্রিন লক হলে ফ্ল্যাশলাইট বা ঝাঁকুনি নিয়ন্ত্রণ বন্ধ হতে পারে। Flash Light Pro কে ছাড় দিলে সহায়ক হয়, তবে Doze, জোরপূর্বক বন্ধ, এবং ডিভাইস নির্মাতার সীমাবদ্ধতা এখনও ব্যাকগ্রাউন্ড কাজ বন্ধ করতে পারে।';

  @override
  String get batteryAllowButton => 'ব্যাকগ্রাউন্ডে চালানোর অনুমতি দিন';

  @override
  String get batteryOpenSettings => 'ব্যাটারি সেটিংস';

  @override
  String get batteryRequestDenied =>
      'ব্যাটারি অপ্টিমাইজেশন পরিবর্তন হয়নি। সিস্টেম সেটিংসে আপনি অনুমতি দিতে পারেন।';

  @override
  String get batteryChecking => 'ব্যাটারির অবস্থা দেখা হচ্ছে...';

  @override
  String get premiumBadgeUpgrade => 'বিশেষ আপগ্রেড';

  @override
  String get premiumTitle => 'বিজ্ঞাপনমুক্ত হোন';

  @override
  String get premiumDescription =>
      'বাধাহীনভাবে Flash Light Pro ব্যবহার করুন। একবার পেমেন্ট, আজীবন অ্যাক্সেস।';

  @override
  String get premiumBenefitsTitle => 'সবকিছু অন্তর্ভুক্ত';

  @override
  String get premiumBenefitNoBanners => 'ব্যানার বিজ্ঞাপন নেই';

  @override
  String get premiumBenefitNoNative => 'নেটিভ বিজ্ঞাপন নেই';

  @override
  String get premiumBenefitNoInterstitials => 'ইন্টারস্টিশিয়াল বিজ্ঞাপন নেই';

  @override
  String get premiumBenefitNoAppOpen => 'অ্যাপ ওপেন বিজ্ঞাপন নেই';

  @override
  String get premiumBenefitUninterrupted => 'বাধাহীন ফ্ল্যাশলাইট অভিজ্ঞতা';

  @override
  String get premiumBenefitLifetime => 'একবার পেমেন্টে আজীবন অ্যাক্সেস';

  @override
  String get premiumOneTimePayment => 'একবারের পেমেন্ট';

  @override
  String get premiumLifetimeAccess => 'আজীবন অ্যাক্সেস';

  @override
  String get premiumCta => 'চিরতরে বিজ্ঞাপন সরান';

  @override
  String get premiumOneTimeNote => 'একবারের ক্রয়। কোনো পুনরাবৃত্তি চার্জ নেই।';

  @override
  String get premiumOwnedBadge => 'আজীবন আনলকড';

  @override
  String get premiumOwnedTitle => 'আপনি বিজ্ঞাপনমুক্ত!';

  @override
  String get premiumOwnedDescription =>
      'Flash Light Pro সমর্থন করার জন্য ধন্যবাদ। আপনার আজীবন বিজ্ঞাপনমুক্ত অভিজ্ঞতা উপভোগ করুন।';

  @override
  String get premiumStorePriceLabel => 'স্টোরের মূল্য';

  @override
  String get termsAndConditions => 'শর্তাবলি ও নিয়মাবলি';

  @override
  String get termsEffectiveDate => 'কার্যকর: ৮ নভেম্বর ২০২৬';

  @override
  String get termsIntro =>
      'এই শর্তাবলি Flash Light Pro ব্যবহারের নিয়ন্ত্রণ করে। অ্যাপটি ইনস্টল বা ব্যবহার করলে আপনি এগুলো মেনে নিচ্ছেন। সম্মত না হলে অনুগ্রহ করে অ্যাপটি আনইনস্টল করুন।';

  @override
  String get termsViewOnline => 'সম্পূর্ণ শর্তাবলি অনলাইনে দেখুন';

  @override
  String get termsLicenceTitle => 'অ্যাপ ব্যবহারের লাইসেন্স';

  @override
  String get termsLicenceBody =>
      'ClaudySoft আপনাকে আপনার মালিকানাধীন বা নিয়ন্ত্রণাধীন ডিভাইসে Flash Light Pro ব্যবহারের জন্য ব্যক্তিগত, অ-একচেটিয়া, হস্তান্তরযোগ্য নয় এমন ও প্রত্যাহারযোগ্য লাইসেন্স দেয়। আইন স্পষ্টভাবে অনুমতি দিলে ছাড়া অ্যাপটি কপি, পুনঃবিক্রয়, পুনঃবিতরণ, পরিবর্তন, রিভার্স ইঞ্জিনিয়ার বা সোর্স কোড উদ্ধারের চেষ্টা করা যাবে না।';

  @override
  String get termsAdsTitle => 'বিজ্ঞাপন ও Remove ads';

  @override
  String get termsAdsBody =>
      'বিনামূল্যের সংস্করণ Google AdMob বিজ্ঞাপন দ্বারা পরিচালিত, যা আপনার অঞ্চলে প্রয়োজনীয় সম্মতির পরেই দেখানো হয়। একবারের ঐচ্ছিক অ-খরচযোগ্য ক্রয়ে সব বিজ্ঞাপন সরানো যায়। পেমেন্ট ও রিফান্ড Google Play বা App Store পরিচালনা করে; অ্যাপ আপনার পেমেন্ট তথ্য পায় না। সেটিংস থেকে ক্রয় পুনরুদ্ধার করা যায়।';

  @override
  String get termsSafetyTitle => 'নিরাপত্তা';

  @override
  String get termsSafetyBody =>
      'Flash Light Pro একটি সুবিধার অ্যাপ, নিরাপত্তা বা জরুরি সরঞ্জাম নয়। SOS, স্ট্রোব ও মোর্স শুধু আলো তৈরি করে; তারা জরুরি সেবায় কল করে না বা আপনার লোকেশন পাঠায় না। স্ট্রোব ফটোসেনসিটিভ ব্যক্তিদের খিঁচুনি সৃষ্টি করতে পারে। গাড়ি চালানোর সময় বা মনোযোগ সরানো বিপজ্জনক এমন পরিস্থিতিতে আলো ব্যবহার করবেন না, এবং চোখে, গাড়ি বা উড়োজাহাজে আলো ফেলবেন না। দীর্ঘ ব্যবহারে ব্যাটারি শেষ ও ডিভাইস গরম হতে পারে, আর ব্যাকগ্রাউন্ড পরিচালনা অপারেটিং সিস্টেম দ্বারা নিশ্চিত নয়।';

  @override
  String get termsUseTitle => 'গ্রহণযোগ্য ব্যবহার';

  @override
  String get termsUseBody =>
      'অ্যাপটি শুধু আইনসিদ্ধ কাজে ব্যবহার করুন। জরুরি সেবার পরিচয় ব্যবহার, কাউকে হয়রানি বা বিপদে ফেলা, চালকের মনোযোগ সরানো, বা সড়ক, বিমান চলাচল কিংবা জনশৃঙ্খলার নিয়ম ভাঙতে এটি ব্যবহার করবেন না।';

  @override
  String get termsPermissionsTitle => 'অনুমতি ও গোপনীয়তা';

  @override
  String get termsPermissionsBody =>
      'অ্যাপটি ক্যামেরার ফ্ল্যাশ, স্ক্রিনের উজ্জ্বলতা, ঐচ্ছিক হ্যাপটিকস এবং শুধু ঝাঁকিয়ে চালু/বন্ধ সক্রিয় থাকলে মোশন সেন্সর ব্যবহার করে। এটি ক্যামেরা, মাইক্রোফোন, লোকেশন, পরিচিতি বা ফাইল অ্যাক্সেস চায় না। তথ্য কীভাবে পরিচালিত হয় তা সেটিংসের গোপনীয়তা নীতিতে দেখুন।';

  @override
  String get termsUpdatesTitle => 'প্রাপ্যতা ও আপডেট';

  @override
  String get termsUpdatesBody =>
      'মূল আলোর মোডগুলো ইন্টারনেট ছাড়াই কাজ করে। ফিচার পরিবর্তন, অপসারণ বা কিছু ডিভাইসে অনুপলব্ধ হতে পারে এবং আপডেট প্রয়োজন হতে পারে। নিরবচ্ছিন্ন বা ত্রুটিমুক্ত পরিচালনার নিশ্চয়তা আমরা দিই না।';

  @override
  String get termsIpTitle => 'মেধাস্বত্ব';

  @override
  String get termsIpBody =>
      'অ্যাপ, এর নাম, লোগো, ডিজাইন ও কোড ClaudySoft বা এর লাইসেন্সদাতাদের মালিকানাধীন এবং আইন দ্বারা সুরক্ষিত। এই শর্তাবলি আপনাকে শুধু সীমিত লাইসেন্স দেয়।';

  @override
  String get termsThirdPartyTitle => 'তৃতীয় পক্ষের সেবা';

  @override
  String get termsThirdPartyBody =>
      'অ্যাপটি Google AdMob, Google Play এবং iOS-এ Apple App Store-এর সেবা ব্যবহার করে। ওই সেবাগুলো তাদের নিজস্ব শর্ত ও গোপনীয়তা নীতি দ্বারা পরিচালিত।';

  @override
  String get termsLiabilityTitle => 'দায়বদ্ধতার সীমা';

  @override
  String get termsLiabilityBody =>
      'আইন যতটা অনুমতি দেয়, অ্যাপটি ‘যেমন আছে’ ও ‘যেমন পাওয়া যায়’ ভিত্তিতে প্রদান করা হয়। পরোক্ষ বা আনুষঙ্গিক ক্ষতির জন্য আমরা দায়ী নই, এবং আমাদের মোট দায় গত বারো মাসে অ্যাপের জন্য আপনার দেওয়া অর্থ বা ৫ মার্কিন ডলারের মধ্যে বেশি যেটি হয় তার মধ্যে সীমাবদ্ধ। আইনে যেসব অধিকার বাদ দেওয়া যায় না, এই শর্ত তা সীমিত করে না।';

  @override
  String get termsIndemnityTitle => 'ক্ষতিপূরণ';

  @override
  String get termsIndemnityBody =>
      'আইন যতটা অনুমতি দেয়, অ্যাপের অপব্যবহার বা এই শর্তাবলি ভাঙার ফলে উদ্ভূত দাবি, ক্ষতি ও যুক্তিসঙ্গত আইনি খরচের জন্য আপনি ClaudySoft-কে ক্ষতিপূরণ দিতে সম্মত হচ্ছেন।';

  @override
  String get termsLawTitle => 'প্রযোজ্য আইন ও ভোক্তা অধিকার';

  @override
  String get termsLawBody =>
      'এই শর্তাবলি ClaudySoft যেখানে প্রতিষ্ঠিত সেখানের প্রযোজ্য আইন দ্বারা পরিচালিত, তবে আপনার বসবাসের স্থানের বাধ্যতামূলক ভোক্তা সুরক্ষা অধিকার সীমিত করে না। প্রযোজ্য আইন অনুযায়ী সংশ্লিষ্ট আদালত বা ভোক্তা কর্তৃপক্ষের কাছে বিরোধ নেওয়া যেতে পারে।';

  @override
  String get termsChangesTitle => 'পরিবর্তন ও যোগাযোগ';

  @override
  String get termsChangesBody =>
      'আমরা সময়ে সময়ে এই শর্তাবলি আপডেট করতে পারি; উপরের কার্যকর তারিখ বদলাবে এবং ব্যবহার চালিয়ে গেলে আপনি নতুন সংস্করণ মেনে নিচ্ছেন। প্রশ্ন থাকলে অ্যাপের স্টোর লিস্টিংয়ে দেওয়া সাপোর্ট ইমেইলে যোগাযোগ করুন।';

  @override
  String get termsFooter =>
      'Flash Light Pro ব্যবহার চালিয়ে গেলে আপনি এই শর্তাবলি ও গোপনীয়তা নীতি মেনে নিচ্ছেন।';
}
