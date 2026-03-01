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

  /// Stronger offline suggestions:
  /// Score words by:
  /// 1) prefix match
  /// 2) contains match
  /// 3) simple edit-distance-like score (very lightweight)
  List<String> suggestSmart(String typed, {int limit = 30}) {
    final t = typed.trim().toUpperCase();
    if (t.isEmpty) return const [];

    final candidates = _byWord.keys.toList();
    final scored = <_ScoredWord>[];

    for (final w in candidates) {
      final score = _scoreWord(t, w);
      if (score > 0) {
        scored.add(_ScoredWord(w, score));
      }
    }

    scored.sort((a, b) {
      final s = b.score.compareTo(a.score);
      if (s != 0) return s;
      return a.word.toLowerCase().compareTo(b.word.toLowerCase());
    });

    final out = <String>[];
    for (final s in scored) {
      out.add(s.word);
      if (out.length >= limit) break;
    }
    return out;
  }

  int _scoreWord(String typed, String w) {
    // Hard cap for performance: skip huge mismatches
    if (typed.length > 0 && (w[0] == typed[0])) {
      // keep
    }

    int score = 0;

    // Prefix match gets big boost
    if (w.startsWith(typed)) score += 100;

    // Contains match medium boost
    if (w.contains(typed)) score += 60;

    // Similar-length bonus
    final lenDiff = (w.length - typed.length).abs();
    score += (20 - lenDiff).clamp(0, 20);

    // Character overlap bonus (very lightweight)
    score += _charOverlapScore(typed, w);

    return score;
  }

  int _charOverlapScore(String a, String b) {
    // Count shared characters, but avoid heavy computation
    final setA = a.split('').toSet();
    final setB = b.split('').toSet();
    final shared = setA.intersection(setB).length;
    return (shared * 4).clamp(0, 40);
  }
}

class _ScoredWord {
  final String word;
  final int score;
  const _ScoredWord(this.word, this.score);
}
