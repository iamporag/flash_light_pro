import 'package:flash_light_pro/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Formats an integer using the active locale's digits (for example Bengali).
String localizedNumber(BuildContext context, num value) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return NumberFormat.decimalPattern(locale).format(value);
}

String localizedPercent(BuildContext context, double ratio) {
  return '${localizedNumber(context, (ratio * 100).round())}%';
}

String localizedDecimal(
  BuildContext context,
  double value, {
  int decimals = 1,
}) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: decimals,
  ).format(value);
}

/// Countdown in `m:ss` form, with zero-padded seconds. Both parts use the
/// active locale's numeral system so Bengali never falls back to Latin digits.
String formatCountdown(BuildContext context, int totalSeconds) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  final minuteText = NumberFormat.decimalPattern(locale).format(minutes);
  final secondText = NumberFormat('00', locale).format(seconds);
  return '$minuteText:$secondText';
}
