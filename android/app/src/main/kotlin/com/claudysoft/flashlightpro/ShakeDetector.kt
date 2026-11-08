package com.claudysoft.flashlightpro

import kotlin.math.abs
import kotlin.math.sqrt

/**
 * Magnitude-based shake detection with a settle requirement and cooldown.
 * Matches the Dart detector so foreground fallback and background monitoring
 * react to the same gestures.
 */
class ShakeDetector(
    @Volatile var threshold: Double = MEDIUM_THRESHOLD,
    private val cooldownMs: Long = COOLDOWN_MS,
    private val rearmThreshold: Double = REARM_THRESHOLD,
) {
    private var lastShakeAt: Long = 0L
    private var armed = true

    /** Returns true at most once per [cooldownMs], and only after the phone
     *  settled since the previous shake. */
    fun addSample(x: Float, y: Float, z: Float, nowMs: Long): Boolean {
        val magnitude = sqrt(x * x + y * y + z * z).toDouble()
        val deviation = abs(magnitude - GRAVITY)

        if (deviation <= rearmThreshold) {
            armed = true
            return false
        }
        if (!armed || deviation < threshold) return false

        if (lastShakeAt != 0L && nowMs - lastShakeAt < cooldownMs) return false

        lastShakeAt = nowMs
        armed = false
        return true
    }

    fun reset() {
        lastShakeAt = 0L
        armed = true
    }

    companion object {
        private const val GRAVITY = 9.80665
        private const val COOLDOWN_MS = 1200L
        private const val REARM_THRESHOLD = 3.0

        const val LOW_THRESHOLD = 18.0
        const val MEDIUM_THRESHOLD = 13.0
        const val HIGH_THRESHOLD = 8.5

        /** Index order matches the Flutter ShakeSensitivity enum. */
        fun thresholdForSensitivity(index: Int): Double = when (index) {
            0 -> LOW_THRESHOLD
            2 -> HIGH_THRESHOLD
            else -> MEDIUM_THRESHOLD
        }
    }
}
