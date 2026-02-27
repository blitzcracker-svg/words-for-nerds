import 'dart:io';

/// Offline-first enforcement:
/// - Only Update Word Library is allowed to use network.
/// - Everything else should never create network clients.
class NetworkGate {
  static bool _allowNetworkForUpdate = false;

  static void allowUpdateNetwork(bool allow) {
    _allowNetworkForUpdate = allow;
  }

  static void requireUpdateNetworkAllowed() {
    if (!_allowNetworkForUpdate) {
      throw StateError(
        'Network blocked: only Update Word Library may use the internet.',
      );
    }
  }

  /// If/when we do real network update later, it must use THIS client.
  /// Always close it after update.
  static HttpClient createUpdateHttpClient() {
    requireUpdateNetworkAllowed();
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);
    client.idleTimeout = const Duration(seconds: 5);
    client.autoUncompress = true;
    return client;
  }
}
