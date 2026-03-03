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

  /// Keeping the method name so main.dart doesn't need changing.
  Future<UpdateResult> runUpdatePlaceholder() async {
    try {
      final ok = await _downloadValidateInstall();
      if (ok) {
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

  bool _isHostAllowed(String host) {
    final h = host.toLowerCase().trim();

    // Direct GitHub hosts we expect.
    const exact = <String>{
      'github.com',
      'objects.githubusercontent.com',
      'release-assets.githubusercontent.com',
      'github-releases.githubusercontent.com',
    };
    if (exact.contains(h)) return true;

    // Some redirects use subdomains of githubusercontent.com
    if (h.endsWith('githubusercontent.com')) return true;

    // GitHub Release assets frequently redirect to AWS S3.
    // Examples:
    // - github-production-release-asset-2e65be.s3.amazonaws.com
    // - github-production-release-asset-*.s3.us-east-1.amazonaws.com
    if (h.contains('github-production-release-asset') && h.endsWith('amazonaws.com')) {
      return true;
    }

    return false;
  }

  Future<bool> _downloadValidateInstall() async {
    final dir = await _getFilesDir();

    final target = File('$dir/library.json');
    final backup = File('$dir/library_backup.json');
    final tmp = File('$dir/library_download.tmp');
    final meta = File('$dir/library_meta.json');

    final url = Uri.parse(
      'https://github.com/$owner/$repo/releases/latest/download/$assetName',
    );

    final client = HttpClient();
    client.userAgent = 'WordsForNerds/1.0';

    try {
      final req = await client.getUrl(url);
      req.followRedirects = true;
      req.maxRedirects = 10;
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final res = await req.close();

      // Check every redirect destination host
      for (final r in res.redirects) {
        final host = r.location.host;
        if (!_isHostAllowed(host)) {
          throw StateError('Redirected to untrusted host: $host');
        }
      }

      // Also check the final response host
      final finalHost = res.redirects.isNotEmpty
          ? res.redirects.last.location.host
          : url.host;
      if (!_isHostAllowed(finalHost)) {
        throw StateError('Final host untrusted: $finalHost');
      }

      if (res.statusCode != 200) {
        throw StateError('HTTP ${res.statusCode}');
      }

      // Size guard (increase later when your library grows)
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

      // Validate JSON format
      final raw = await tmp.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw StateError('Library must be JSON array.');
      if (decoded.isEmpty) throw StateError('Library empty.');

      int validCount = 0;
      for (final item in decoded) {
        if (item is Map && (item['word']?.toString().trim().isNotEmpty ?? false)) {
          validCount++;
        }
      }
      if (validCount == 0) throw StateError('No valid entries.');

      // Backup current library
      if (await target.exists()) {
        await target.copy(backup.path);
      }

      // Replace
      await tmp.copy(target.path);
      await tmp.delete().catchError((_) {});

      // Persist last updated timestamp
      final nowIso = DateTime.now().toIso8601String();
      await meta.writeAsString(jsonEncode({
        'lastUpdatedIso': nowIso,
        'source': url.toString(),
      }));

      return true;
    } catch (_) {
      // Revert if backup exists
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
