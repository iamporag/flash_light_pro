package com.claudysoft.flashlightpro

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.widget.Toast

class TorchTileService : TileService() {
    override fun onStartListening() {
        super.onStartListening()
        updateTile()
    }

    override fun onClick() {
        super.onClick()

        // A running SOS/strobe mode is stopped explicitly. Toggling the shared
        // controller here would act on one arbitrary blink phase and leave the
        // native pattern fighting the tap.
        if (TorchPatternPlayer.isActive()) {
            TorchForegroundService.stopPattern(this)
            updateTile()
            return
        }

        val result = TorchManager.get(this).toggle()
        if (result.error != null) {
            Toast.makeText(this, messageFor(result.error), Toast.LENGTH_SHORT).show()
        } else {
            syncForegroundService(result.snapshot.isOn)
        }
        updateTile()
    }

    private fun syncForegroundService(isOn: Boolean) {
        if (!isOn) {
            TorchForegroundService.stop(this)
            return
        }
        if (!TorchPreferences.backgroundEnabled(this)) return

        // A tile tap is a user action on an app UI element, which is exempt
        // from the Android 12+ background foreground-service start limit.
        if (!TorchForegroundService.start(this).started) {
            Toast.makeText(this, R.string.background_start_failed, Toast.LENGTH_SHORT).show()
        }
    }

    private fun updateTile() {
        val tile = qsTile ?: return
        val snapshot = TorchManager.get(this).snapshot()
        val mode = TorchModeState.mode
        val torchOn = snapshot.isOn || mode != TorchMode.OFF

        tile.state = when {
            !snapshot.available -> Tile.STATE_UNAVAILABLE
            torchOn -> Tile.STATE_ACTIVE
            else -> Tile.STATE_INACTIVE
        }
        tile.label = getString(
            if (snapshot.available) R.string.tile_label else R.string.tile_label_unavailable,
        )
        tile.icon = Icon.createWithResource(this, R.drawable.ic_tile_torch)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = getString(
                when {
                    mode == TorchMode.SOS -> R.string.tile_state_sos
                    mode == TorchMode.STROBE -> R.string.tile_state_strobe
                    snapshot.isOn -> R.string.tile_state_on
                    else -> R.string.tile_state_off
                },
            )
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // TalkBack reads this instead of inferring state from the label and
            // icon color alone.
            tile.stateDescription = getString(
                when {
                    !snapshot.available -> R.string.tile_state_description_unavailable
                    mode == TorchMode.SOS -> R.string.tile_state_description_sos
                    mode == TorchMode.STROBE -> R.string.tile_state_description_strobe
                    snapshot.isOn -> R.string.tile_state_description_on
                    else -> R.string.tile_state_description_off
                },
            )
        }
        tile.updateTile()
    }

    private fun messageFor(error: TorchError): String = when (error) {
        TorchError.CAMERA_IN_USE -> getString(R.string.torch_camera_in_use)
        TorchError.UNAVAILABLE -> getString(R.string.torch_unavailable)
        TorchError.FAILED -> getString(R.string.torch_toggle_failed)
    }

    companion object {
        fun requestRefresh(context: Context) {
            try {
                requestListeningState(
                    context,
                    ComponentName(context, TorchTileService::class.java),
                )
            } catch (_: Exception) {
                // The tile may not be added or the device may not support it.
            }
        }
    }
}
