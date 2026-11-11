import 'dart:async';

import 'package:flash_light_pro/features/battery/services/battery_optimization_service.dart';
import 'package:flash_light_pro/features/monetization/presentation/monetization_scope.dart';
import 'package:flash_light_pro/core/config/app_theme_config.dart';
import 'package:flash_light_pro/src/presentation/utils/localization.dart';
import 'package:flutter/material.dart';

/// Explains and exposes Android's battery optimization exemption without ever
/// changing the setting silently. Hidden on platforms without the service.
class BatteryOptimizationSection extends StatefulWidget {
  const BatteryOptimizationSection({
    super.key,
    this.service = const MethodChannelBatteryOptimizationService(),
  });

  final BatteryOptimizationService service;

  @override
  State<BatteryOptimizationSection> createState() =>
      _BatteryOptimizationSectionState();
}

class _BatteryOptimizationSectionState extends State<BatteryOptimizationSection>
    with WidgetsBindingObserver {
  BatteryOptimizationStatus? _status;
  bool _requesting = false;
  bool _denied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    final status = await widget.service.status();
    if (!mounted) return;
    setState(() {
      _status = status;
      if (status.ignoring) _denied = false;
    });
  }

  Future<void> _request() async {
    setState(() => _requesting = true);
    _markExternalSystemFlow();
    final opened = await widget.service.requestIgnore();
    if (!mounted) return;
    setState(() {
      _requesting = false;
      _denied = !opened;
    });
    if (opened) {
      // The user decides in the system dialog; refresh when they return.
      unawaited(_refresh());
    }
  }

  void _markExternalSystemFlow() {
    MonetizationScope.maybeOf(context)?.markExternalSystemFlow();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null || !status.supported) return const SizedBox.shrink();

    final l10n = context.l10n;
    final ignoring = status.ignoring;

    return Padding(
      key: const Key('settings-battery'),
      padding: const EdgeInsets.only(top: 14),
      child: Material(
        color: AppColors.surface.withValues(alpha: 0.78),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.batterySection,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    ignoring
                        ? Icons.battery_saver_rounded
                        : Icons.battery_alert_rounded,
                    size: 18,
                    color: ignoring ? AppColors.accent : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.batteryOptimizationTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      ignoring
                          ? l10n.batteryStatusUnrestricted
                          : l10n.batteryStatusOptimized,
                      key: const Key('settings-battery-status'),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.batteryOptimizationBody,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              if (_denied) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.batteryRequestDenied,
                  key: const Key('settings-battery-denied'),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (!ignoring)
                    FilledButton.tonal(
                      key: const Key('settings-battery-allow'),
                      onPressed: _requesting
                          ? null
                          : () => unawaited(_request()),
                      child: Text(l10n.batteryAllowButton),
                    ),
                  TextButton(
                    key: const Key('settings-battery-open'),
                    onPressed: () {
                      _markExternalSystemFlow();
                      unawaited(widget.service.openSettings());
                    },
                    child: Text(l10n.batteryOpenSettings),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
