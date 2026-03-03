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

  // Pull from your repo's latest release asset (JSONL).
  // Make sure the release asset is named exactly: library.jsonl
  static const String _url =
      'https://github.com/blitzcracker-svg/words-for-nerds/releases/latest/download/library.jsonl';

  Future<UpdateResult> runUpdate() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);

    try {
      final uri = Uri.parse(_url);

      final req = await client.getUrl(uri).timeout(const Duration(seconds: 15));
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.headers.set(HttpHeaders.userAgentHeader, 'words-for-nerds');

      final resp = await req.close().timeout(const Duration(seconds: 30));

      if (resp.statusCode != 200) {
        return UpdateResult(false, 'Update failed (HTTP ${resp.statusCode}).');
      }

      final bytes = await resp.fold<List<int>>(<int>[], (a, b) => a..addAll(b));
      final body = utf8.decode(bytes);

      // If the download was empty / nonsense, treat as failure.
      if (body.trim().isEmpty) {
        return const UpdateResult(false, 'Update failed (empty download).');
      }

      // Load into the in-memory offline library (app stays offline otherwise).
      LibraryService.instance.loadFromRemoteString(body);

      return const UpdateResult(true, 'Update successful.');
    } on SocketException {
      return const UpdateResult(false, 'Update failed (no network).');
    } on TimeoutException {
      return const UpdateResult(false, 'Update failed (timeout).');
    } catch (_) {
      return const UpdateResult(false, 'Update failed.');
    } finally {
      client.close(force: true);
    }
  }
}

class TimeoutException implements Exception {}
