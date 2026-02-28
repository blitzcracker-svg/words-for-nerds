import 'dart:io';
import 'network_gate.dart';

class UpdateResult {
  final bool success;
  final String message;
  const UpdateResult(this.success, this.message);
}

class UpdateService {
  Future<UpdateResult> runUpdatePlaceholder() async {
    NetworkGate.allowUpdateNetwork(true);

    HttpClient? client;
    try {
      client = NetworkGate.createUpdateHttpClient();
      return const UpdateResult(true, 'Update finished (offline placeholder).');
    } catch (e) {
      return UpdateResult(false, 'Update failed: $e');
    } finally {
      try {
        client?.close(force: true);
      } catch (_) {}
      NetworkGate.allowUpdateNetwork(false);
    }
  }
}
