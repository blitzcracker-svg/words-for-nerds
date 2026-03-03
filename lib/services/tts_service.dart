import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class TtsService {
  static const MethodChannel _ch = MethodChannel('words_for_nerds/tts');

  static bool _initialized = false;

  /// The exact text currently being spoken (or null).
  static final ValueNotifier<String?> speakingText = ValueNotifier<String?>(null);

  /// True while TTS is actively speaking.
  static final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);

  static void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    _ch.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onStart':
          final args = (call.arguments is Map) ? (call.arguments as Map) : const {};
          final text = args['text']?.toString();
          speakingText.value = text;
          isSpeaking.value = true;
          break;

        case 'onDone':
        case 'onStop':
        case 'onError':
          isSpeaking.value = false;
          speakingText.value = null;
          break;
      }
    });
  }

  static Future<bool> speak(String text) async {
    _ensureInitialized();
    try {
      final ok = await _ch.invokeMethod<bool>('speak', {'text': text});
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> stop() async {
    _ensureInitialized();
    try {
      await _ch.invokeMethod('stop');
    } catch (_) {}
  }
}
