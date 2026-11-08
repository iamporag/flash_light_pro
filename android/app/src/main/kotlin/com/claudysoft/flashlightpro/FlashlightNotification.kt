package com.claudysoft.flashlightpro

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import android.view.View
import android.widget.RemoteViews

/**
 * Builds the single unified control panel shown by [TorchForegroundService].
 *
 * The card renders from the authoritative [TorchSnapshot] plus the native mode
 * and shake preferences, so the notification, tile, widget, and Flutter UI can
 * never disagree. RemoteViews only: no Flutter widgets are involved.
 */
internal object FlashlightNotification {
    fun build(
        context: Context,
        channelId: String,
        snapshot: TorchSnapshot,
        mode: TorchMode,
        paused: Boolean,
        shakeEnabled: Boolean,
        shakeMonitoring: Boolean,
        flashlightOn: Boolean,
        openIntent: PendingIntent,
        flashlightIntent: PendingIntent,
        shakeIntent: PendingIntent,
        sosIntent: PendingIntent,
        strobeIntent: PendingIntent,
        stopIntent: PendingIntent,
        error: String? = null,
    ): Notification {
        val patternActive = mode != TorchMode.OFF
        val anyActive = flashlightOn || shakeEnabled || patternActive

        val title = when {
            !snapshot.available && !patternActive ->
                context.getString(R.string.notification_unavailable)
            mode == TorchMode.SOS -> context.getString(
                if (paused) R.string.notification_pattern_paused
                else R.string.notification_sos_active,
            )
            mode == TorchMode.STROBE -> context.getString(
                if (paused) R.string.notification_pattern_paused
                else R.string.notification_strobe_active,
            )
            flashlightOn -> context.getString(R.string.notification_torch_running)
            shakeEnabled -> context.getString(R.string.notification_shake_ready)
            else -> context.getString(R.string.notification_torch_off)
        }
        val subtitle = when (mode) {
            TorchMode.SOS -> context.getString(R.string.notification_sos_subtitle)
            TorchMode.STROBE -> context.getString(
                R.string.notification_strobe_subtitle,
            )
            TorchMode.OFF -> when {
                flashlightOn -> context.getString(R.string.notification_background_on)
                shakeEnabled -> context.getString(
                    R.string.notification_shake_on_subtitle,
                )
                else -> context.getString(R.string.notification_background_off)
            }
        }
        val modeLabel = when (mode) {
            TorchMode.SOS -> context.getString(R.string.notification_mode_sos)
            TorchMode.STROBE -> context.getString(R.string.notification_mode_strobe)
            TorchMode.OFF -> context.getString(
                if (shakeEnabled) R.string.notification_mode_shake
                else R.string.notification_mode_background,
            )
        }
        val chipText = context.getString(
            when {
                paused -> R.string.notification_status_paused
                anyActive -> R.string.notification_status_active
                else -> R.string.notification_status_inactive
            },
        )

        val on = context.getString(R.string.notification_on)
        val off = context.getString(R.string.notification_off)
        val unavailable = context.getString(R.string.notification_unavailable)

        val collapsed = RemoteViews(
            context.packageName,
            R.layout.notification_flashlight_collapsed,
        ).apply {
            setTextViewText(R.id.notification_brand, context.getString(R.string.app_name))
            setTextViewText(R.id.notification_status, title)
            setContentDescription(R.id.notification_collapsed_root, title)
            bindChip(this, context, anyActive, chipText)
            setOnClickPendingIntent(R.id.notification_collapsed_root, openIntent)

            if (snapshot.available) {
                setViewVisibility(R.id.notification_toggle, View.VISIBLE)
                setOnClickPendingIntent(R.id.notification_toggle, flashlightIntent)
                setContentDescription(
                    R.id.notification_toggle,
                    context.getString(
                        if (flashlightOn) R.string.notification_turn_off_description
                        else R.string.notification_turn_on_description,
                    ),
                )
            } else {
                setViewVisibility(R.id.notification_toggle, View.GONE)
            }
        }

        val expanded = RemoteViews(
            context.packageName,
            R.layout.notification_flashlight_expanded,
        ).apply {
            setTextViewText(R.id.notification_brand, context.getString(R.string.app_name))
            setTextViewText(R.id.notification_mode, modeLabel)
            setTextViewText(R.id.notification_expanded_title, title)
            setTextViewText(R.id.notification_expanded_subtitle, subtitle)
            setContentDescription(R.id.notification_expanded_root, "$title. $subtitle")
            bindChip(this, context, anyActive, chipText)
            setOnClickPendingIntent(R.id.notification_expanded_root, openIntent)

            bindControl(
                views = this,
                context = context,
                rootId = R.id.notification_control_flashlight,
                labelId = R.id.notification_control_flashlight_label,
                stateId = R.id.notification_control_flashlight_state,
                iconId = R.id.notification_control_flashlight_icon,
                active = flashlightOn,
                label = context.getString(R.string.notification_control_flashlight),
                state = if (snapshot.available) (if (flashlightOn) on else off)
                else unavailable,
                intent = if (snapshot.available) flashlightIntent else null,
                description = context.getString(
                    if (flashlightOn) R.string.notification_turn_off_description
                    else R.string.notification_turn_on_description,
                ),
            )
            bindControl(
                views = this,
                context = context,
                rootId = R.id.notification_control_shake,
                labelId = R.id.notification_control_shake_label,
                stateId = R.id.notification_control_shake_state,
                iconId = R.id.notification_control_shake_icon,
                active = shakeEnabled && shakeMonitoring,
                label = context.getString(R.string.notification_control_shake),
                state = if (shakeEnabled) on else off,
                intent = shakeIntent,
                description = context.getString(
                    R.string.notification_control_shake_description,
                ),
            )
            bindControl(
                views = this,
                context = context,
                rootId = R.id.notification_control_sos,
                labelId = R.id.notification_control_sos_label,
                stateId = R.id.notification_control_sos_state,
                iconId = R.id.notification_control_sos_icon,
                active = mode == TorchMode.SOS,
                label = context.getString(R.string.notification_control_sos),
                state = if (mode == TorchMode.SOS) on else off,
                intent = sosIntent,
                description = context.getString(
                    R.string.notification_control_sos_description,
                ),
            )
            bindControl(
                views = this,
                context = context,
                rootId = R.id.notification_control_strobe,
                labelId = R.id.notification_control_strobe_label,
                stateId = R.id.notification_control_strobe_state,
                iconId = R.id.notification_control_strobe_icon,
                active = mode == TorchMode.STROBE,
                label = context.getString(R.string.notification_control_strobe),
                state = if (mode == TorchMode.STROBE) on else off,
                intent = strobeIntent,
                description = context.getString(
                    R.string.notification_control_strobe_description,
                ),
            )

            setOnClickPendingIntent(R.id.notification_action_open, openIntent)
            setContentDescription(
                R.id.notification_action_open,
                context.getString(R.string.notification_open_controls),
            )
            setOnClickPendingIntent(R.id.notification_action_stop, stopIntent)
            setContentDescription(
                R.id.notification_action_stop,
                context.getString(R.string.notification_stop_background_description),
            )

            if (error != null) {
                setViewVisibility(R.id.notification_error, View.VISIBLE)
                setTextViewText(R.id.notification_error, error)
            } else {
                setViewVisibility(R.id.notification_error, View.GONE)
            }
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).setPriority(Notification.PRIORITY_LOW)
        }

