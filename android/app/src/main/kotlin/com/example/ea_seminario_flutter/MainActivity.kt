package com.example.ea_easyeat_flutter

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.easyeat/nfc_hce"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startHce" -> {
                        val customerId = call.argument<String>("customerId")
                        if (customerId != null) {
                            HceService.currentCustomerId = customerId
                            // Enable the HCE service component
                            setHceServiceEnabled(true)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "customerId is null", null)
                        }
                    }
                    "stopHce" -> {
                        HceService.currentCustomerId = null
                        setHceServiceEnabled(false)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setHceServiceEnabled(enabled: Boolean) {
        val componentName = ComponentName(this, HceService::class.java)
        val state = if (enabled) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        } else {
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED
        }
        packageManager.setComponentEnabledSetting(
            componentName,
            state,
            PackageManager.DONT_KILL_APP
        )
    }
}
