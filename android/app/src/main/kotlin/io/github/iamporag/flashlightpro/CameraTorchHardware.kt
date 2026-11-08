package io.github.iamporag.flashlightpro

import android.content.Context
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import kotlin.math.roundToInt

class CameraTorchHardware(context: Context) : TorchHardware {
    private val manager =
        context.getSystemService(Context.CAMERA_SERVICE) as? CameraManager

    private val cameraId: String? = manager?.let(::findTorchCamera)

    private val maximumLevel: Int = manager?.let(::readMaximumLevel) ?: 1

    private var callback: CameraManager.TorchCallback? = null

    override val available: Boolean get() = cameraId != null

    override val levelSupported: Boolean
        get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            maximumLevel > 1

    fun start(onStateChanged: (Boolean) -> Unit) {
        val cameraManager = manager ?: return
        val targetCamera = cameraId ?: return
        if (callback != null) return

        val torchCallback = object : CameraManager.TorchCallback() {
            override fun onTorchModeChanged(cameraId: String, enabled: Boolean) {
                if (cameraId == targetCamera) onStateChanged(enabled)
            }

            override fun onTorchModeUnavailable(cameraId: String) {
                if (cameraId == targetCamera) onStateChanged(false)
            }
        }

        callback = torchCallback
        try {
            cameraManager.registerTorchCallback(
                torchCallback,
                Handler(Looper.getMainLooper()),
            )
        } catch (_: Exception) {
            callback = null
        }
    }

    override fun setEnabled(enabled: Boolean, level: Float) {
        val cameraManager = manager ?: throw unavailable()
        val id = cameraId ?: throw unavailable()

        try {
            if (!enabled) {
                cameraManager.setTorchMode(id, false)
                return
            }

            if (levelSupported) {
                cameraManager.turnOnTorchWithStrengthLevel(
                    id,
                    strengthFor(level),
                )
            } else {
                cameraManager.setTorchMode(id, true)
            }
        } catch (failure: CameraAccessException) {
            throw TorchHardwareException(
                when (failure.reason) {
                    CameraAccessException.CAMERA_IN_USE,
                    CameraAccessException.MAX_CAMERAS_IN_USE,
                    -> TorchError.CAMERA_IN_USE

                    else -> TorchError.FAILED
                },
            )
        } catch (_: IllegalArgumentException) {
            throw unavailable()
        } catch (_: SecurityException) {
            throw TorchHardwareException(TorchError.FAILED)
        }
    }

    override fun setLevel(level: Float) {
        if (!levelSupported) return

        val cameraManager = manager ?: throw unavailable()
        val id = cameraId ?: throw unavailable()

        try {
            cameraManager.turnOnTorchWithStrengthLevel(id, strengthFor(level))
        } catch (failure: CameraAccessException) {
            throw TorchHardwareException(
                if (failure.reason == CameraAccessException.CAMERA_IN_USE ||
                    failure.reason == CameraAccessException.MAX_CAMERAS_IN_USE
                ) {
                    TorchError.CAMERA_IN_USE
                } else {
                    TorchError.FAILED
                },
            )
        } catch (_: IllegalArgumentException) {
            throw unavailable()
        } catch (_: SecurityException) {
            throw TorchHardwareException(TorchError.FAILED)
        }
    }

    private fun strengthFor(level: Float): Int =
        (level.coerceIn(0f, 1f) * maximumLevel)
            .roundToInt()
            .coerceIn(1, maximumLevel)

    private fun readMaximumLevel(cameraManager: CameraManager): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return 1

        return try {
            val id = findTorchCamera(cameraManager) ?: return 1
            cameraManager.getCameraCharacteristics(id)
                .get(CameraCharacteristics.FLASH_INFO_STRENGTH_MAXIMUM_LEVEL)
                ?: 1
        } catch (_: Exception) {
            1
        }
    }

    private fun findTorchCamera(cameraManager: CameraManager): String? {
        return try {
            var fallback: String? = null
            for (id in cameraManager.cameraIdList) {
                val characteristics = cameraManager.getCameraCharacteristics(id)
                if (characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) != true) {
                    continue
                }

                if (characteristics.get(CameraCharacteristics.LENS_FACING) ==
                    CameraCharacteristics.LENS_FACING_BACK
                ) {
                    return id
                }
                if (fallback == null) fallback = id
            }
            fallback
        } catch (_: Exception) {
            null
        }
    }

    private fun unavailable() = TorchHardwareException(TorchError.UNAVAILABLE)
}
