package io.github.iamporag.flashlightpro

import android.content.Context
import android.os.Handler
import android.os.Looper

/**
 * Process-wide torch owner. The Flutter channel, Quick Settings tile, and home
 * screen widget all resolve this one controller, so they cannot fight over the
 * camera.
 */
object TorchManager {
    @Volatile
    private var instance: TorchController? = null

    fun get(context: Context): TorchController {
        instance?.let { return it }

        return synchronized(this) {
            instance ?: create(context.applicationContext).also { instance = it }
        }
    }

    private fun create(context: Context): TorchController {
        val hardware = CameraTorchHardware(context)
        val controller = TorchController(
            hardware = hardware,
            store = SharedPreferencesTorchStore(context),
            // Reconcile from the live CameraManager callback instead of
            // resurrecting a torch-on flag left by a previous process.
            restorePersistedState = false,
        )
        controller.addObserver(AndroidTorchSideEffects(context))
        hardware.start { controller.onExternalStateChanged(it) }
        return controller
    }
}

/** Keeps system surfaces in sync without running a background service. */
private class AndroidTorchSideEffects(context: Context) : TorchObserver {
    private val appContext = context.applicationContext
    private val handler = Handler(Looper.getMainLooper())
    private val update = Runnable {
        TorchWidgetProvider.updateAll(appContext)
        TorchTileService.requestRefresh(appContext)
    }

    override fun onStateChanged(snapshot: TorchSnapshot) {
        // Pattern playback changes the hardware every few hundred ms. The
        // service refreshes the visible surfaces once per mode change instead
        // of letting the debounce fire on every blink.
        if (TorchPatternPlayer.isActive()) return

        handler.removeCallbacks(update)
        handler.postDelayed(update, UPDATE_DELAY_MS)
    }

    private companion object {
        const val UPDATE_DELAY_MS = 150L
    }
}
