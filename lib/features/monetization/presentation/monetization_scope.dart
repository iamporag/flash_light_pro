import 'package:flutter/widgets.dart';

import '../application/monetization_controller.dart';

/// Provides the monetization controller to any route below the host.
///
/// When the app is constructed without an `AdConfig` (all widget tests and any
/// embedding that does not want monetization), this scope is absent and every
/// ad or purchase widget renders nothing.
class MonetizationScope extends InheritedWidget {
  const MonetizationScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final MonetizationController controller;

  static MonetizationController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MonetizationScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(MonetizationScope oldWidget) =>
      controller != oldWidget.controller;
}
