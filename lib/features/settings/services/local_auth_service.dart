import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
final localAuthServiceProvider = Provider<LocalAuthService>((ref) {
  return LocalAuthService();
});

class LocalAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometrics or authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();

      return canCheckBiometrics || isDeviceSupported;
    } on PlatformException catch (e) {
      debugPrint('Biometric check error: ${e.message}');
      return false;
    }
  }

  /// Get available biometric types (Fingerprint, Face ID, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Error fetching biometrics: ${e.message}');
      return [];
    }
  }

  /// Authenticate user
  Future<bool> authenticate() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to unlock the app',
        options: const AuthenticationOptions(
          biometricOnly: false, // allow PIN/pattern fallback
          stickyAuth: true,     // keeps auth active across app lifecycle
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Auth error: ${e.message}');
      return false;
    }
  }

  /// Cancel ongoing authentication (useful when navigating away)
  Future<void> cancelAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (e) {
      debugPrint('Cancel auth error: $e');
    }
  }
}