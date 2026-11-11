/// Single entry point for immutable application configuration.
///
/// UI strings are deliberately absent: `lib/l10n/app_en.arb` and
/// `app_bn.arb` are the only translation sources, and generated
/// [AppLocalizations] accessors are the only way screens read text.
library;

export 'admob/admob_config.dart';
export 'admob/admob_ids.dart';
export 'admob/admob_policy.dart';
export 'app_info.dart';
export 'app_theme_config.dart';
export 'feature_config.dart';
export 'purchase_config.dart';
