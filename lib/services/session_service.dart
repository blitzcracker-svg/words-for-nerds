// lib/services/session_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const String _fileName = 'session_state.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<Map<String, dynamic>?> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Map<String, dynamic> data) async {
    final f = await _file();
    final tmp = File('${f.path}.tmp');

    final raw = jsonEncode(data);
    await tmp.writeAsString(raw, flush: true);

    if (await f.exists()) {
      try {
        await f.delete();
      } catch (_) {}
    }
    await tmp.rename(f.path);
  }

  Future<void> clear() async {
    try {
      final f = await _file();
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
