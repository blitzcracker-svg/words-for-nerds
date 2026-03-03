import 'package:flutter/services.dart';

class TtsService {
  static const MethodChannel _ch = MethodChannel('words_for_nerds/tts');

  static Future<bool> speak(String text) async {
    try {
      final ok = await _ch.invokeMethod<bool>('speak', {'text': text});
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> stop() async {
    try {
      await _ch.invokeMethod('stop');
    } catch (_) {}
  }
}
