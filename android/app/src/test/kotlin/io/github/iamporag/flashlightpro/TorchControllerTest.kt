package io.github.iamporag.flashlightpro

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class TorchControllerTest {
    private class FakeHardware(
        override var available: Boolean = true,
        override var levelSupported: Boolean = false,
    ) : TorchHardware {
        var isOn = false
        var failure: TorchError? = null
        var enableCalls = 0
        var lastLevel = 1f

        override fun setEnabled(enabled: Boolean, level: Float) {
            failure?.let { throw TorchHardwareException(it) }
            enableCalls++
            lastLevel = level
            isOn = enabled
        }

        override fun setLevel(level: Float) {
            failure?.let { throw TorchHardwareException(it) }
            lastLevel = level
        }
    }

    private class FakeStore(
        override var isOn: Boolean = false,
        override var level: Float = 1f,
    ) : TorchStateStore

    private fun controller(
        hardware: FakeHardware = FakeHardware(),
        store: FakeStore = FakeStore(),
    ) = TorchController(hardware, store)

    @Test
    fun `toggle changes state and persists it`() {
        val hardware = FakeHardware()
        val store = FakeStore()
        val controller = controller(hardware, store)

        assertTrue(controller.toggle().snapshot.isOn)
        assertTrue(store.isOn)
        assertTrue(hardware.isOn)

        assertFalse(controller.toggle().snapshot.isOn)
        assertFalse(store.isOn)
        assertFalse(hardware.isOn)
    }

    @Test
    fun `rapid toggles are applied in order`() {
        val hardware = FakeHardware()
        val controller = controller(hardware)

        val results = List(5) { controller.toggle() }

        assertTrue(results.first().snapshot.isOn)
        assertFalse(results[1].snapshot.isOn)
        assertTrue(results[2].snapshot.isOn)
        assertEquals(5, hardware.enableCalls)
        assertTrue(controller.snapshot().isOn)
    }

    @Test
    fun `unavailable hardware reports an error and stays off`() {
        val hardware = FakeHardware(available = false)
        val controller = controller(hardware)

        val result = controller.toggle()

        assertFalse(result.success)
        assertEquals(TorchError.UNAVAILABLE, result.error)
        assertFalse(result.snapshot.isOn)
        assertEquals(0, hardware.enableCalls)
    }

    @Test
    fun `camera in use keeps the previous state`() {
        val hardware = FakeHardware()
        val controller = controller(hardware)
        hardware.failure = TorchError.CAMERA_IN_USE

        val result = controller.setEnabled(true)

        assertEquals(TorchError.CAMERA_IN_USE, result.error)
        assertFalse(result.snapshot.isOn)
        assertFalse(controller.snapshot().isOn)
    }

    @Test
    fun `external changes update state and notify observers`() {
        val hardware = FakeHardware()
        val controller = controller(hardware)
        val snapshots = mutableListOf<TorchSnapshot>()
        controller.addObserver { snapshots.add(it) }

        controller.onExternalStateChanged(true)
        controller.onExternalStateChanged(true)
        controller.onExternalStateChanged(false)

        assertEquals(2, snapshots.size)
        assertTrue(snapshots.first().isOn)
        assertFalse(controller.snapshot().isOn)
    }

    @Test
    fun `level is stored even when hardware has no strength control`() {
        val hardware = FakeHardware(levelSupported = false)
        val store = FakeStore()
        val controller = controller(hardware, store)

        assertTrue(controller.setLevel(0.4f))

        assertEquals(0.4f, store.level, 0.001f)
    }

    @Test
    fun `level is applied while the torch is on`() {
        val hardware = FakeHardware(levelSupported = true)
        val controller = controller(hardware)
        controller.setEnabled(true)

        assertTrue(controller.setLevel(0.6f))

        assertEquals(0.6f, hardware.lastLevel, 0.001f)
    }

    @Test
    fun `removed observers are not notified`() {
        val controller = controller()
        var calls = 0
        val observer = TorchObserver { calls++ }

        controller.addObserver(observer)
        controller.setEnabled(true)
        controller.removeObserver(observer)
        controller.setEnabled(false)

        assertEquals(1, calls)
    }

    @Test
    fun `initial state comes from the persisted store`() {
        val controller = controller(store = FakeStore(isOn = true))

        assertTrue(controller.snapshot().isOn)
    }

    @Test
    fun `failure on disable keeps the torch reported on`() {
        val hardware = FakeHardware()
        val controller = controller(hardware)
        controller.setEnabled(true)
        hardware.failure = TorchError.FAILED

        val result = controller.setEnabled(false)

        assertEquals(TorchError.FAILED, result.error)
        assertTrue(result.snapshot.isOn)
    }
}
