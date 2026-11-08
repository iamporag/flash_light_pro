package io.github.iamporag.flashlightpro

import android.content.Context
import java.util.concurrent.CopyOnWriteArraySet

/** Pattern modes owned natively so they survive the Flutter UI closing. */
enum class TorchMode(val wireName: String) {
    OFF("off"),
    SOS("sos"),
    STROBE("strobe"),
}

data class TorchModeSnapshot(
    val mode: TorchMode,
    val paused: Boolean,
    val torchOn: Boolean,
    val available: Boolean,
    val shakeEnabled: Boolean,
    val shakeMonitoringActive: Boolean,
)

/**
 * Process-wide pattern state. The foreground service, notification panel,
 * tile/widget, and Flutter channel all read this one source.
 */
object TorchModeState {
    fun interface Listener {
        fun onModeChanged(snapshot: TorchModeSnapshot)
    }

    @Volatile
    var mode: TorchMode = TorchMode.OFF
        private set

    @Volatile
    var paused: Boolean = false
        private set

    private val listeners = CopyOnWriteArraySet<Listener>()

    fun addListener(listener: Listener) {
        listeners.add(listener)
    }

    fun removeListener(listener: Listener) {
        listeners.remove(listener)
    }

    fun snapshot(context: Context): TorchModeSnapshot {
        val torch = TorchManager.get(context).snapshot()
        val patternActive = mode != TorchMode.OFF
        return TorchModeSnapshot(
            mode = mode,
            paused = paused,
            // During a pattern the light is intentionally blinking, so report
            // the active mode rather than one instant of the duty cycle.
            torchOn = patternActive || torch.isOn,
            available = torch.available,
            shakeEnabled = TorchPreferences.shakeEnabled(context),
            shakeMonitoringActive = ShakeMonitorStatus.state ==
                ShakeMonitorStatus.State.RUNNING,
        )
    }

    internal fun set(context: Context, newMode: TorchMode, isPaused: Boolean) {
        mode = newMode
        paused = isPaused
        val snapshot = snapshot(context)
        listeners.forEach { listener ->
            try {
                listener.onModeChanged(snapshot)
            } catch (_: Exception) {
                // A broken listener must never break pattern playback.
            }
        }
    }
}
