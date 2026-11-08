package com.claudysoft.flashlightpro

import android.content.Context

/**
 * Compatibility facade for earlier call sites.
 *
 * Background shake monitoring now lives inside [TorchForegroundService], which
 * owns the only accelerometer listener and the single ongoing notification.
 * These delegates keep old Flutter method names working without introducing a
 * second foreground service.
 */
internal object ShakeMonitorCompat {
    fun isSupported(context: Context): Boolean =
        TorchForegroundService.isShakeSupported(context)

    fun start(context: Context): TorchForegroundService.StartResult {
        if (!isSupported(context)) {
            return TorchForegroundService.StartResult(false, "unsupported")
        }
        return TorchForegroundService.start(context)
    }

    fun stop(context: Context) = TorchForegroundService.stopShake(context)
}
