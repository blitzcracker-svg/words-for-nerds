package com.example.flutter_app

import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
  private val CHANNEL = "words_for_nerds/tts"
  private var tts: TextToSpeech? = null
  private var ttsReady: Boolean = false

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "speak" -> {
            val text = call.argument<String>("text") ?: ""
            ensureTts { ok ->
              if (!ok) {
                result.success(false)
                return@ensureTts
              }
              try {
                tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "words_for_nerds_utt")
                result.success(true)
              } catch (e: Exception) {
                result.success(false)
              }
            }
          }

          "stop" -> {
            try {
              tts?.stop()
            } catch (_: Exception) {}
            result.success(true)
          }

          else -> result.notImplemented()
        }
      }
  }

  private fun ensureTts(cb: (Boolean) -> Unit) {
    if (ttsReady && tts != null) {
      cb(true)
      return
    }

    if (tts == null) {
      tts = TextToSpeech(this) { status ->
        if (status == TextToSpeech.SUCCESS) {
          ttsReady = true
          tts?.language = Locale.US
          tts?.setSpeechRate(1.0f)
          tts?.setPitch(1.0f)
          cb(true)
        } else {
          ttsReady = false
          cb(false)
        }
      }
    } else {
      cb(ttsReady)
    }
  }

  private fun shutdownTts() {
    try {
      tts?.stop()
      tts?.shutdown()
    } catch (_: Exception) {}
    tts = null
    ttsReady = false
  }

  override fun onDestroy() {
    shutdownTts()
    super.onDestroy()
  }
}
