package io.github.iamporag.flashlightpro

import android.content.Context

class SharedPreferencesTorchStore(context: Context) : TorchStateStore {
    private val preferences = context.getSharedPreferences(
        "flash_light_pro_torch",
        Context.MODE_PRIVATE,
    )

    override var isOn: Boolean
        get() = try {
            preferences.getBoolean(KEY_IS_ON, false)
        } catch (_: ClassCastException) {
            false
        }
        set(value) {
            preferences.edit().putBoolean(KEY_IS_ON, value).apply()
        }

    override var level: Float
        get() = try {
            preferences.getFloat(KEY_LEVEL, 1f).coerceIn(MIN_LEVEL, 1f)
        } catch (_: ClassCastException) {
            1f
        }
        set(value) {
            preferences.edit()
                .putFloat(KEY_LEVEL, value.coerceIn(MIN_LEVEL, 1f))
                .apply()
        }

    private companion object {
        const val KEY_IS_ON = "torch_on"
        const val KEY_LEVEL = "torch_level"
        const val MIN_LEVEL = 0.01f
    }
}
