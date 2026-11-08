package io.github.iamporag.flashlightpro

import android.content.Context
import android.os.Handler
import android.os.Looper

/**
 * Executes SOS and strobe patterns through the shared [TorchController].
 *
 * Playback lives in native code so a pattern keeps running after the Flutter
 * engine is gone. Only one listener/pattern can exist at a time; starting a
 * mode replaces the previous one, and every hardware step is serialized by the
 * controller.
 */
internal object TorchPatternPlayer {
    private data class Step(val on: Boolean, val durationMs: Long)

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var controller: TorchController
    private lateinit var appContext: Context
    private var steps: List<Step> = emptyList()
    private var index = 0
    private var generation = 0
    private var running = false

    private val tick = object : Runnable {
        override fun run() {
            if (!running) return
            if (TorchModeState.mode == TorchMode.OFF) {
                running = false
                return
            }
            val step = steps[index % steps.size]
            index++
            if (controller.snapshot().available) {
                val result = controller.setEnabled(step.on)
                if (result.error == TorchError.UNAVAILABLE) {
                    stop(appContext)
                    return
                }
            }
            handler.postDelayed(this, step.durationMs)
        }
    }

    fun isActive(): Boolean = TorchModeState.mode != TorchMode.OFF

    fun start(context: Context, mode: TorchMode): Boolean {
        if (mode == TorchMode.OFF) return false
        val app = context.applicationContext
        appContext = app
        controller = TorchManager.get(app)
        if (!controller.snapshot().available) return false

        val nextSteps = when (mode) {
            TorchMode.SOS -> sosSteps()
            TorchMode.STROBE -> strobeSteps(TorchPreferences.strobeInterval(app))
            TorchMode.OFF -> return false
        }

        generation++
        handler.removeCallbacks(tick)
        if (isActive()) TorchModeState.set(app, TorchMode.OFF, false)
        // Establish a known-off baseline before playback starts.
        controller.setEnabled(false)

        steps = nextSteps
        index = 0
        running = true
        TorchModeState.set(app, mode, false)
        handler.postDelayed(tick, 0)
        return true
    }

    fun stop(context: Context): Boolean {
        val app = context.applicationContext
        val wasActive = isActive() || running
        generation++
        running = false
        index = 0
        steps = emptyList()
        handler.removeCallbacks(tick)
        if (isActive()) TorchModeState.set(app, TorchMode.OFF, false)
        if (::controller.isInitialized && controller.snapshot().available) {
            controller.setEnabled(false)
        }
        return wasActive
    }

    fun pause(context: Context): Boolean {
        if (!isActive() || TorchModeState.paused) return false
        val app = context.applicationContext
        generation++
        running = false
        handler.removeCallbacks(tick)
        if (::controller.isInitialized && controller.snapshot().available) {
            controller.setEnabled(false)
        }
        TorchModeState.set(app, TorchModeState.mode, true)
        return true
    }

    fun resume(context: Context): Boolean {
        if (!isActive() || !TorchModeState.paused) return false
        val app = context.applicationContext
        appContext = app
        controller = TorchManager.get(app)
        generation++
        index = 0
        running = true
        TorchModeState.set(app, TorchModeState.mode, false)
        handler.postDelayed(tick, 0)
        return true
    }

    /** Rebuilds the schedule so a new strobe speed applies immediately. */
    fun onStrobeIntervalChanged(context: Context) {
        if (TorchModeState.mode != TorchMode.STROBE) return
        steps = strobeSteps(TorchPreferences.strobeInterval(context))
    }

    private fun sosSteps(): List<Step> {
        val unit = 180L
        val cycleGap = 1800L
        val steps = mutableListOf<Step>()

        fun addLetter(symbols: List<Long>) {
            symbols.forEachIndexed { index, duration ->
                steps += Step(on = true, durationMs = duration)
                steps += Step(
                    on = false,
                    durationMs = if (index == symbols.lastIndex) unit * 3 else unit,
                )
            }
        }

        addLetter(listOf(unit, unit, unit))
        addLetter(listOf(unit * 3, unit * 3, unit * 3))
        addLetter(listOf(unit, unit, unit))
        steps[steps.lastIndex] = Step(on = false, durationMs = cycleGap)
        return steps
    }

    private fun strobeSteps(intervalMs: Int): List<Step> {
        val interval = intervalMs.coerceIn(200, 1000)
        val onMs = (interval / 2).coerceIn(50, (interval - 50).coerceAtLeast(50))
        return listOf(
            Step(on = true, durationMs = onMs.toLong()),
            Step(on = false, durationMs = (interval - onMs).toLong()),
        )
    }
}
