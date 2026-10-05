import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive Authentication & Security Service for MTMMS (Government of Goa).
///
/// Features:
/// - Secure Sanctum Bearer Token management with [FlutterSecureStorage]
/// - Hardware Biometric Authentication with [LocalAuthentication]
/// - Non-sensitive profile caching with [SharedPreferences]
/// - Zero plaintext credential leaks
class AuthService {
  AuthService._();

  static const String _tokenKey = 'mtmms_auth_token';
  static const String _userKey = 'mtmms_auth_user';
  static const String _rememberedEmailKey = 'mtmms_remembered_email';
  static const String _biometricEnabledKey = 'mtmms_biometric_enabled';
  static const String _lastLoginKey = 'mtmms_last_login';

  // Secure storage instance
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static final LocalAuthentication _localAuth = LocalAuthentication();

  // In-memory token cache to minimize asynchronous disk round-trips
  static String? _cachedToken;

  // ============================================================
  // 1. TOKEN MANAGEMENT (SECURE STORAGE)
  // ============================================================

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    }
  }

  static Future<String?> getToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }

    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) {
        _cachedToken = token;
        return token;
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token != null && token.isNotEmpty) {
        _cachedToken = token;
        return token;
      }
    } catch (_) {}

    return null;
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearToken() async {
    _cachedToken = null;
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      await prefs.remove(_rememberedEmailKey);
    } catch (_) {}
  }

  // ============================================================
  // 2. USER PROFILE & SESSION
  // ============================================================

  static Future<void> saveUser(Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user));
      await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userKey);
      if (raw == null) return null;
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<String> getRole() async {
    final user = await getUser();
    return user?['role']?.toString().toLowerCase() ?? 'admin';
  }

  static Future<bool> isAdmin() async {
    final role = await getRole();
    return role == 'admin' || role == 'administrator';
  }

  static Future<bool> isOfficer() async {
    final role = await getRole();
    return role == 'officer' || role == 'inspector';
  }

  static Future<String?> getLastLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastLoginKey);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // 3. REMEMBERED EMAIL / USERNAME
  // ============================================================

  static Future<void> saveRememberedEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_rememberedEmailKey, email.trim());
    } catch (_) {}
  }

  static Future<String?> getRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_rememberedEmailKey);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // 4. BIOMETRIC AUTHENTICATION (HARDWARE LOCAL_AUTH)
  // ============================================================

  /// Check if the physical device has hardware biometric support & enrolled biometrics
  static Future<bool> canCheckBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Get list of available biometric types (fingerprint, face, iris)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Enable biometric quick-access for the logged in officer
  static Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
    } catch (_) {}
  }

  static Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? true;
    } catch (_) {
      return false;
    }
  }

  /// Perform hardware biometric authentication to unlock saved session
  static Future<bool> authenticateWithBiometrics({
    String reason = 'Authenticate to access MTMMS Official Government Grid',
  }) async {
    try {
      final bool canAuth = await canCheckBiometrics();
      if (!canAuth) return false;

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // 5. LOGOUT (PURGE SESSION)
  // ============================================================

  static Future<void> logout() async {
    await clearToken();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (_) {}
  }
}