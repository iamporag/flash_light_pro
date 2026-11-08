package com.claudysoft.flashlightpro

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import java.util.concurrent.CopyOnWriteArraySet

/**
 * The single foreground service behind every background flashlight feature.
 *
 * It keeps the CameraManager torch session alive, owns the only accelerometer
 * listener, and executes native SOS/strobe patterns. Every hardware action
 * still goes through the shared [TorchManager] controller, so Flutter, the
 * notification panel, Quick Settings tile, and home screen widget can never
 * disagree about the state.
 */
class TorchForegroundService : Service(),
    TorchObserver,
    SensorEventListener,
    TorchModeState.Listener {
    private val mainHandler = Handler(Looper.getMainLooper())
    private lateinit var controller: TorchController
    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private val detector = ShakeDetector()
    private var listening = false
    private var foregroundStarted = false
    private var startFailed = false
    private var notificationError: String? = null

    override fun onCreate() {
        super.onCreate()
        controller = TorchManager.get(this)
        sensorManager = getSystemService(SensorManager::class.java)
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        try {
            createNotificationChannel()
            startInForeground()
            foregroundStarted = true
            controller.addObserver(this)
            TorchModeState.addListener(this)
            TorchForegroundStatus.update(TorchForegroundStatus.State.RUNNING)

            // The user's persisted choice restores a sensor listener after the
            // process is recreated. There is no boot receiver, so a force-stop
            // or reboot still requires an explicit start.
            syncSensor()

            // A rapid action can finish before the service is created. Never
            // keep an idle notification or process around.
            maybeStopIfIdle()
        } catch (failure: Exception) {
            // Android 12+ can refuse a background start, and Android 14+ can
            // refuse the declared type when its prerequisites are missing.
            // Never crash the app for a torch enhancement.
            startFailed = true
            TorchForegroundStatus.update(
                TorchForegroundStatus.State.FAILED,
                failure.javaClass.simpleName,
            )
            stopSelf()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SET_TORCH -> {
                // An explicit switch position always wins over a running mode.
                TorchPatternPlayer.stop(this)
                applyTorch(intent.getBooleanExtra(EXTRA_ENABLED, false))
            }
            ACTION_TOGGLE_TORCH -> {
                if (TorchPatternPlayer.isActive()) {
                    TorchPatternPlayer.stop(this)
                } else {
                    val result = controller.toggle()
                    notificationError = result.error?.let(::messageFor)
                }
            }
            ACTION_TOGGLE_SHAKE -> {
                TorchPreferences.setShakeEnabled(
                    this,
                    !TorchPreferences.shakeEnabled(this),
                )
                syncSensor()
            }
            ACTION_START_SOS -> startPattern(TorchMode.SOS)
            ACTION_START_STROBE -> startPattern(TorchMode.STROBE)
            ACTION_STOP_MODE -> TorchPatternPlayer.stop(this)
            ACTION_PAUSE_MODE -> TorchPatternPlayer.pause(this)
            ACTION_RESUME_MODE -> TorchPatternPlayer.resume(this)
            ACTION_SYNC_SHAKE -> syncSensor()
            ACTION_STOP_ALL -> {
                stopAll()
                return START_NOT_STICKY
            }
            else -> syncSensor()
        }

        refreshNotification()
        maybeStopIfIdle()

        // A restarted process must never switch the torch back on by itself.
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStateChanged(snapshot: TorchSnapshot) {
        mainHandler.post {
            if (!foregroundStarted) return@post

            // Pattern steps are intentionally rapid. Refreshing the panel on
            // every blink would be noisy and waste battery; mode changes and
            // pattern completion drive the visible state instead.
            if (TorchPatternPlayer.isActive()) return@post

            // Observers only fire after a successful hardware change, so any
            // earlier error is no longer current.
            notificationError = null
            refreshNotification()
            if (!snapshot.isOn) maybeStopIfIdle()
        }
    }

    override fun onModeChanged(snapshot: TorchModeSnapshot) {
        mainHandler.post {
            if (!foregroundStarted) return@post
            notificationError = null
            refreshNotification()
            // One refresh per mode change, never per blink.
            TorchWidgetProvider.updateAll(this)
            TorchTileService.requestRefresh(this)
            maybeStopIfIdle()
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type != Sensor.TYPE_ACCELEROMETER) return
        if (!TorchPreferences.shakeEnabled(this)) return
        if (TorchPatternPlayer.isActive()) return
        if (TorchPreferences.shakeBlocked(this)) return

        // A volatile in-memory read, so a sensitivity change applies without
        // re-registering the sensor on every settings edit.
        detector.threshold = ShakeDetector.thresholdForSensitivity(
            TorchPreferences.shakeSensitivity(this),
        )

        val values = event.values
        val detected = detector.addSample(
            values[0],
            values[1],
            values[2],
            SystemClock.elapsedRealtime(),
        )
        if (!detected) return

        val snapshot = controller.snapshot()
        if (!snapshot.available) return

        // The observer refreshes this notification, the tile, and the widget.
        controller.toggle()
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    override fun onDestroy() {
        mainHandler.removeCallbacksAndMessages(null)
        controller.removeObserver(this)
        TorchModeState.removeListener(this)
        unregisterSensor()

        if (TorchPatternPlayer.isActive()) {
            TorchPatternPlayer.stop(this)
        }

        if (foregroundStarted) {
            // If the system destroys the service while the torch is still on,
            // the safest outcome is an explicit hardware release.
            if (controller.snapshot().isOn) controller.setEnabled(false)

            @Suppress("DEPRECATION")
            stopForeground(true)
            foregroundStarted = false
        }

        if (!startFailed) {
            TorchForegroundStatus.update(TorchForegroundStatus.State.STOPPED)
        }
        super.onDestroy()
    }

    private fun applyTorch(enabled: Boolean) {
        val result = controller.setEnabled(enabled)
        notificationError = result.error?.let(::messageFor)
    }

    private fun startPattern(mode: TorchMode) {
        if (!TorchPatternPlayer.start(this, mode)) {
            notificationError = getString(R.string.torch_unavailable)
        }
    }

    private fun stopAll() {
        TorchPatternPlayer.stop(this)
        TorchPreferences.setShakeEnabled(this, false)
        unregisterSensor()
        controller.setEnabled(false)
        notificationError = null
        stopSelf()
    }

    private fun maybeStopIfIdle() {
        if (!foregroundStarted) return
        if (TorchPatternPlayer.isActive()) return
        if (controller.snapshot().isOn) return
        if (TorchPreferences.shakeEnabled(this)) return
        stopSelf()
    }

    private fun syncSensor() {
        if (TorchPreferences.shakeEnabled(this)) {
            registerSensor()
        } else {
            unregisterSensor()
        }
    }

    private fun registerSensor() {
        if (listening) return
        val sensor = accelerometer
        if (sensor == null) {
            ShakeMonitorStatus.update(
                ShakeMonitorStatus.State.FAILED,
                "sensor_unavailable",
            )
            return
        }

        listening = sensorManager.registerListener(
            this,
            sensor,
            SensorManager.SENSOR_DELAY_UI,
        )
        if (!listening) {
            ShakeMonitorStatus.update(
                ShakeMonitorStatus.State.FAILED,
                "sensor_unavailable",
            )
            return
        }

        detector.reset()
        ShakeMonitorStatus.update(ShakeMonitorStatus.State.RUNNING)
        refreshNotification()
    }

    private fun unregisterSensor() {
        if (listening) {
            sensorManager.unregisterListener(this)
            listening = false
            detector.reset()
        }
        ShakeMonitorStatus.update(ShakeMonitorStatus.State.STOPPED)
    }

    private fun startInForeground() {
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Torch access through setTorchMode needs no CAMERA runtime
            // permission, so the camera FGS type is neither accurate nor
            // permitted. specialUse is the supported type for this use case.
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun refreshNotification() {
        if (!foregroundStarted) return
        try {
            getSystemService(NotificationManager::class.java)
                .notify(NOTIFICATION_ID, buildNotification())
        } catch (_: Exception) {
            // Notification permission can be revoked; the service keeps running.
        }
    }

    private fun buildNotification(): Notification {
        val openApp = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val openPendingIntent = PendingIntent.getActivity(
            this,
            REQUEST_OPEN,
            openApp,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val snapshot = controller.snapshot()
        val mode = TorchModeState.mode
        val patternActive = mode != TorchMode.OFF
        val flashlightOn = patternActive || snapshot.isOn
        val shakeEnabled = TorchPreferences.shakeEnabled(this)

        fun serviceIntent(requestCode: Int, action: String): PendingIntent {
            return PendingIntent.getService(
                this,
                requestCode,
                Intent(this, TorchForegroundService::class.java).setAction(action),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        val flashlightIntent = PendingIntent.getService(
            this,
            REQUEST_FLASHLIGHT,
            Intent(this, TorchForegroundService::class.java)
                .setAction(ACTION_SET_TORCH)
                .putExtra(EXTRA_ENABLED, !flashlightOn),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return FlashlightNotification.build(
            context = this,
            channelId = CHANNEL_ID,
            snapshot = snapshot,
            mode = mode,
            paused = TorchModeState.paused,
            shakeEnabled = shakeEnabled,
            shakeMonitoring = listening,
            flashlightOn = flashlightOn,
            openIntent = openPendingIntent,
            flashlightIntent = flashlightIntent,
            shakeIntent = serviceIntent(REQUEST_SHAKE, ACTION_TOGGLE_SHAKE),
            sosIntent = serviceIntent(
                REQUEST_SOS,
                if (mode == TorchMode.SOS) ACTION_STOP_MODE else ACTION_START_SOS,
            ),
            strobeIntent = serviceIntent(
                REQUEST_STROBE,
                if (mode == TorchMode.STROBE) ACTION_STOP_MODE
                else ACTION_START_STROBE,
            ),
            stopIntent = serviceIntent(REQUEST_STOP, ACTION_STOP_ALL),
            error = notificationError,
        )
    }

    private fun messageFor(error: TorchError): String = when (error) {
        TorchError.CAMERA_IN_USE -> getString(R.string.torch_camera_in_use)
        TorchError.UNAVAILABLE -> getString(R.string.torch_unavailable)
        TorchError.FAILED -> getString(R.string.torch_toggle_failed)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.notification_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = getString(R.string.notification_channel_description)
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }

    data class StartResult(val started: Boolean, val error: String?)

    companion object {
        private const val CHANNEL_ID = "flashlight_background"
        const val NOTIFICATION_ID = 4101
        private const val REQUEST_OPEN = 1
        private const val REQUEST_FLASHLIGHT = 2
        private const val REQUEST_SHAKE = 3
        private const val REQUEST_SOS = 4
        private const val REQUEST_STROBE = 5
        private const val REQUEST_STOP = 6

        private const val EXTRA_ENABLED = "enabled"

        const val ACTION_START =
            "com.claudysoft.flashlightpro.action.START_TORCH_SERVICE"
        const val ACTION_STOP =
            "com.claudysoft.flashlightpro.action.STOP_TORCH_SERVICE"
        const val ACTION_TOGGLE_TORCH =
            "com.claudysoft.flashlightpro.action.TOGGLE_TORCH"
        const val ACTION_SET_TORCH =
            "com.claudysoft.flashlightpro.action.SET_TORCH"
        const val ACTION_TOGGLE_SHAKE =
            "com.claudysoft.flashlightpro.action.TOGGLE_SHAKE"
        const val ACTION_START_SOS =
            "com.claudysoft.flashlightpro.action.START_SOS"
        const val ACTION_START_STROBE =
            "com.claudysoft.flashlightpro.action.START_STROBE"
        const val ACTION_STOP_MODE =
            "com.claudysoft.flashlightpro.action.STOP_MODE"
        const val ACTION_PAUSE_MODE =
            "com.claudysoft.flashlightpro.action.PAUSE_MODE"
        const val ACTION_RESUME_MODE =
            "com.claudysoft.flashlightpro.action.RESUME_MODE"
        const val ACTION_SYNC_SHAKE =
            "com.claudysoft.flashlightpro.action.SYNC_SHAKE"
        const val ACTION_STOP_ALL =
            "com.claudysoft.flashlightpro.action.STOP_ALL"

        fun start(context: Context): StartResult {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                return StartResult(false, "unsupported")
            }
            if (TorchForegroundStatus.state == TorchForegroundStatus.State.RUNNING) {
                return StartResult(true, null)
            }

            val appContext = context.applicationContext
            val intent = Intent(appContext, TorchForegroundService::class.java)
                .setAction(ACTION_START)

            return try {
                // Allowed while an Activity is visible or when the user acts on
                // a related UI element (Quick Settings tile, widget, or
                // notification action). No while-in-use permission is involved
                // because the service uses the specialUse type.
                appContext.startForegroundService(intent)
                StartResult(true, null)
            } catch (failure: Exception) {
                TorchForegroundStatus.update(
                    TorchForegroundStatus.State.FAILED,
                    failure.javaClass.simpleName,
                )
                StartResult(false, "failed")
            }
        }

        fun stop(context: Context) {
            try {
                context.applicationContext.stopService(
                    Intent(context, TorchForegroundService::class.java),
                )
            } catch (_: Exception) {
                // The service may already be gone.
            }
        }

        /** Applies a preference change to the already-running service. */
        fun syncShake(context: Context) {
            val appContext = context.applicationContext
            if (TorchPreferences.shakeEnabled(appContext)) {
                start(appContext)
                return
            }
            if (TorchForegroundStatus.state !=
                TorchForegroundStatus.State.RUNNING
            ) {
                return
            }
            try {
                appContext.startService(
                    Intent(appContext, TorchForegroundService::class.java)
                        .setAction(ACTION_SYNC_SHAKE),
                )
            } catch (_: Exception) {
                // If Android refuses, stopping is still better than leaving a
                // listener registered against the user's choice.
                stop(appContext)
            }
        }

        /** Unregisters the sensor and stops the service only when idle. */
        fun stopShake(context: Context) {
            val appContext = context.applicationContext
            TorchPreferences.setShakeEnabled(appContext, false)
            if (TorchForegroundStatus.state !=
                TorchForegroundStatus.State.RUNNING
            ) {
                ShakeMonitorStatus.update(ShakeMonitorStatus.State.STOPPED)
                return
            }
            try {
                appContext.startService(
                    Intent(appContext, TorchForegroundService::class.java)
                        .setAction(ACTION_SYNC_SHAKE),
                )
            } catch (_: Exception) {
                stop(appContext)
            }
        }

        /** Starts a native pattern on the unified service. */
        fun setPattern(context: Context, mode: TorchMode): Boolean {
            val appContext = context.applicationContext
            if (mode != TorchMode.OFF && !start(appContext).started) {
                return false
            }
            if (!TorchPatternPlayer.start(appContext, mode)) return false
            if (TorchForegroundStatus.state == TorchForegroundStatus.State.RUNNING) {
                try {
                    appContext.startService(
                        Intent(appContext, TorchForegroundService::class.java)
                            .setAction(
                                if (mode == TorchMode.SOS) ACTION_START_SOS
                                else ACTION_START_STROBE,
                            ),
                    )
                } catch (_: Exception) {
                    // The player already owns playback; refresh is best effort.
                }
            }
            return true
        }

        fun stopPattern(context: Context) {
            val appContext = context.applicationContext
            if (!TorchPatternPlayer.stop(appContext)) return
            if (TorchForegroundStatus.state ==
                TorchForegroundStatus.State.RUNNING
            ) {
                try {
                    appContext.startService(
                        Intent(appContext, TorchForegroundService::class.java)
                            .setAction(ACTION_STOP_MODE),
                    )
                } catch (_: Exception) {
                    // onModeChanged already refreshed the notification.
                }
            }
        }

        fun pausePattern(context: Context): Boolean {
            val appContext = context.applicationContext
            val paused = TorchPatternPlayer.pause(appContext)
            if (paused && TorchForegroundStatus.state ==
                TorchForegroundStatus.State.RUNNING
            ) {
                try {
                    appContext.startService(
                        Intent(appContext, TorchForegroundService::class.java)
                            .setAction(ACTION_PAUSE_MODE),
                    )
                } catch (_: Exception) {
                    // State listeners already refreshed the panel.
                }
            }
            return paused
        }

        fun resumePattern(context: Context): Boolean {
            val appContext = context.applicationContext
            val resumed = TorchPatternPlayer.resume(appContext)
            if (resumed && TorchForegroundStatus.state ==
                TorchForegroundStatus.State.RUNNING
            ) {
                try {
                    appContext.startService(
                        Intent(appContext, TorchForegroundService::class.java)
                            .setAction(ACTION_RESUME_MODE),
                    )
                } catch (_: Exception) {
                    // State listeners already refreshed the panel.
                }
            }
            return resumed
        }

        fun isShakeSupported(context: Context): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false

            val manager =
                context.getSystemService(SensorManager::class.java) ?: return false
            return manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) != null
        }
    }
}

/** Process-wide background service state, consumed by the Flutter channel. */
object TorchForegroundStatus {
    enum class State(val wireName: String) {
        STOPPED("stopped"),
        RUNNING("running"),
        FAILED("failed"),
    }

    fun interface Listener {
        fun onStateChanged(state: State)
    }

    @Volatile
    var state: State = State.STOPPED
        private set

    @Volatile
    var lastError: String? = null
        private set

    private val listeners = CopyOnWriteArraySet<Listener>()

    fun addListener(listener: Listener) {
        listeners.add(listener)
    }

    fun removeListener(listener: Listener) {
        listeners.remove(listener)
    }

    internal fun update(newState: State, error: String? = null) {
        state = newState
        lastError = error
        listeners.forEach { listener ->
            try {
                listener.onStateChanged(newState)
            } catch (_: Exception) {
                // A broken listener must never break the service.
            }
        }
    }

    fun notificationsEnabled(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true

        return context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    }
}
