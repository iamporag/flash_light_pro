package io.github.iamporag.flashlightpro

import android.content.Context

/**
 * Native copy of settings that native components need while no Flutter engine
 * is alive: the background-mode choice and the shake-monitoring state. Flutter
 * mirrors them here whenever it loads or changes them.
 */
object TorchPreferences {
    private const val FILE = "flashlight_native"
    private const val KEY_BACKGROUND_ENABLED = "background_enabled"
    private const val KEY_SHAKE_ENABLED = "shake_enabled"
    private const val KEY_SHAKE_SENSITIVITY = "shake_sensitivity"
    private const val KEY_SHAKE_BLOCKED = "shake_blocked"
    private const val KEY_STROBE_INTERVAL = "strobe_interval"

    private const val DEFAULT_SHAKE_SENSITIVITY = 1
    private const val DEFAULT_STROBE_INTERVAL = 400
    private const val MIN_STROBE_INTERVAL = 200
    private const val MAX_STROBE_INTERVAL = 1000

    @Volatile
    private var cached: Boolean? = null
    @Volatile
    private var cachedShakeEnabled: Boolean? = null
    @Volatile
    private var cachedShakeSensitivity: Int? = null
    @Volatile
    private var cachedShakeBlocked: Boolean? = null
    @Volatile
    private var cachedStrobeInterval: Int? = null

    private fun preferences(context: Context) =
        context.applicationContext.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    fun backgroundEnabled(context: Context): Boolean {
        cached?.let { return it }

        val value = preferences(context).getBoolean(KEY_BACKGROUND_ENABLED, true)
        cached = value
        return value
    }

    fun setBackgroundEnabled(context: Context, enabled: Boolean) {
        cached = enabled
        preferences(context).edit().putBoolean(KEY_BACKGROUND_ENABLED, enabled).apply()
    }

    fun shakeEnabled(context: Context): Boolean {
        cachedShakeEnabled?.let { return it }

        val value = preferences(context).getBoolean(KEY_SHAKE_ENABLED, false)
        cachedShakeEnabled = value
        return value
    }

    fun setShakeEnabled(context: Context, enabled: Boolean) {
        cachedShakeEnabled = enabled
        preferences(context).edit().putBoolean(KEY_SHAKE_ENABLED, enabled).apply()
    }

    fun shakeSensitivity(context: Context): Int {
        cachedShakeSensitivity?.let { return it }

        val value = preferences(context)
            .getInt(KEY_SHAKE_SENSITIVITY, DEFAULT_SHAKE_SENSITIVITY)
        cachedShakeSensitivity = value
        return value
    }

    fun setShakeSensitivity(context: Context, index: Int) {
        val clamped = index.coerceIn(0, 2)
        cachedShakeSensitivity = clamped
        preferences(context).edit().putInt(KEY_SHAKE_SENSITIVITY, clamped).apply()
    }

    /** True while the Dart layer owns the torch (SOS, strobe, Morse, screen
     *  light); shake toggles must not interrupt those modes. */
    fun shakeBlocked(context: Context): Boolean {
        cachedShakeBlocked?.let { return it }

        val value = preferences(context).getBoolean(KEY_SHAKE_BLOCKED, false)
        cachedShakeBlocked = value
        return value
    }

    fun setShakeBlocked(context: Context, blocked: Boolean) {
        cachedShakeBlocked = blocked
        preferences(context).edit().putBoolean(KEY_SHAKE_BLOCKED, blocked).apply()
    }

    /** Mirrored from Flutter so a strobe started in the notification panel
     *  matches the speed chosen in the app. */
    fun strobeInterval(context: Context): Int {
        cachedStrobeInterval?.let { return it }

        val value = preferences(context)
            .getInt(KEY_STROBE_INTERVAL, DEFAULT_STROBE_INTERVAL)
            .coerceIn(MIN_STROBE_INTERVAL, MAX_STROBE_INTERVAL)
        cachedStrobeInterval = value
        return value
    }

    fun setStrobeInterval(context: Context, milliseconds: Int) {
        val clamped = milliseconds.coerceIn(MIN_STROBE_INTERVAL, MAX_STROBE_INTERVAL)
        cachedStrobeInterval = clamped
        preferences(context).edit().putInt(KEY_STROBE_INTERVAL, clamped).apply()
    }
}
