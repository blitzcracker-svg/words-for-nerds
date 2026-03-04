import 'dart:async';
import 'dart:io';

import 'library_service.dart';

class UpdateResult {
  final bool success;
  final String message;
  const UpdateResult._(this.success, this.message);

  factory UpdateResult.ok([String message = 'Update complete.']) =>
      UpdateResult._(true, message);

  factory UpdateResult.fail([String message = 'Update failed.']) =>
      UpdateResult._(false, message);
}

class UpdateService {
  static final UpdateService instance = UpdateService._();
  UpdateService._();

  // Primary: GitHub Release asset (latest)
  static const String _releaseLatestUrl =
      'https://github.com/blitzcracker-svg/words-for-nerds/releases/latest/download/library.json';

  // Fallback (still works if you choose to keep the repo asset updated too)
  static const String _fallbackRawUrl =
      'https://raw.githubusercontent.com/blitzcracker-svg/words-for-nerds/main/assets/library.json';

  // Safety limit so a bad download can’t explode memory/storage.
  static const int _maxBytes = 50 * 1024 * 1024; // 50 MB

  Future<UpdateResult> runUpdate() async {
    try {
      final raw = await _downloadText(_releaseLatestUrl).catchError((_) async {
        // If the Release asset is missing, fall back to the raw file.
        return await _downloadText(_fallbackRawUrl);
      });

      // Very light validation before we write anything.
      final t = raw.trimLeft();
      if (t.isEmpty) {
        return UpdateResult.fail('Downloaded file was empty.');
      }
      if (!(t.startsWith('[') || t.startsWith('{'))) {
        return UpdateResult.fail('Downloaded file did not look like JSON.');
      }

      await LibraryService.instance.applyUpdatedLibrary(raw);
      return UpdateResult.ok('Update successful.');
    } catch (_) {
      return UpdateResult.fail('Update failed (offline or unreachable).');
    }
  }

  Future<String> _downloadText(String url) async {
    final uri = Uri.parse(url);

    // Only allow https.
    if (uri.scheme != 'https') {
      throw StateError('Refusing non-https URL');
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    try {
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'words-for-nerds');

      final res = await req.close().timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode}');
      }

      final bytes = <int>[];
      await for (final chunk in res) {
        bytes.addAll(chunk);
        if (bytes.length > _maxBytes) {
          throw StateError('Download too large');
        }
      }

      return utf8.decode(bytes, allowMalformed: false);
    } finally {
      client.close(force: true);
    }
  }
}
