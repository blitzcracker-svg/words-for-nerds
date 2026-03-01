import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/word_entry.dart';

class LibraryService {
  LibraryService._();
  static final LibraryService instance = LibraryService._();

  bool _ready = false;
  bool get ready => _ready;

  late final List<WordEntry> _entries;
  late final Map<String, WordEntry> _byWord;

  List<String> get allWords => _byWord.keys.toList()..sort();

  Future<void> initFromAsset() async {
    if (_ready) return;

    final raw = await rootBundle.loadString('assets/library.json');
    final data = jsonDecode(raw);

    if (data is! List) {
      throw StateError('library.json must be a JSON array.');
    }

    final entries = <WordEntry>[];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        final e = WordEntry.fromJson(item);
        if (e.word.isNotEmpty) entries.add(e);
      } else if (item is Map) {
        final e = WordEntry.fromJson(item.cast<String, dynamic>());
        if (e.word.isNotEmpty) entries.add(e);
      }
    }

    final by = <String, WordEntry>{};
    for (final e in entries) {
      by[e.word] = e; // last wins if duplicates
    }

    _entries = by.values.toList();
    _byWord = by;
    _ready = true;
  }

  WordEntry? lookup(String word) {
    return _byWord[word.trim().toUpperCase()];
  }

  /// Lightweight suggestion: first-letter + contains filter.
  List<String> suggest(String typed, {int limit = 10}) {
    final t = typed.trim().toUpperCase();
    if (t.isEmpty) return const [];

    final first = t[0];
    final hits = <String>[];

    for (final w in _byWord.keys) {
      if (w.isEmpty) continue;
      if (w[0] == first && (w.contains(t) || t.contains(w.substring(0, min(3, w.length))))) {
        hits.add(w);
        if (hits.length >= limit) break;
      }
    }

    // If not enough, fill with same-first-letter words.
    if (hits.length < limit) {
      for (final w in _byWord.keys) {
        if (w.isEmpty) continue;
        if (w[0] == first && !hits.contains(w)) {
          hits.add(w);
          if (hits.length >= limit) break;
        }
      }
    }

    return hits;
  }
}
