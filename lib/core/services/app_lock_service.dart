import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Manages the biometric app-lock state.
///
/// A single source of truth:
/// - `enabled` : user preference (persisted)
/// - `locked`  : runtime state (in-memory). Starts `true` if enabled,
///              flips to `false` after successful authentication,
///              set back to `true` when the app goes to background.
class AppLockService {
  final SharedPreferences _prefs;
  final LocalAuthentication _auth = LocalAuthentication();

  final ValueNotifier<bool> _locked = ValueNotifier<bool>(false);
  ValueListenable<bool> get locked => _locked;

  AppLockService(this._prefs) {
    _locked.value = isEnabled;
  }

  bool get isEnabled =>
      _prefs.getBool(AppConstants.keyBiometricLock) ?? false;

  Future<bool> isDeviceSupported() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      return canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool value) async {
    await _prefs.setBool(AppConstants.keyBiometricLock, value);
    _locked.value = value;
  }

  /// Call when the app comes back to foreground.
  void lockIfEnabled() {
    if (isEnabled) _locked.value = true;
  }

  Future<bool> authenticate() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Hustle',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (ok) _locked.value = false;
      return ok;
    } catch (_) {
      return false;
    }
  }
}
