package com.vexellab.veil

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.Activity
import android.content.Intent
import android.provider.Settings

class MainActivity : FlutterActivity() {
    private var pendingPlayer: MethodChannel.Result? = null
    private var originalBrightness: Float? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "veil/player").setMethodCallHandler { call, result ->
            when (call.method) {
                "getBrightness" -> {
                    val level = window.attributes.screenBrightness
                    result.success(if (level >= 0) level.toDouble() else Settings.System.getInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS, 128) / 255.0)
                }
                "setBrightness" -> {
                    val value = call.arguments as? Number
                    if (value == null) { result.error("arguments", "Missing brightness", null) }
                    else {
                        if (originalBrightness == null) originalBrightness = window.attributes.screenBrightness
                        window.attributes = window.attributes.apply { screenBrightness = value.toFloat().coerceIn(0.02f, 1f) }
                        result.success(null)
                    }
                }
                "restoreBrightness" -> {
                    originalBrightness?.let { brightness -> window.attributes = window.attributes.apply { screenBrightness = brightness } }
                    originalBrightness = null
                    result.success(null)
                }
                "fullscreen" -> {
                    val url = call.argument<String>("url")
                    if (pendingPlayer != null || url == null || !url.startsWith("https://")) {
                        result.error("unavailable", "Cannot present native player", null)
                    } else {
                        pendingPlayer = result
                        val intent = Intent(this, NativePlaybackActivity::class.java)
                            .putExtra("url", url)
                            .putExtra("position", call.argument<Number>("position")?.toLong() ?: 0L)
                            .putExtra("playing", call.argument<Boolean>("playing") ?: false)
                            .putExtra("volume", call.argument<Number>("volume")?.toFloat() ?: 1f)
                            .putExtra("format", call.argument<String>("format") ?: "hls")
                            .putExtra("headers", java.util.HashMap(call.argument<Map<String, String>>("headers") ?: emptyMap()))
                        startActivityForResult(intent, 901)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 901) {
            if (resultCode == Activity.RESULT_OK) pendingPlayer?.success(mapOf("position" to (data?.getLongExtra("position", 0L) ?: 0L), "playing" to (data?.getBooleanExtra("playing", false) ?: false)))
            else pendingPlayer?.error("playback", "Native player closed without playback state", null)
            pendingPlayer = null
        }
    }
}
