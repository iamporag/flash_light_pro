package io.github.iamporag.flashlightpro

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.widget.RemoteViews
import android.widget.Toast

class TorchWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        updateAll(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_TOGGLE) {
            super.onReceive(context, intent)
            return
        }

        val pendingResult = goAsync()
        Thread {
            try {
                if (TorchPatternPlayer.isActive()) {
                    // Stop the native mode instead of toggling one blink phase.
                    TorchForegroundService.stopPattern(context)
                } else {
                    val result = TorchManager.get(context).toggle()
                    if (result.error != null) {
                        Handler(Looper.getMainLooper()).post {
                            Toast.makeText(
                                context,
                                messageFor(context, result.error),
                                Toast.LENGTH_SHORT,
                            ).show()
                        }
                    } else {
                        syncForegroundService(context, result.snapshot.isOn)
                    }
                }
                updateAll(context)
            } finally {
                pendingResult.finish()
            }
        }.start()
    }

    companion object {
        const val ACTION_TOGGLE =
            "io.github.iamporag.flashlightpro.action.TOGGLE_TORCH_FROM_WIDGET"

        private const val EXTRA_WIDGET_ID = "appWidgetId"

        fun updateAll(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, TorchWidgetProvider::class.java)
            val ids = appWidgetManager.getAppWidgetIds(component)
            if (ids.isEmpty()) return

            val snapshot = TorchManager.get(context).snapshot()
            for (id in ids) {
                appWidgetManager.updateAppWidget(
                    id,
                    buildViews(context, id, snapshot),
                )
            }
        }

        private fun buildViews(
            context: Context,
            appWidgetId: Int,
            snapshot: TorchSnapshot,
        ): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.torch_widget)
            val modeActive = TorchModeState.mode != TorchMode.OFF
            val isOn = snapshot.available && (snapshot.isOn || modeActive)
            val label = when {
                !snapshot.available -> context.getString(R.string.widget_unavailable)
                isOn -> context.getString(R.string.widget_on)
                else -> context.getString(R.string.widget_off)
            }
            val foreground = if (isOn) {
                context.getColor(R.color.widget_foreground_on)
            } else {
                context.getColor(R.color.widget_foreground_off)
            }

            views.setTextViewText(R.id.widget_label, label)
            views.setTextColor(R.id.widget_label, foreground)
            views.setInt(
                R.id.widget_icon,
                "setColorFilter",
                foreground,
            )
            views.setContentDescription(
                R.id.widget_root,
                context.getString(R.string.widget_description),
            )
            views.setInt(
                R.id.widget_root,
                "setBackgroundResource",
                if (isOn) R.drawable.widget_background_on else R.drawable.widget_background_off,
            )

            val intent = Intent(context, TorchWidgetProvider::class.java)
                .setAction(ACTION_TOGGLE)
                .putExtra(EXTRA_WIDGET_ID, appWidgetId)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            return views
        }

        private fun syncForegroundService(context: Context, isOn: Boolean) {
            if (!isOn) {
                TorchForegroundService.stop(context)
                return
            }
            if (!TorchPreferences.backgroundEnabled(context)) return

            // A widget tap is a user action on an app UI element, which is
            // exempt from the Android 12+ background service-start limit.
            if (TorchForegroundService.start(context).started) return

            Handler(Looper.getMainLooper()).post {
                Toast.makeText(
                    context,
                    R.string.background_start_failed,
                    Toast.LENGTH_SHORT,
                ).show()
            }
        }

        private fun messageFor(context: Context, error: TorchError): String = when (error) {
            TorchError.CAMERA_IN_USE -> context.getString(R.string.torch_camera_in_use)
            TorchError.UNAVAILABLE -> context.getString(R.string.torch_unavailable)
            TorchError.FAILED -> context.getString(R.string.torch_toggle_failed)
        }
    }
}
