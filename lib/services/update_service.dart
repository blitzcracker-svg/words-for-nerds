import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'library_service.dart';

class UpdateResult {
  final bool success;
  final String message;
  const UpdateResult({required this.success, required this.message});
}

class UpdateService {
  // Edit these if your repo changes:
  static const String owner = 'blitzcracker-svg';
  static const String repo = 'words-for-nerds';
  static const String assetName = 'library.json';

  static const MethodChannel _filesCh = MethodChannel('words_for_nerds/files');

  Future<String> _getFilesDir() async {
    final path = await _filesCh.invokeMethod<String>('getFilesDir');
    if (path == null || path.trim().isEmpty) {
      throw StateError('Could not resolve app files directory.');
    }
    return path;
  }

  /// Keeps main.dart unchanged by preserving the old method name.
  Future<UpdateResult> runUpdatePlaceholder() async {
    try {
      final ok = await _downloadValidateInstall();
      if (ok) {
        // Reload library immediately so new words are usable without restart.
        await LibraryService.instance.reloadFromDisk();
        return const UpdateResult(success: true, message: 'Updated.');
      }
      return const UpdateResult(success: false, message: 'Update failed.');
    } on SocketException {
      return const UpdateResult(success: false, message: 'Offline.');
    } catch (_) {
      return const UpdateResult(success: false, message: 'Update failed.');
    }
  }

  Future<bool> _downloadValidateInstall() async {
    final dir = await _getFilesDir();

    final target = File('$dir/library.json');
    final backup = File('$dir/library_backup.json');
    final tmp = File('$dir/library_download.tmp');
    final meta = File('$dir/library_meta.json');

    // GitHub releases latest download URL
    final url = Uri.parse(
      'https://github.com/$owner/$repo/releases/latest/download/$assetName',
    );

    // Safety: allowlist hosts (github + its release storage redirect)
    const allowedHosts = <String>{
      'github.com',
      'objects.githubusercontent.com',
      'github-releases.githubusercontent.com',
    };

    final client = HttpClient();
    client.userAgent = 'WordsForNerds/1.0';

    try {
      final req = await client.getUrl(url);
      req.followRedirects = true;
      req.maxRedirects = 5;

      final res = await req.close();

      // Validate redirects are still within GitHub infrastructure
      for (final r in res.redirects) {
        final h = r.location.host.toLowerCase();
        if (!allowedHosts.contains(h)) {
          throw StateError('Redirected to untrusted host: $h');
        }
      }

      if (res.statusCode != 200) {
        throw StateError('HTTP ${res.statusCode}');
      }

      // Size guard (adjust later if you grow the library a lot)
      const maxBytes = 10 * 1024 * 1024; // 10MB
      int received = 0;

      final sink = tmp.openWrite();
      await for (final chunk in res) {
        received += chunk.length;
        if (received > maxBytes) {
          await sink.close();
          throw StateError('Download too large.');
        }
        sink.add(chunk);
      }
      await sink.close();

      // Validate JSON
      final raw = await tmp.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw StateError('Library must be JSON array.');
      if (decoded.isEmpty) throw StateError('Library empty.');

      // Minimal schema validation
      int validCount = 0;
      for (final item in decoded) {
        if (item is Map && (item['word']?.toString().trim().isNotEmpty ?? false)) {
          validCount++;
        }
      }
      if (validCount == 0) throw StateError('No valid entries.');

      // Backup current library (if present)
      if (await target.exists()) {
        await target.copy(backup.path);
      }

      // Atomic-ish replace
      await tmp.copy(target.path);
      await tmp.delete().catchError((_) {});

      // Write meta
      final nowIso = DateTime.now().toIso8601String();
      await meta.writeAsString(jsonEncode({
        'lastUpdatedIso': nowIso,
        'source': url.toString(),
      }));

      return true;
    } catch (_) {
      // Revert if we have a backup and target got messed up
      try {
        if (await backup.exists()) {
          await backup.copy(target.path);
        }
      } catch (_) {}
      return false;
    } finally {
      try {
        await tmp.delete();
      } catch (_) {}
      client.close(force: true);
    }
  }
}
