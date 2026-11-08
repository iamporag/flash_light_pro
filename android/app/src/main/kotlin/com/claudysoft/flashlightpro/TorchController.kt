package com.claudysoft.flashlightpro

/**
 * Platform-independent torch state machine. Android hardware access, storage,
 * and side effects are injected so the toggle behaviour can be unit tested.
 */
enum class TorchError {
    UNAVAILABLE,
    CAMERA_IN_USE,
    FAILED,
}

data class TorchSnapshot(
    val available: Boolean,
    val isOn: Boolean,
    val levelSupported: Boolean,
)

data class TorchResult(
    val snapshot: TorchSnapshot,
    val error: TorchError? = null,
) {
    val success: Boolean get() = error == null
}

class TorchHardwareException(val error: TorchError) : Exception()

interface TorchHardware {
    val available: Boolean
    val levelSupported: Boolean

    fun setEnabled(enabled: Boolean, level: Float)

    fun setLevel(level: Float)
}

interface TorchStateStore {
    var isOn: Boolean
    var level: Float
}

fun interface TorchObserver {
    fun onStateChanged(snapshot: TorchSnapshot)
}

class TorchController(
    private val hardware: TorchHardware,
    private val store: TorchStateStore,
    restorePersistedState: Boolean = true,
) {
    private val lock = Any()
    private val observers = mutableSetOf<TorchObserver>()
    private var isOn = if (restorePersistedState) store.isOn else false

    init {
        // A new process cannot inherit a torch session: the camera service
        // releases the torch when its controlling process dies. Never report a
        // stale "on" state until the hardware callback confirms it.
        if (!restorePersistedState && store.isOn) store.isOn = false
    }

    fun snapshot(): TorchSnapshot = synchronized(lock) { snapshotLocked() }

    fun addObserver(observer: TorchObserver) {
        synchronized(lock) { observers.add(observer) }
    }

    fun removeObserver(observer: TorchObserver) {
        synchronized(lock) { observers.remove(observer) }
    }

    /** Each toggle reads the state updated by the previous call, so rapid taps
     *  are applied in order instead of racing on stale hardware state. */
    fun toggle(): TorchResult = synchronized(lock) { applyLocked(!isOn) }

    fun setEnabled(enabled: Boolean): TorchResult = synchronized(lock) {
        applyLocked(enabled)
    }

    fun setLevel(level: Float): Boolean = synchronized(lock) {
        val normalized = level.coerceIn(MIN_LEVEL, 1f)
        store.level = normalized
        if (!hardware.levelSupported || !isOn) return true

        try {
            hardware.setLevel(normalized)
            true
        } catch (_: TorchHardwareException) {
            false
        } catch (_: Exception) {
            false
        }
    }

    /** Receives changes made outside this controller, including other apps. */
    fun onExternalStateChanged(isOn: Boolean) {
        val snapshot = synchronized(lock) {
            if (!hardware.available || this.isOn == isOn) return
            this.isOn = isOn
            store.isOn = isOn
            snapshotLocked()
        }
        notifyObservers(snapshot)
    }

    fun notifyCurrentState() {
        notifyObservers(snapshot())
    }

    private fun applyLocked(enabled: Boolean): TorchResult {
        if (!hardware.available) {
            isOn = false
            store.isOn = false
            val snapshot = snapshotLocked()
            notifyObservers(snapshot)
            return TorchResult(snapshot, TorchError.UNAVAILABLE)
        }

        return try {
            hardware.setEnabled(enabled, store.level)
            isOn = enabled
            store.isOn = enabled
            val snapshot = snapshotLocked()
            notifyObservers(snapshot)
            TorchResult(snapshot)
        } catch (failure: TorchHardwareException) {
            if (failure.error == TorchError.UNAVAILABLE) {
                isOn = false
                store.isOn = false
            }
            TorchResult(snapshotLocked(), failure.error)
        } catch (_: Exception) {
            TorchResult(snapshotLocked(), TorchError.FAILED)
        }
    }

    private fun snapshotLocked() = TorchSnapshot(
        available = hardware.available,
        isOn = isOn,
        levelSupported = hardware.levelSupported,
    )

    private fun notifyObservers(snapshot: TorchSnapshot) {
        val current = synchronized(lock) { observers.toList() }
        current.forEach { observer ->
            try {
                observer.onStateChanged(snapshot)
            } catch (_: Exception) {
                // A broken observer must never block torch control.
            }
        }
    }

    private companion object {
        const val MIN_LEVEL = 0.01f
    }
}