        builder
            .setSmallIcon(R.drawable.ic_tile_torch)
            .setContentTitle(title)
            .setContentText(subtitle)
            .setContentIntent(openIntent)
            .setCustomContentView(collapsed)
            .setCustomBigContentView(expanded)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setColor(context.getColor(R.color.notification_accent))

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(
                Notification.FOREGROUND_SERVICE_IMMEDIATE,
            )
        }

        return builder.build()
    }

    private fun bindControl(
        views: RemoteViews,
        context: Context,
        rootId: Int,
        labelId: Int,
        stateId: Int,
        iconId: Int,
        active: Boolean,
        label: String,
        state: String,
        intent: PendingIntent?,
        description: String,
    ) {
        views.setInt(
            rootId,
            "setBackgroundResource",
            if (active) R.drawable.notification_control_on
            else R.drawable.notification_control_off,
        )
        views.setTextViewText(labelId, label)
        views.setTextViewText(stateId, state)
        views.setTextColor(
            labelId,
            context.getColor(
                if (active) R.color.notification_text_primary
                else R.color.notification_text_muted,
            ),
        )
        views.setTextColor(
            stateId,
            context.getColor(
                if (active) R.color.notification_control_on_text
                else R.color.notification_control_off_text,
            ),
        )
        views.setInt(
            stateId,
            "setBackgroundResource",
            if (active) R.drawable.notification_switch_on
            else R.drawable.notification_switch_off,
        )
        views.setInt(
            iconId,
            "setColorFilter",
            context.getColor(
                if (active) R.color.notification_torch
                else R.color.notification_text_muted,
            ),
        )
        views.setContentDescription(rootId, description)
        if (intent != null) {
            views.setOnClickPendingIntent(rootId, intent)
        }
    }

    private fun bindChip(
        views: RemoteViews,
        context: Context,
        active: Boolean,
        text: String,
    ) {
        views.setTextViewText(R.id.notification_chip, text)
        views.setTextColor(
            R.id.notification_chip,
            context.getColor(
                if (active) R.color.notification_chip_active_text
                else R.color.notification_chip_inactive_text,
            ),
        )
        views.setInt(
            R.id.notification_chip,
            "setBackgroundResource",
            if (active) R.drawable.notification_chip_active
            else R.drawable.notification_chip_inactive,
        )
        views.setContentDescription(R.id.notification_chip, text)
    }
}
