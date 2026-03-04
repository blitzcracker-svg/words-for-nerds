import 'dart:convert';
import 'dart:io';

import 'library_service.dart';

class UpdateResult {
  final bool success;
  final String message;
  const UpdateResult(this.success, this.message);
}

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  // ✅ Pulls the latest library directly from your repo.
  // If you update assets/library.json in GitHub, this fetches it.
  static const String libraryUrl =
      'https://raw.githubusercontent.com/blitzcracker-svg/words-for-nerds/main/assets/library.json';

  // Hard safety cap so updates can't balloon unexpectedly.
  static const int _maxBytes = 10 * 1024 * 1024; // 10 MB

  Future<UpdateResult> runUpdate() async {
    try {
      final uri = Uri.parse(libraryUrl);

      // Basic network safety checks
      if (uri.scheme != 'https') {
        return const UpdateResult(false, 'Update blocked: unsafe URL.');
      }
      if (uri.host != 'raw.githubusercontent.com') {
        return const UpdateResult(false, 'Update blocked: untrusted host.');
      }

      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);

      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set(HttpHeaders.userAgentHeader, 'words-for-nerds');

      final resp = await req.close();

      if (resp.statusCode != 200) {
        return UpdateResult(false, 'Update failed: HTTP ${resp.statusCode}.');
      }

      // Read response with a size limit
      final chunks = <int>[];
      await for (final chunk in resp) {
        chunks.addAll(chunk);
        if (chunks.length > _maxBytes) {
          return const UpdateResult(false, 'Update blocked: file too large.');
        }
      }

      final raw = utf8.decode(chunks);

      // Validate it's a JSON array and non-empty
      final trimmed = raw.trimLeft();
      if (!trimmed.startsWith('[')) {
        return const UpdateResult(false, 'Update failed: invalid format.');
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.isEmpty) {
        return const UpdateResult(false, 'Update failed: empty library.');
      }

      // Apply + persist (offline after this)
      await LibraryService.instance.applyUpdatedLibrary(raw);

      client.close(force: true);
      return const UpdateResult(true, 'Update successful.');
    } catch (_) {
      return const UpdateResult(false, 'Update failed.');
    }
  }
}
