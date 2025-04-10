import 'package:local_auth/local_auth.dart';

class AuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Checks if device supports biometrics or passcode.
  static Future<bool> isDeviceSupported() async {
    return await _auth.isDeviceSupported();
  }

  /// Checks if any biometrics (Face ID, Fingerprint) are enrolled.
  static Future<bool> hasBiometrics() async {
    return await _auth.canCheckBiometrics;
  }

  /// Authenticates the user using biometrics or device passcode.
static Future<bool> authenticateUser({String reason = "Authenticate to view balance"}) async {
    try {
      final isAvailable = await isDeviceSupported();
      if (!isAvailable) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // fallback to device pin/password if needed
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      print("Authentication error: $e");
      return false;
    }
  }
}
