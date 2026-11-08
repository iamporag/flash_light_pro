package com.claudysoft.flashlightpro

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val deviceControlsChannelName =
        "com.claudysoft.flashlightpro/device_controls"
    private val torchEventsChannelName =
        "com.claudysoft.flashlightpro/torch_state"
    private val backgroundTorchEventsChannelName =
        "com.claudysoft.flashlightpro/background_torch_state"
    private val shakeMonitorEventsChannelName =
        "com.claudysoft.flashlightpro/shake_monitor_state"
    private val nativeControlsEventsChannelName =
        "com.claudysoft.flashlightpro/native_controls_state"

    private var originalWindowBrightness: Float? = null
    private var notificationPermissionResult: MethodChannel.Result? = null

    private fun torch() = TorchManager.get(this)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, deviceControlsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isTorchAvailable" -> result.success(torch().snapshot().available)
                    "getTorchState" -> result.success(torch().snapshot().isOn)
                    "setTorchEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") == true
                        val outcome = torch().setEnabled(enabled)
                        result.success(
                            mapOf(
                                "success" to outcome.success,
                                "isOn" to outcome.snapshot.isOn,
                                "available" to outcome.snapshot.available,
                                "error" to outcome.error?.wireName(),
                            ),
                        )
                    }
                    "isTorchLevelSupported" -> result.success(
                        torch().snapshot().levelSupported,
                    )
                    "setTorchLevel" -> {
                        val level = (call.argument<Double>("level") ?: 1.0)
                            .toFloat()
                            .coerceIn(0.01f, 1f)
                        val controller = torch()
                        val applied =
                            controller.snapshot().levelSupported &&
                                controller.setLevel(level)
                        result.success(applied)
                    }
                    "isBackgroundModeSupported" -> result.success(
                        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O,
                    )
                    "startBackgroundMode" -> {
                        val outcome = TorchForegroundService.start(this)
                        result.success(
                            mapOf(
                                "started" to outcome.started,
                                "notificationsEnabled" to
                                    TorchForegroundStatus.notificationsEnabled(this),
                                "error" to outcome.error,
                            ),
                        )
                    }
                    "stopBackgroundMode" -> {
                        TorchForegroundService.stop(this)
                        result.success(null)
                    }
                    "setBackgroundModePreference" -> {
                        TorchPreferences.setBackgroundEnabled(
                            this,
                            call.argument<Boolean>("enabled") == true,
                        )
                        result.success(null)
                    }
                    "isBackgroundModeActive" -> result.success(
                        TorchForegroundStatus.state ==
                            TorchForegroundStatus.State.RUNNING,
                    )
                    "isShakeMonitoringSupported" -> result.success(
                        TorchForegroundService.isShakeSupported(this),
                    )
                    "startShakeMonitor" -> {
                        val outcome = ShakeMonitorCompat.start(this)
                        result.success(
                            mapOf(
                                "started" to outcome.started,
                                "notificationsEnabled" to
                                    TorchForegroundStatus.notificationsEnabled(this),
                                "error" to outcome.error,
                            ),
                        )
                    }
                    "stopShakeMonitor" -> {
                        ShakeMonitorCompat.stop(this)
                        result.success(null)
                    }
                    "isShakeMonitorActive" -> result.success(
                        ShakeMonitorStatus.state ==
                            ShakeMonitorStatus.State.RUNNING,
                    )
                    "setShakePreference" -> {
                        TorchPreferences.setShakeEnabled(
                            this,
                            call.argument<Boolean>("enabled") == true,
                        )
                        TorchPreferences.setShakeSensitivity(
                            this,
                            call.argument<Int>("sensitivity") ?: 1,
                        )
                        TorchPreferences.setShakeBlocked(
                            this,
                            call.argument<Boolean>("blocked") == true,
                        )
                        // The unified service owns the only sensor listener, so
                        // the preference applies without another service.
                        TorchForegroundService.syncShake(this)
                        result.success(null)
                    }
                    "setStrobeIntervalPreference" -> {
                        TorchPreferences.setStrobeInterval(
                            this,
                            call.argument<Int>("milliseconds") ?: 400,
                        )
                        TorchPatternPlayer.onStrobeIntervalChanged(this)
                        result.success(null)
                    }
                    "startTorchMode" -> {
                        val mode = call.argument<String>("mode").toTorchMode()
                        result.success(
                            if (mode == null) {
                                false
                            } else {
                                TorchForegroundService.setPattern(this, mode)
                            },
                        )
                    }
                    "stopTorchMode" -> {
                        TorchForegroundService.stopPattern(this)
                        result.success(null)
                    }
                    "pauseTorchMode" -> result.success(
                        TorchForegroundService.pausePattern(this),
                    )
                    "resumeTorchMode" -> result.success(
                        TorchForegroundService.resumePattern(this),
                    )
                    "getNativeControlState" -> result.success(
                        nativeControlSnapshot(this),
                    )
                    "getBatteryOptimizationStatus" -> result.success(
                        batteryOptimizationStatus(),
                    )
                    "requestIgnoreBatteryOptimizations" ->
                        requestIgnoreBatteryOptimizations(result)
                    "openBatteryOptimizationSettings" -> {
                        result.success(openBatteryOptimizationSettings())
                    }
                    "hasNotificationPermission" -> result.success(
                        TorchForegroundStatus.notificationsEnabled(this),
                    )
                    "requestNotificationPermission" ->
                        requestNotificationPermission(result)
                    "setScreenBrightness" -> {
                        val brightness = (call.argument<Double>("brightness") ?: 0.85)
                            .coerceIn(0.01, 1.0)
                        setScreenBrightness(brightness.toFloat())
                        result.success(null)
                    }
                    "restoreScreenBrightness" -> {
                        restoreScreenBrightness()
                        result.success(null)
                    }
                    "setKeepScreenOn" -> {
                        setKeepScreenOn(call.argument<Boolean>("enabled") == true)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, torchEventsChannelName)
            .setStreamHandler(TorchEventStreamHandler(this))
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            backgroundTorchEventsChannelName,
        ).setStreamHandler(BackgroundTorchEventStreamHandler())
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            shakeMonitorEventsChannelName,
        ).setStreamHandler(ShakeMonitorEventStreamHandler())
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            nativeControlsEventsChannelName,
        ).setStreamHandler(NativeControlsEventStreamHandler(this))
    }

    private class TorchEventStreamHandler(
        private val activity: MainActivity,
    ) : EventChannel.StreamHandler {
        private val mainHandler = Handler(Looper.getMainLooper())
        private var sink: EventChannel.EventSink? = null
        private val observer = TorchObserver { snapshot ->
            mainHandler.post {
                sink?.success(snapshot.isOn)
            }
        }

        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            if (sink != null) return

            sink = events
            val controller = TorchManager.get(activity)
            controller.addObserver(observer)
            events?.success(controller.snapshot().isOn)
        }

        override fun onCancel(arguments: Any?) {
            sink = null
            TorchManager.get(activity).removeObserver(observer)
        }
    }

    private class BackgroundTorchEventStreamHandler : EventChannel.StreamHandler {
        private val mainHandler = Handler(Looper.getMainLooper())
        private var sink: EventChannel.EventSink? = null
        private val listener = TorchForegroundStatus.Listener { state ->
            mainHandler.post {
                sink?.success(state.wireName)
            }
        }

        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            if (sink != null) return

            sink = events
            TorchForegroundStatus.addListener(listener)
            events?.success(TorchForegroundStatus.state.wireName)
        }

        override fun onCancel(arguments: Any?) {
            sink = null
            TorchForegroundStatus.removeListener(listener)
        }
    }

    private class ShakeMonitorEventStreamHandler : EventChannel.StreamHandler {
        private val mainHandler = Handler(Looper.getMainLooper())
        private var sink: EventChannel.EventSink? = null
        private val listener = ShakeMonitorStatus.Listener { state ->
            mainHandler.post {
                sink?.success(state.wireName)
            }
        }

        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            if (sink != null) return

            sink = events
            ShakeMonitorStatus.addListener(listener)
            events?.success(ShakeMonitorStatus.state.wireName)
        }

        override fun onCancel(arguments: Any?) {
            sink = null
            ShakeMonitorStatus.removeListener(listener)
        }
    }

    /**
     * One consolidated stream for the mode, pauses, and shake monitoring that
     * native components can change while the Flutter UI is not looking. The
     * hardware on/off value still comes from [TorchEventStreamHandler].
     */
    private class NativeControlsEventStreamHandler(
        private val activity: MainActivity,
    ) : EventChannel.StreamHandler {
        private val mainHandler = Handler(Looper.getMainLooper())
        private var sink: EventChannel.EventSink? = null

        private val modeListener = TorchModeState.Listener {
            emit()
        }
        private val shakeListener = ShakeMonitorStatus.Listener {
            emit()
        }
        private val torchListener = TorchObserver {
            emit()
        }

        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            if (sink != null) return

            sink = events
            TorchModeState.addListener(modeListener)
            ShakeMonitorStatus.addListener(shakeListener)
            TorchManager.get(activity).addObserver(torchListener)
            emit()
        }

        override fun onCancel(arguments: Any?) {
            sink = null
            TorchModeState.removeListener(modeListener)
            ShakeMonitorStatus.removeListener(shakeListener)
            TorchManager.get(activity).removeObserver(torchListener)
        }

        private fun emit() {
            mainHandler.post {
                sink?.success(nativeControlSnapshot(activity))
            }
        }
    }

    private fun batteryOptimizationStatus(): Map<String, Any> {
        val supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
        val ignoring = if (supported) {
            getSystemService(PowerManager::class.java)
                ?.isIgnoringBatteryOptimizations(packageName) == true
        } else {
            true
        }
        return mapOf(
            "supported" to supported,
            "ignoring" to ignoring,
        )
    }

    private fun requestIgnoreBatteryOptimizations(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.success(true)
            return
        }
        if (getSystemService(PowerManager::class.java)
                ?.isIgnoringBatteryOptimizations(packageName) == true
        ) {
            result.success(true)
            return
        }

        val request = Intent(
            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
            Uri.parse("package:$packageName"),
        )
        try {
            startActivity(request)
            result.success(true)
        } catch (_: ActivityNotFoundException) {
            // Some manufacturers remove the direct dialog. The list is the
            // documented fallback and still never changes settings silently.
            result.success(openBatteryOptimizationSettings())
        } catch (_: SecurityException) {
            result.success(openBatteryOptimizationSettings())
        }
    }

    private fun openBatteryOptimizationSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false

        return try {
            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            true
        } catch (_: ActivityNotFoundException) {
            try {
                startActivity(Intent(Settings.ACTION_SETTINGS))
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        val alreadyGranted =
            Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        if (alreadyGranted) {
            result.success(true)
            return
        }

        if (notificationPermissionResult != null) {
            // The system only allows one dialog at a time.
            result.success(false)
            return
        }

        notificationPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_NOTIFICATIONS,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_NOTIFICATIONS) return

        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        notificationPermissionResult?.success(granted)
        notificationPermissionResult = null
    }

    private fun setScreenBrightness(brightness: Float) {
        val attributes = window.attributes
        if (originalWindowBrightness == null) {
            originalWindowBrightness = attributes.screenBrightness
        }
        attributes.screenBrightness = brightness
        window.attributes = attributes
    }

    private fun restoreScreenBrightness() {
        val attributes = window.attributes
        attributes.screenBrightness =
            originalWindowBrightness ?: WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
        window.attributes = attributes
        originalWindowBrightness = null
    }

    private fun setKeepScreenOn(enabled: Boolean) {
        if (enabled) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    private companion object {
        const val REQUEST_NOTIFICATIONS = 4102
    }
}

private fun TorchError.wireName(): String = when (this) {
    TorchError.UNAVAILABLE -> "unavailable"
    TorchError.CAMERA_IN_USE -> "cameraInUse"
    TorchError.FAILED -> "failed"
}

private fun nativeControlSnapshot(context: Context): Map<String, Any> {
    val state = TorchModeState.snapshot(context)
    return mapOf(
        "mode" to state.mode.wireName,
        "paused" to state.paused,
        "torchOn" to state.torchOn,
        "available" to state.available,
        "shakeEnabled" to state.shakeEnabled,
        "shakeMonitoring" to state.shakeMonitoringActive,
        "backgroundServiceRunning" to
            (TorchForegroundStatus.state == TorchForegroundStatus.State.RUNNING),
        "notificationsEnabled" to
            TorchForegroundStatus.notificationsEnabled(context),
    )
}

private fun String?.toTorchMode(): TorchMode? = when (this) {
    "off" -> TorchMode.OFF
    "sos" -> TorchMode.SOS
    "strobe" -> TorchMode.STROBE
    else -> null
}
