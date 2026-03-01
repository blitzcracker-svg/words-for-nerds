import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/word_entry.dart';

class LibraryService {
  LibraryService._();
  static final LibraryService instance = LibraryService._();

  bool _ready = false;
  bool get ready => _ready;

  late final Map<String, WordEntry> _byWord;

  Future<void> initFromAsset() async {
    if (_ready) return;

    final raw = await rootBundle.loadString('assets/library.json');
    final data = jsonDecode(raw);

    if (data is! List) {
      throw StateError('assets/library.json must be a JSON array.');
    }

    final by = <String, WordEntry>{};
    for (final item in data) {
      if (item is Map) {
        final e = WordEntry.fromJson(item.cast<String, dynamic>());
        if (e.word.isNotEmpty) {
          by[e.word] = e; // last wins if duplicates
        }
      }
    }

    _byWord = by;
    _ready = true;
  }

  List<String> allWordsSorted() {
    final words = _byWord.keys.toList();
    words.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return words;
  }

  WordEntry? lookup(String word) => _byWord[word.trim().toUpperCase()];

  /// Suggestions (offline): contains match first, then prefix match.
  /// Returns up to [limit] results.
  List<String> suggest(String typed, {int limit = 15}) {
    final t = typed.trim().toUpperCase();
    if (t.isEmpty) return const [];

    final keys = _byWord.keys.toList();

    final out = <String>[];

    // 1) contains matches
    for (final w in keys) {
      if (w.contains(t)) {
        out.add(w);
        if (out.length >= limit) break;
      }
    }

    // 2) prefix matches to fill
    if (out.length < limit) {
      for (final w in keys) {
        if (w.startsWith(t) && !out.contains(w)) {
          out.add(w);
          if (out.length >= limit) break;
        }
      }
    }

    out.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }
}
