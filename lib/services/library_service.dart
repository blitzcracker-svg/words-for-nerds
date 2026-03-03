import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/word_entry.dart';

class LibraryService {
  LibraryService._();
  static final LibraryService instance = LibraryService._();

  static const MethodChannel _filesCh = MethodChannel('words_for_nerds/files');

  bool _ready = false;
  bool get ready => _ready;

  Map<String, WordEntry> _byWord = {};

  Future<String> _getFilesDir() async {
    final path = await _filesCh.invokeMethod<String>('getFilesDir');
    if (path == null || path.trim().isEmpty) {
      throw StateError('Could not resolve app files directory.');
    }
    return path;
  }

  Future<File> _savedLibraryFile() async {
    final dir = await _getFilesDir();
    return File('$dir/library.json');
  }

  Future<File> _metaFile() async {
    final dir = await _getFilesDir();
    return File('$dir/library_meta.json');
  }

  Future<void> initFromAsset() async {
    if (_ready) return;
    await _loadBestAvailable();
    _ready = true;
  }

  Future<void> reloadFromDisk() async {
    _ready = false;
    await _loadBestAvailable();
    _ready = true;
  }

  Future<void> _loadBestAvailable() async {
    // Try saved library first
    String? raw;
    try {
      final f = await _savedLibraryFile();
      if (await f.exists()) {
        raw = await f.readAsString();
      }
    } catch (_) {}

    // Fallback to bundled asset
    raw ??= await rootBundle.loadString('assets/library.json');

    final data = jsonDecode(raw);
    if (data is! List) {
      throw StateError('Library must be a JSON array.');
    }

    final by = <String, WordEntry>{};
    for (final item in data) {
      if (item is Map) {
        final e = WordEntry.fromJson(item.cast<String, dynamic>());
        if (e.word.isNotEmpty) by[e.word] = e;
      }
    }

    _byWord = by;
  }

  List<String> allWordsSorted() {
    final words = _byWord.keys.toList();
    words.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return words;
  }

  WordEntry? lookup(String word) => _byWord[word.trim().toUpperCase()];

  List<String> suggestSmart(String typed, {int limit = 30}) {
    final t = typed.trim().toUpperCase();
    if (t.isEmpty) return const [];

    final scored = <_ScoredWord>[];
    for (final w in _byWord.keys) {
      final score = _scoreWord(t, w);
      if (score > 0) scored.add(_ScoredWord(w, score));
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
    int score = 0;
    if (w.startsWith(typed)) score += 100;
    if (w.contains(typed)) score += 60;

    final lenDiff = (w.length - typed.length).abs();
    score += (20 - lenDiff).clamp(0, 20);

    final setA = typed.split('').toSet();
    final setB = w.split('').toSet();
    final shared = setA.intersection(setB).length;
    score += (shared * 4).clamp(0, 40);

    return score;
  }

  // ---- last-updated helpers ----
  Future<String> lastUpdatedLabel() async {
    try {
      final mf = await _metaFile();
      if (!await mf.exists()) return 'Bundled';
      final j = jsonDecode(await mf.readAsString());
      if (j is Map && j['lastUpdatedIso'] is String) {
        return (j['lastUpdatedIso'] as String);
      }
    } catch (_) {}
    return 'Bundled';
  }
}

class _ScoredWord {
  final String word;
  final int score;
  const _ScoredWord(this.word, this.score);
}
