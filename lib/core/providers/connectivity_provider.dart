import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a real-time stream of the device's connectivity status.
/// Returns `true` when online, `false` when offline.
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();

  // Create a stream controller that combines initial check + ongoing changes
  final controller = StreamController<bool>();

  // Check initial status
  connectivity.checkConnectivity().then((results) {
    controller.add(_isConnected(results));
  });

  // Listen for changes
  final subscription = connectivity.onConnectivityChanged.listen((results) {
    controller.add(_isConnected(results));
  });

  // Clean up when provider is disposed
  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Helper to check if any of the connectivity results indicate a connection.
bool _isConnected(List<ConnectivityResult> results) {
  return results.any((r) =>
      r == ConnectivityResult.wifi ||
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.ethernet);
}
