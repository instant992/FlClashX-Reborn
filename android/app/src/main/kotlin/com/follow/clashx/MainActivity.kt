package com.follow.clashx

import android.annotation.SuppressLint
import android.os.Bundle
import android.provider.Settings
import com.follow.clashx.common.GlobalState
import com.follow.clashx.common.Components
import com.follow.clashx.plugins.AppPlugin
import com.follow.clashx.plugins.ServicePlugin
import com.follow.clashx.plugins.TilePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity(),
    CoroutineScope by CoroutineScope(SupervisorJob() + Dispatchers.Default) {

    private var deviceIdChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableHighRefreshRate()
    }

    @SuppressLint("WrongConstant")
    private fun enableHighRefreshRate() {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.R) return
        try {
            val display = display ?: return
            var bestModeId = 0
            var bestRate = 60f
            for (mode in display.supportedModes) {
                if (mode.refreshRate > bestRate) {
                    bestRate = mode.refreshRate
                    bestModeId = mode.modeId
                }
            }
            if (bestModeId != 0) {
                window.attributes = window.attributes.apply {
                    preferredDisplayModeId = bestModeId
                }
            }
        } catch (_: Exception) {
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(AppPlugin())
        flutterEngine.plugins.add(ServicePlugin())
        flutterEngine.plugins.add(TilePlugin())
        State.flutterEngine = flutterEngine
        deviceIdChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "${Components.PACKAGE_NAME}/device_id"
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAndroidId" -> result.success(getAndroidId())
                    else -> result.notImplemented()
                }
            }
        }
    }

    @SuppressLint("HardwareIds")
    private fun getAndroidId(): String? {
        return try {
            Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
        } catch (_: Exception) {
            null
        }
    }

    override fun onDestroy() {
        deviceIdChannel?.setMethodCallHandler(null)
        GlobalState.launch {
            Service.setEventListener(null)
        }
        State.flutterEngine = null
        super.onDestroy()
    }
}