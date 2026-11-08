package io.github.iamporag.flashlightpro

import android.content.Context
import java.util.concurrent.CopyOnWriteArraySet

/**
 * Process-wide shake-detection state. "RUNNING" means the unified foreground
 * service currently holds an accelerometer listener. It is deliberately
 * separate from [TorchForegroundStatus], which describes the service process.
 */
object ShakeMonitorStatus {
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
                // A broken listener must never break monitoring.
            }
        }
    }

    fun notificationsEnabled(context: Context): Boolean =
        TorchForegroundStatus.notificationsEnabled(context)
}
