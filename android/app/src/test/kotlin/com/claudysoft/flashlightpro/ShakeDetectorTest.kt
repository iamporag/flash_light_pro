package com.claudysoft.flashlightpro

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ShakeDetectorTest {
    private val gravity = 9.80665f

    private fun sample(
        detector: ShakeDetector,
        x: Float = 0f,
        y: Float = 0f,
        z: Float = gravity,
        at: Long,
    ): Boolean = detector.addSample(x, y, z, at)

    @Test
    fun `a hard shake is detected once`() {
        val detector = ShakeDetector()

        assertTrue(sample(detector, z = 30f, at = 1_000L))
        assertFalse(sample(detector, z = 30f, at = 1_100L))
    }

    @Test
    fun `cooldown blocks repeats until the phone settles`() {
        val detector = ShakeDetector()
        assertTrue(sample(detector, z = 30f, at = 1_000L))

        assertFalse(sample(detector, z = gravity, at = 1_100L))
        assertFalse(sample(detector, z = 30f, at = 1_200L))

        assertTrue(sample(detector, z = 30f, at = 2_500L))
    }

    @Test
    fun `noise below the threshold is ignored`() {
        val detector = ShakeDetector()

        assertFalse(sample(detector, z = gravity + 5f, at = 1_000L))
        assertFalse(sample(detector, z = gravity + 12.9f, at = 2_000L))
    }

    @Test
    fun `sensitivity thresholds match the flutter levels`() {
        assertEquals(18.0, ShakeDetector.thresholdForSensitivity(0), 0.0)
        assertEquals(13.0, ShakeDetector.thresholdForSensitivity(1), 0.0)
        assertEquals(8.5, ShakeDetector.thresholdForSensitivity(2), 0.0)
        assertEquals(13.0, ShakeDetector.thresholdForSensitivity(99), 0.0)
    }

    @Test
    fun `a high sensitivity detects lighter movement`() {
        val detector = ShakeDetector(
            threshold = ShakeDetector.HIGH_THRESHOLD,
        )

        assertTrue(sample(detector, z = gravity + 9f, at = 1_000L))
    }

    @Test
    fun `reset re-arms a detector that never settled`() {
        val detector = ShakeDetector()
        assertTrue(sample(detector, z = 30f, at = 1_000L))
        assertFalse(sample(detector, z = 30f, at = 2_600L))

        detector.reset()

        assertTrue(sample(detector, z = 30f, at = 2_700L))
    }
}
