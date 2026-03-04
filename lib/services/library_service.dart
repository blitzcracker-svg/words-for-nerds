import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../models/word_entry.dart';

class LibraryService {
  LibraryService._();
  static final LibraryService instance = LibraryService._();

  static const String _assetPath = 'assets/library.json';

  final Map<String, WordEntry> _byWord = <String, WordEntry>{};
  List<String> _allWords = const <String>[];

  String _lastUpdated = 'Bundled';

  String? _localLibraryPath;
  String? _localMetaPath;

  // --- Public API ---

  /// Call once at startup.
  Future<void> initFromAsset() async {
    await _ensureLocalPaths();

    // Prefer saved updated library if it exists.
    final localFile = File(_localLibraryPath!);
    if (await localFile.exists()) {
      final raw = await localFile.readAsString();
      _loadFromString(raw);

      final meta = await _readMetaDate();
      _lastUpdated = meta ?? 'Updated';
      return;
    }

    // Otherwise use bundled asset.
    final raw = await rootBundle.loadString(_assetPath);
    _loadFromString(raw);
    _lastUpdated = 'Bundled';
  }

  /// Used by UpdateService after downloading a new library.
  Future<void> applyUpdatedLibrary(String raw) async {
    await _ensureLocalPaths();

    // Parse first (validation) before writing anything.
    _loadFromString(raw);

    // Atomic write: write temp then rename.
    final tmpPath = '${_localLibraryPath!}.tmp';
    final tmpFile = File(tmpPath);
    await tmpFile.writeAsString(raw, flush: true);

    final targetFile = File(_localLibraryPath!);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await tmpFile.rename(_localLibraryPath!);

    // Save metadata
    _lastUpdated = _todayIso();
    await File(_localMetaPath!).writeAsString(jsonEncode({'lastUpdated': _lastUpdated}), flush: true);
  }

  WordEntry? lookup(String word) {
    final key = word.trim().toUpperCase();
    return _byWord[key];
  }

  List<String> get allWords => _allWords;

  Future<String> lastUpdatedLabel() async {
    // In-memory is enough most of the time, but meta keeps it across restarts.
    if (_lastUpdated.isNotEmpty) return _lastUpdated;
    await _ensureLocalPaths();
    return (await _readMetaDate()) ?? 'Bundled';
  }

  /// Suggestions for "WORD NOT FOUND" screen.
  List<String> suggest(String typed, {int limit = 25}) {
    final t = typed.trim().toUpperCase();
    if (t.isEmpty) return const <String>[];

    final first = t[0];
    final List<String> hits = <String>[];

    for (final w in _allWords) {
      if (w.isEmpty) continue;
      if (w[0] != first) continue;

      if (w.contains(t) ||
          w.startsWith(t) ||
          _commonPrefixLen(w, t) >= min(3, t.length)) {
        hits.add(w);
      }

      if (hits.length >= limit) break;
    }

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

  // --- Internals ---

  Future<void> _ensureLocalPaths() async {
    if (_localLibraryPath != null && _localMetaPath != null) return;

    final dir = await getApplicationDocumentsDirectory();
    _localLibraryPath = '${dir.path}/library.json';
    _localMetaPath = '${dir.path}/library_meta.json';
  }

  Future<String?> _readMetaDate() async {
    try {
      final f = File(_localMetaPath!);
      if (!await f.exists()) return null;
      final raw = await f.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['lastUpdated'] is String) {
        return decoded['lastUpdated'] as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _loadFromString(String raw) {
    final trimmed = raw.trimLeft();

    final Map<String, WordEntry> map = <String, WordEntry>{};

    if (trimmed.startsWith('[')) {
      // JSON array
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            final entry = WordEntry.fromJson(item.cast<String, dynamic>());
            final key = entry.word.toUpperCase();
            if (key.isEmpty) continue;
            map[key] = entry;
          }
        }
      }
    } else {
      // JSONL (one JSON per line) – supported if you ever switch later
      final lines = raw.split('\n');
      for (final line in lines) {
        final l = line.trim();
        if (l.isEmpty) continue;
        final decoded = jsonDecode(l);
        if (decoded is Map) {
          final entry = WordEntry.fromJson(decoded.cast<String, dynamic>());
          final key = entry.word.toUpperCase();
          if (key.isEmpty) continue;
          map[key] = entry;
        }
      }
    }

    final words = map.keys.toList()..sort();

    _byWord
      ..clear()
      ..addAll(map);

    _allWords = List<String>.unmodifiable(words);
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
