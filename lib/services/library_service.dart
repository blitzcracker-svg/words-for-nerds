import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../models/word_entry.dart';

class LibraryService {
  LibraryService._();
  static final LibraryService instance = LibraryService._();

  static const String _assetPath = 'assets/library.jsonl';

  final Map<String, WordEntry> _byWord = {};
  List<String> _allWords = const [];

  String _lastUpdated = 'Bundled';

  /// Call once at startup.
  Future<void> initFromAsset() async {
    final raw = await rootBundle.loadString(_assetPath);
    _loadFromString(raw);
    _lastUpdated = 'Bundled';
  }

  /// Used by UpdateService after downloading a new library.
  void loadFromRemoteString(String raw) {
    _loadFromString(raw);
    _lastUpdated = _todayIso();
  }

  WordEntry? lookup(String word) {
    final key = word.trim().toUpperCase();
    return _byWord[key];
  }

  List<String> get allWords => _allWords;

  Future<String> lastUpdatedLabel() async {
    // (lightweight: in-memory label; no extra deps)
    return _lastUpdated;
  }

  /// Suggestions for "WORD NOT FOUND" screen.
  /// Simple + fast heuristic (no heavy algorithms).
  List<String> suggest(String typed, {int limit = 25}) {
    final t = typed.trim().toUpperCase();
    if (t.isEmpty) return const [];
    final first = t[0];

    final List<String> hits = [];

    // Prefer: same first letter + contains typed substring (or prefix)
    for (final w in _allWords) {
      if (w.isEmpty) continue;
      if (w[0] != first) continue;

      if (w.contains(t) ||
          t.contains(w) ||
          w.startsWith(t) ||
          _commonPrefixLen(w, t) >= min(3, t.length)) {
        hits.add(w);
      }
      if (hits.length >= limit) break;
    }

    // If still short, broaden: contains substring anywhere
    if (hits.length < limit) {
      for (final w in _allWords) {
        if (hits.contains(w)) continue;
        if (w.contains(t) || w.startsWith(t) || _commonPrefixLen(w, t) >= 2) {
          hits.add(w);
        }
        if (hits.length >= limit) break;
      }
    }

    return hits;
  }

  /* ------------------------------ Internal ------------------------------ */

  void _loadFromString(String raw) {
    final trimmed = raw.trimLeft();

    final Map<String, WordEntry> map = {};
    final List<String> words = [];

    if (trimmed.startsWith('[')) {
      // JSON array
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final entry = WordEntry.fromJson(item);
            final key = entry.word.toUpperCase();
            if (key.isEmpty) continue;
            map[key] = entry;
          } else if (item is Map) {
            final entry = WordEntry.fromJson(item.cast<String, dynamic>());
            final key = entry.word.toUpperCase();
            if (key.isEmpty) continue;
            map[key] = entry;
          }
        }
      }
    } else {
      // JSONL (one JSON object per line)
      final lines = raw.split('\n');
      for (final line in lines) {
        final l = line.trim();
        if (l.isEmpty) continue;
        final decoded = jsonDecode(l);
        if (decoded is Map<String, dynamic>) {
          final entry = WordEntry.fromJson(decoded);
          final key = entry.word.toUpperCase();
          if (key.isEmpty) continue;
          map[key] = entry;
        } else if (decoded is Map) {
          final entry = WordEntry.fromJson(decoded.cast<String, dynamic>());
          final key = entry.word.toUpperCase();
          if (key.isEmpty) continue;
          map[key] = entry;
        }
      }
    }

    words.addAll(map.keys);
    words.sort(); // stable alphabetical list

    _byWord
      ..clear()
      ..addAll(map);
    _allWords = words;
  }

  int _commonPrefixLen(String a, String b) {
    final n = min(a.length, b.length);
    var i = 0;
    while (i < n && a.codeUnitAt(i) == b.codeUnitAt(i)) {
      i++;
    }
    return i;
  }

  String _todayIso() {
    final now = DateTime.now().toUtc();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
