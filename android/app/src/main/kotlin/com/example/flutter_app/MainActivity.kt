package com.example.flutter_app

import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
  private val CHANNEL = "words_for_nerds/tts"
  private val mainHandler = Handler(Looper.getMainLooper())

  private var tts: TextToSpeech? = null
  private var ttsReady: Boolean = false
  private var lastSpokenText: String = ""

  private lateinit var channel: MethodChannel

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    channel.setMethodCallHandler { call, result ->
      when (call.method) {
        "speak" -> {
          val text = call.argument<String>("text") ?: ""
          lastSpokenText = text

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
          // Tell Dart we stopped (so UI un-bolds immediately)
          mainHandler.post { channel.invokeMethod("onStop", null) }
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

          // Send start/done/error events back to Dart for bolding.
          tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String?) {
              mainHandler.post {
                channel.invokeMethod("onStart", mapOf("text" to lastSpokenText))
              }
            }

            override fun onDone(utteranceId: String?) {
              mainHandler.post { channel.invokeMethod("onDone", null) }
            }

            @Deprecated("Deprecated in Java")
            override fun onError(utteranceId: String?) {
              mainHandler.post { channel.invokeMethod("onError", null) }
            }

            override fun onError(utteranceId: String?, errorCode: Int) {
              mainHandler.post { channel.invokeMethod("onError", null) }
            }
          })

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
