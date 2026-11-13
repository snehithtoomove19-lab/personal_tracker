package com.example.personal_tracker

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val pendingSharedTexts = mutableListOf<String>()
    private var shareChannel: MethodChannel? = null
    private var shareListenerReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        shareChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SHARE_CHANNEL,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "takePendingSharedTexts" -> {
                        shareListenerReady = true
                        result.success(pendingSharedTexts.toList())
                        pendingSharedTexts.clear()
                    }

                    else -> result.notImplemented()
                }
            }
        }

        extractSharedText(intent)?.let(pendingSharedTexts::add)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        val sharedText = extractSharedText(intent) ?: return
        if (shareListenerReady) {
            shareChannel?.invokeMethod("sharedTexts", listOf(sharedText))
        } else {
            pendingSharedTexts.add(sharedText)
        }
    }

    private fun extractSharedText(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_SEND || intent.type != "text/plain") {
            return null
        }

        val text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)
            ?.toString()
            ?.trim()
            .orEmpty()
        intent.removeExtra(Intent.EXTRA_TEXT)
        return text.takeIf(String::isNotEmpty)
    }

    private companion object {
        const val SHARE_CHANNEL = "personal_tracker/share"
    }
}
