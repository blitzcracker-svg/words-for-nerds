import 'dart:io';
import 'network_gate.dart';

class UpdateResult {
  final bool success;
  final String message;
  const UpdateResult(this.success, this.message);
}

class UpdateService {
  /// Placeholder update:
  /// - If device appears OFFLINE → return failure (so UpdateFailedScreen shows)
  /// - If device appears ONLINE → return success (so UpdateCompleteScreen shows)
  ///
  /// No real dictionary downloading yet.
  Future<UpdateResult> runUpdatePlaceholder() async {
    NetworkGate.allowUpdateNetwork(true);

    HttpClient? client;
    try {
      // Create the only allowed network client (gated)
      client = NetworkGate.createUpdateHttpClient();

      // Minimal "are we online?" check.
      // In airplane mode / no internet, this will typically throw or timeout.
      await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 4));

      // Online → simulate success
      return const UpdateResult(true, 'Online (placeholder update succeeded).');
    } catch (_) {
      // Offline/timeout/DNS failure → simulate failure
      return const UpdateResult(false, 'Offline (placeholder update failed).');
    } finally {
      // Force-close any sockets and lock networking back down
      try {
        client?.close(force: true);
      } catch (_) {}
      NetworkGate.allowUpdateNetwork(false);
    }
  }
}
